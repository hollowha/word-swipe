#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
WORDS_DIR = ROOT / "assets" / "words"
INSIGHTS_DIR = ROOT / "assets" / "insights"
REPORT_PATH = ROOT / "assets" / "quality_report.json"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
BAD_GLYPHS = ("�", "阞", "伄", "繚", "臘", "疆", "刉", "簸", "帣", "?")
REQUIRED_WORD_FIELDS = {
    "id",
    "word",
    "cefrLevel",
    "definitionLoaded",
    "frequencyRank",
    "usefulnessScore",
    "sourceTags",
    "lemma",
    "isCore",
    "qualityFlags",
}


def load_json(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a list")
    return data


def has_bad_glyphs(value: str) -> bool:
    return any(glyph in value for glyph in BAD_GLYPHS)


def validate() -> dict[str, Any]:
    report: dict[str, Any] = {"levels": {}, "issues": []}
    all_words: list[str] = []

    for level in LEVELS:
        words_path = WORDS_DIR / f"{level}_words.json"
        insights_path = INSIGHTS_DIR / f"{level}_insights.json"
        words = load_json(words_path)
        insights = load_json(insights_path)
        insight_by_id = {str(item.get("wordId")): item for item in insights}

        level_issues = []
        for item in words:
            missing = sorted(REQUIRED_WORD_FIELDS.difference(item))
            if missing:
                level_issues.append({"word": item.get("word"), "missing": missing})
            word = str(item.get("word", ""))
            all_words.append(word)
            if re.search(r"--|(?:[a-z]-){2,}[a-z]+", word):
                level_issues.append({"word": word, "issue": "malformed-hyphen"})
            insight = insight_by_id.get(str(item.get("id")))
            if not insight:
                level_issues.append({"word": word, "issue": "missing-insight-record"})
                continue
            text = " ".join(
                str(insight.get(key, ""))
                for key in ("phonetic", "definition", "example")
            )
            if has_bad_glyphs(text):
                level_issues.append({"word": word, "issue": "mojibake"})

        report["levels"][level.upper()] = {
            "wordCount": len(words),
            "insightCount": len(insights),
            "hasInsightCount": sum(1 for item in insights if item.get("hasInsight")),
            "issueCount": len(level_issues),
            "issues": level_issues[:200],
        }

    duplicates = [
        {"word": word, "count": count}
        for word, count in Counter(all_words).items()
        if count > 1
    ]
    report["duplicateCount"] = len(duplicates)
    report["duplicates"] = duplicates[:200]
    return report


def main() -> None:
    report = validate()
    REPORT_PATH.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    total_issues = sum(level["issueCount"] for level in report["levels"].values())
    print(f"Wrote {REPORT_PATH}")
    print(f"Duplicate groups: {report['duplicateCount']}")
    print(f"Asset issues: {total_issues}")
    if report["duplicateCount"] or total_issues:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
