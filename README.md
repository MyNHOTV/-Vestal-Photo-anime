# flutter_quick_base

Base Flutter template optimized for **2–4 week** projects.
- **GetX** for state + navigation
- **Lean Clean Architecture** (domain/data/presentation)
- **Dio** networking with an `ApiProvider.shared.xxxAPI.methodName(success, fail)` style
- **JSON** via `json_serializable`
- **easy_localization** with `assets/i18n/*.json`
- **env & flavors** via `flutter_dotenv` + `--dart-define`
- **Hive** (optional) for lightweight storage
- Basic tests, lints, and scripts

## Quick start

```bash
# 1) Get packages
flutter pub get

# 2) Generate code (models from json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 3) Run with a flavor (dev by default)
flutter run --dart-define=FLAVOR=dev --dart-define=ENABLE_LOG=true
```

## Directory layout

```
lib/
  core/
    config/
    network/
    utils/
    widgets/
  features/
    home/
      data/ domain/ presentation/
    sample_api/
      data/ domain/ presentation/
  app.dart
  main.dart
assets/i18n/
test/
tool/
```

## Flavors

Use `--dart-define`:

- `FLAVOR=dev|stg|prod`
- `ENABLE_LOG=true|false`

Dotenv files:
- `.env.dev`
- `.env.stg`
- `.env.prod`

## API pattern

```dart
ApiProvider.shared.sampleAPI.getSomething(
  success: (data) { /* ... */ },
  fail: (error) { /* ... */ },
);
```

## Notes
- Replace `sample_api` with your real feature.
- If you already have `CPullToRefresh`, drop it into `lib/core/widgets/` and import it in your screens.
