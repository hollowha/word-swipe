# Contributing to WordSwipe

Thanks for helping improve WordSwipe.
This document keeps collaboration predictable, especially because this repo mixes Flutter app code with tracked generated study assets.

感謝你一起協作 WordSwipe。
這份文件的目標是讓 Flutter 程式碼與已追蹤的資料資產可以穩定共存，減少不必要的衝突。

## Workflow

1. Create a branch from the latest `master`.
2. Keep changes scoped to one topic when possible.
3. Run the relevant checks before committing.
4. Open a pull request with a short summary of behavior changes and test results.

## Recommended Local Setup

```bash
flutter pub get
python -m pip install -r scripts/requirements.txt
```

Run the app locally:

```bash
flutter run -d chrome
```

## Checks Before Opening a PR

Required:

```bash
flutter test
```

Recommended when UI, routing, assets, or deployment behavior changed:

```bash
flutter build web --release
```

If you touch Python generation scripts, also make sure the script still runs with the documented dependencies.

## Generated Assets

The following generated assets are intentionally committed:

- `assets/words/*.json`
- `assets/insights/*.json`

Regenerate them only when your change actually affects:

- vocabulary source logic
- filtering rules
- morphology source files
- insight generation behavior

Before committing regenerated assets:

- review the diff carefully
- avoid unrelated formatting churn
- mention in the PR that generated data changed

## Avoiding Conflicts

- Pull the latest branch state before regenerating tracked assets.
- Avoid combining broad asset regeneration with unrelated feature work unless necessary.
- Do not overwrite unrelated changes from other contributors in tracked JSON files.
- If a merge conflict happens in generated assets, prefer regenerating from the latest source and verifying the result rather than resolving blindly by hand.

## What Not to Commit

Please keep these local:

- `build/`
- `.dart_tool/`
- Python virtual environments such as `.venv/` and `venv/`
- Python caches such as `__pycache__/` and `.pytest_cache/`
- local IDE settings and temporary files
- Firebase debug logs

Hive runtime data is local application state and should never be committed.

## Deployment

Firebase deployment is configured for the maintainer environment by default.
Contributors should treat deploy commands as opt-in and maintainer-controlled unless they have configured their own Firebase project.

## Questions

If a change affects both app behavior and generated assets, call that out clearly in the PR description so reviewers know to inspect both code and data diffs.
