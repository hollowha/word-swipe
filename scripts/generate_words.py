#!/usr/bin/env python3
"""
generate_words.py
Generates scored CEFR-classified English word assets.
Output: assets/words/{a1,a2,b1,b2,c1,c2}_words.json

Requirements: pip install requests
Run from the scripts/ directory: python generate_words.py
"""

import json
import re
import unicodedata
from pathlib import Path
from collections import defaultdict
import requests

SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR / 'data'
FILTERS_DIR = DATA_DIR / 'filters'
OUTPUT_DIR = Path(__file__).parent.parent / 'assets' / 'words'
NOISE_TOKENS_PATH = FILTERS_DIR / 'noise_tokens.txt'

TARGETS = {
    'A1': 1500,
    'A2': 2500,
    'B1': 4000,
    'B2': 5000,
    'C1': 4000,
    'C2': 3000,
}

SHORT_ALLOWLIST = {
    'am', 'an', 'as', 'at', 'be', 'by', 'do', 'go', 'he', 'hi', 'if', 'in',
    'is', 'it', 'me', 'my', 'no', 'of', 'oh', 'ok', 'on', 'or', 'so', 'to',
    'up', 'us', 'we',
}

PROPER_NAME_DENYLIST = {
    'aaron', 'abby', 'abbott', 'abe', 'abel', 'abigail', 'aang', 'abba',
    'abbas', 'abbie', 'abbi', 'aaliyah', 'aamir', 'aarav', 'aarhus',
    'aaronson',
}

# Frequency rank → CEFR level cutoffs
CEFR_BANDS = [
    (2000,        'A1'),
    (5000,        'A2'),
    (12000,       'B1'),
    (25000,       'B2'),
    (45000,       'C1'),
    (float('inf'), 'C2'),
]

FREQ_LIST_URL = (
    'https://raw.githubusercontent.com/hermitdave/FrequencyWords/'
    'master/content/2018/en/en_full.txt'
)

OXFORD_CSV_URLS = [
    'https://raw.githubusercontent.com/nicholasgasior/oxford-5000/main/oxford_5000.csv',
    'https://raw.githubusercontent.com/nicholasgasior/oxford-5000/master/oxford_5000.csv',
]


def normalize(w: str) -> str:
    w = unicodedata.normalize('NFKD', w)
    w = w.encode('ascii', 'ignore').decode()
    return w.lower().strip()


def is_valid(w: str) -> bool:
    if len(w) <= 2 and w not in SHORT_ALLOWLIST:
        return False
    return (
        2 <= len(w) <= 30
        and bool(re.match(r'^[a-z][a-z\'\-]*[a-z]$', w))
    )


def load_noise_tokens() -> set[str]:
    if not NOISE_TOKENS_PATH.exists():
        return set()
    return {
        normalize(line)
        for line in NOISE_TOKENS_PATH.read_text(encoding='utf-8').splitlines()
        if line.strip() and not line.strip().startswith('#')
    }


def is_elongated_interjection(word: str) -> bool:
    collapsed = re.sub(r'(.)\1+', r'\1', word)
    return len(word) >= 4 and collapsed in {
        'ah',
        'oh',
        'uh',
        'hm',
        'huh',
        'mm',
        'agh',
        'argh',
        'ow',
        'ha',
    }


def is_fragmented_spoken_form(word: str) -> bool:
    if word.startswith('a-'):
        return True
    return bool(re.fullmatch(r'(?:[a-z]-){2,}[a-z]+', word))


def is_truncated_contraction(word: str) -> bool:
    return word in {
        'aren',
        'couldn',
        'didn',
        'doesn',
        'hadn',
        'hasn',
        'haven',
        'isn',
        'shouldn',
        'wasn',
        'weren',
        'wouldn',
    }


def is_noise_token(word: str, denylist: set[str]) -> bool:
    if word in denylist:
        return True
    if word in PROPER_NAME_DENYLIST:
        return True
    if '--' in word:
        return True
    if re.fullmatch(r'(?:[a-z]+-){2,}[a-z]+', word) and len(word) < 8:
        return True
    if is_truncated_contraction(word):
        return True
    if is_fragmented_spoken_form(word):
        return True
    if is_elongated_interjection(word):
        return True
    return False


def frequency_to_cefr(rank: int) -> str:
    for cutoff, level in CEFR_BANDS:
        if rank <= cutoff:
            return level
    return 'C2'


def load_frequency_list() -> dict:
    """Returns {word: metadata} from a subtitle frequency-ranked word list."""
    print(f'Downloading frequency list from {FREQ_LIST_URL} ...')
    try:
        resp = requests.get(FREQ_LIST_URL, timeout=60)
        resp.raise_for_status()
    except Exception as e:
        print(f'  ERROR: {e}')
        return {}

    result = {}
    for rank, line in enumerate(resp.text.strip().splitlines()[:70000], 1):
        parts = line.split()
        if not parts:
            continue
        word = normalize(parts[0])
        if word and is_valid(word) and word not in result:
            count = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
            result[word] = {
                'level': frequency_to_cefr(rank),
                'frequencyRank': rank,
                'subtitleCount': count,
                'sourceTags': ['opensubtitles2018'],
                'isCore': False,
            }

    print(f'  Loaded {len(result)} words from frequency list.')
    return result


