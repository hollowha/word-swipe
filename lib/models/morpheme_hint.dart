class MorphemeHint {
  final String kind;
  final String form;
  final String meaning;
  final String themeCategory;
  final String matchedWord;
  final List<String> relatedWords;

  const MorphemeHint({
    required this.kind,
    required this.form,
    required this.meaning,
    required this.themeCategory,
    required this.matchedWord,
    this.relatedWords = const [],
  });

  factory MorphemeHint.fromJson(Map<String, dynamic> json) {
    return MorphemeHint(
      kind: json['kind'] as String? ?? '',
      form: json['form'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      themeCategory: json['themeCategory'] as String? ?? '',
      matchedWord: json['matchedWord'] as String? ?? '',
      relatedWords: (json['relatedWords'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'form': form,
      'meaning': meaning,
      'themeCategory': themeCategory,
      'matchedWord': matchedWord,
      'relatedWords': relatedWords,
    };
  }
}
