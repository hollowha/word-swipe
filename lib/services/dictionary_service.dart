import 'package:dio/dio.dart';

class WordDefinition {
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String example;
  final String lookedUpAs; // which form actually returned a result

  const WordDefinition({
    this.phonetic = '',
    this.partOfSpeech = '',
    this.definition = '',
    this.example = '',
    this.lookedUpAs = '',
  });
}

class DictionaryService {
  final Dio _dio;

  DictionaryService()
      : _dio = Dio(
          BaseOptions(receiveTimeout: const Duration(seconds: 8)),
        );

  // Try the word itself, then progressively simpler lemma forms.
  Future<WordDefinition?> fetchDefinition(String word) async {
    for (final candidate in _candidates(word)) {
      final result = await _fetch(candidate);
      if (result != null) {
        return WordDefinition(
          phonetic: result.phonetic,
          partOfSpeech: result.partOfSpeech,
          definition: result.definition,
          example: result.example,
          lookedUpAs: candidate == word ? '' : candidate,
        );
      }
    }
    return null;
  }

  Future<WordDefinition?> _fetch(String word) async {
    try {
      final resp = await _dio.get(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
      );
      if (resp.statusCode == 200) return _parse(resp.data as List<dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      // network/timeout — give up for this candidate
    } catch (_) {
      return null;
    }
    return null;
  }

  // Returns the original word plus up to 4 lemma fallback candidates.
  // Ordered from most-specific to most-generic.
  List<String> _candidates(String raw) {
    final w = raw.toLowerCase().trim();
    final seen = <String>{w};
    final out = <String>[w];

    void add(String s) {
      if (s.length >= 2 && !seen.contains(s)) {
        seen.add(s);
        out.add(s);
      }
    }

    // ── -ing  (running→run, dancing→dance, smiling→smile) ─────────────────
    if (w.endsWith('ing') && w.length > 5) {
      final stem = w.substring(0, w.length - 3);
      add('${stem}e'); // dancing → dance
      // doubled consonant: running → run
      if (stem.length >= 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
        add(stem.substring(0, stem.length - 1));
      }
      add(stem); // plain stem
    }

    // ── -ed  (played→play, danced→dance, smiled→smile) ────────────────────
    if (w.endsWith('ied') && w.length > 4) {
      add('${w.substring(0, w.length - 3)}y'); // studied → study
    } else if (w.endsWith('ed') && w.length > 4) {
      final stem = w.substring(0, w.length - 2);
      add('${stem}e'); // danced → dance
      if (stem.length >= 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
        add(stem.substring(0, stem.length - 1)); // stopped → stop
      }
      add(stem); // played → play
    }

    // ── -s / -es / -ies  (plurals / 3rd-person singular) ──────────────────
    if (w.endsWith('ies') && w.length > 4) {
      add('${w.substring(0, w.length - 3)}y'); // studies → study
    } else if (w.endsWith('ves') && w.length > 4) {
      add('${w.substring(0, w.length - 3)}f'); // leaves → leaf
      add('${w.substring(0, w.length - 3)}fe'); // knives → knife
    } else if (w.endsWith('es') && w.length > 3) {
      add(w.substring(0, w.length - 2)); // boxes → box
      add(w.substring(0, w.length - 1)); // makes → make
    } else if (w.endsWith('s') && w.length > 3 && !w.endsWith('ss')) {
      add(w.substring(0, w.length - 1)); // cats → cat
    }

    // ── -ly  (quickly→quick, beautifully→beautiful) ────────────────────────
    if (w.endsWith('ily') && w.length > 5) {
      add('${w.substring(0, w.length - 3)}y'); // happily → happy
    } else if (w.endsWith('ly') && w.length > 4) {
      add(w.substring(0, w.length - 2)); // quickly → quick
    }

    // ── -er / -est  (comparatives) ─────────────────────────────────────────
    if (w.endsWith('est') && w.length > 5) {
      add(w.substring(0, w.length - 3)); // fastest → fast
      add('${w.substring(0, w.length - 3)}e'); // latest → late
    } else if (w.endsWith('er') && w.length > 4 &&
        !w.endsWith('eer') &&
        !w.endsWith('ier')) {
      add(w.substring(0, w.length - 2)); // faster → fast
      add('${w.substring(0, w.length - 2)}e'); // later → late
    }

    // ── -tion / -sion  (creation→create, decision→decide) ─────────────────
    if (w.endsWith('ation') && w.length > 7) {
      add('${w.substring(0, w.length - 5)}e'); // creation → create
      add(w.substring(0, w.length - 5)); // creation → creat
    } else if (w.endsWith('tion') && w.length > 6) {
      add('${w.substring(0, w.length - 4)}t'); // action → act
    }

    // Limit to first 5 candidates to avoid excessive API calls
    return out.take(5).toList();
  }

  WordDefinition _parse(List<dynamic> data) {
    if (data.isEmpty) return const WordDefinition();
    final entry = data.first as Map<String, dynamic>;

    final phonetics = entry['phonetics'] as List<dynamic>? ?? [];
    final phonetic = phonetics
        .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');

    final meanings = entry['meanings'] as List<dynamic>? ?? [];
    if (meanings.isEmpty) return WordDefinition(phonetic: phonetic);

    final m = meanings.first as Map<String, dynamic>;
    final pos = m['partOfSpeech'] as String? ?? '';
    final defs = m['definitions'] as List<dynamic>? ?? [];
    if (defs.isEmpty) return WordDefinition(phonetic: phonetic, partOfSpeech: pos);

    final d = defs.first as Map<String, dynamic>;
    return WordDefinition(
      phonetic: phonetic,
      partOfSpeech: pos,
      definition: d['definition'] as String? ?? '',
      example: d['example'] as String? ?? '',
    );
  }
}
