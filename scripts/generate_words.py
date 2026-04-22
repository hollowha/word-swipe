#!/usr/bin/env python3
"""
generate_words.py
Generates 20,000 CEFR-classified English words as split JSON asset files.
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
    """Returns {word: cefr_level} from frequency-ranked word list."""
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
            result[word] = frequency_to_cefr(rank)

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


def build_word_set(freq: dict, oxford: dict, denylist: set[str]) -> dict:
    """Merge sources (Oxford takes priority), cap at TARGETS."""
    merged = {
        word: level
        for word, level in {**freq, **oxford}.items()  # Oxford overrides freq
        if not is_noise_token(word, denylist)
    }

    by_level = defaultdict(list)
    for word, level in merged.items():
        by_level[level].append(word)

    result = {}
    for level, target in TARGETS.items():
        words = sorted(set(by_level.get(level, [])))
        if len(words) < target:
            print(f'  WARNING: {level} has {len(words)} words (target={target})')
        result[level] = words[:target]
    return result


def make_entry(word: str, level: str) -> dict:
    return {
        'id': word,
        'word': word,
        'cefrLevel': level,
        'partOfSpeech': '',
        'phonetic': '',
        'definition': '',
        'example': '',
        'definitionLoaded': False,
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
    for level, words in word_set.items():
        path = OUTPUT_DIR / f'{level.lower()}_words.json'
        data = [make_entry(w, level) for w in words]
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
        print(f'  Wrote {path.name}: {len(words)} words')
        total += len(words)

    if total == 0:
        raise SystemExit(
            'Generated zero words. Aborting to avoid keeping empty assets.'
        )

    print(f'\nDone! Total words: {total}')


if __name__ == '__main__':
    main()
