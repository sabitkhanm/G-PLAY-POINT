# G-PLAY POINT — Core UI Layer

Copy these files into the existing project under `g_point_v1/lib/core/`.

## Included

- Central design tokens
- Light/Dark Material 3 theme
- Motion tokens
- Premium card
- Premium button
- Premium text field
- Section header
- Animated counter
- Skeleton loading widgets
- Empty state
- Error state

## Integration

`main.dart` should continue importing:

```dart
import 'core/theme/app_theme.dart';
```

and use:

```dart
theme: AppTheme.light(),
darkTheme: AppTheme.dark(),
```

The current project already has these references.

## Important

The theme uses `Inter` as the primary font family with Bengali/system fallbacks. If a bundled font is later required for deterministic Bengali rendering, add the chosen font files to `assets/fonts/` and declare them in `pubspec.yaml`.