def load_oxford_overrides() -> dict:
    """Returns {word: cefr_level} from Oxford 5000 CSV (best-effort)."""
    for url in OXFORD_CSV_URLS:
        print(f'Trying Oxford CSV: {url} ...')
        try:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            result = {}
            for line in resp.text.strip().splitlines()[1:]:
                parts = line.split(',')
                if len(parts) >= 3:
                    word = normalize(parts[0])
                    level = parts[2].strip().upper()[:2]
                    if word and is_valid(word) and level in TARGETS:
                        result[word] = level
            print(f'  Loaded {len(result)} Oxford override words.')
            return result
        except Exception as e:
            print(f'  Failed: {e}')
    print('  Oxford CSV unavailable — using frequency list only.')
    return {}


def usefulness_score(word: str, record: dict) -> float:
    rank = record.get('frequencyRank') or 70000
    score = max(0.0, 100.0 - (rank / 700.0))
    if record.get('isCore'):
        score += 45
    if 'oxford5000' in record.get('sourceTags', []):
        score += 30
    if '-' in word or "'" in word:
        score -= 8
    if len(word) <= 2:
        score -= 6
    score -= len(record.get('qualityFlags', [])) * 12
    return round(max(score, 0.0), 3)


def quality_flags(word: str) -> list[str]:
    flags = []
    if '-' in word:
        flags.append('hyphenated')
    if "'" in word:
        flags.append('apostrophe')
    if len(word) <= 2:
        flags.append('short-token')
    return flags


def build_word_set(freq: dict, oxford: dict, denylist: set[str]) -> dict:
    """Merge sources, score usefulness, then cap each CEFR level."""
    merged = {}
    for word, record in freq.items():
        if is_noise_token(word, denylist):
            continue
        merged[word] = dict(record)

    for word, level in oxford.items():
        if is_noise_token(word, denylist):
            continue
        record = merged.setdefault(
            word,
            {
                'level': level,
                'frequencyRank': 0,
                'subtitleCount': 0,
                'sourceTags': [],
                'isCore': True,
            },
        )
        record['level'] = level
        record['isCore'] = True
        if 'oxford5000' not in record['sourceTags']:
            record['sourceTags'].append('oxford5000')
        record['qualityFlags'] = quality_flags(word)
        record['usefulnessScore'] = usefulness_score(word, record)

    by_level = defaultdict(list)
    for word, record in merged.items():
        record.setdefault('qualityFlags', quality_flags(word))
        record['usefulnessScore'] = usefulness_score(word, record)
        by_level[record['level']].append((word, record))

    result = {}
    for level, target in TARGETS.items():
        records = sorted(
            by_level.get(level, []),
            key=lambda item: (
                -item[1]['usefulnessScore'],
                item[1].get('frequencyRank') or 999999,
                item[0],
            ),
        )
        if len(records) < target:
            print(f'  WARNING: {level} has {len(records)} words (target={target})')
        result[level] = records[:target]
    return result


def make_entry(word: str, level: str, record: dict) -> dict:
    return {
        'id': word,
        'word': word,
        'cefrLevel': level,
        'partOfSpeech': '',
        'phonetic': '',
        'definition': '',
        'example': '',
        'definitionLoaded': False,
        'frequencyRank': record.get('frequencyRank') or 0,
        'usefulnessScore': record.get('usefulnessScore') or 0,
        'sourceTags': record.get('sourceTags') or [],
        'lemma': word,
        'isCore': bool(record.get('isCore')),
        'qualityFlags': record.get('qualityFlags') or [],
    }


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    denylist = load_noise_tokens()
    print(f'Loaded {len(denylist)} explicit noise tokens.')
    freq = load_frequency_list()
    oxford = load_oxford_overrides()
    if not freq and not oxford:
        raise SystemExit(
            'No source word data could be downloaded. '
            'Aborting to avoid overwriting existing assets with empty files.'
        )
    word_set = build_word_set(freq, oxford, denylist)

    total = 0
    for level, records in word_set.items():
        path = OUTPUT_DIR / f'{level.lower()}_words.json'
        data = [make_entry(word, level, record) for word, record in records]
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
        print(f'  Wrote {path.name}: {len(records)} words')
        total += len(records)

    if total == 0:
        raise SystemExit(
            'Generated zero words. Aborting to avoid keeping empty assets.'
        )

    print(f'\nDone! Total words: {total}')


if __name__ == '__main__':
    main()
