# G-POINT v1.0 Foundation

A personal point and business management app foundation for Android/iOS.

## Included in this foundation
- G-POINT branding
- iOS-inspired page transitions and motion system
- Light/Dark mode
- Bangla/English toggle
- SQLite local database
- Player Master (name, phone, Gmail, notes, balance)
- Point ledger (ADD / SPEND / REFUND)
- Payment records
- Expense records
- Dashboard summary
- Player search and detail history
- GitHub Actions APK build workflow

## Not falsely claimed as complete
Cloud sync, admin authentication, vouchers, reports export, automated backup/restore and audit-grade permissions are planned for the next implementation stages.

## Build
Use Flutter stable:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
