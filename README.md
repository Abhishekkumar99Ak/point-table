# Point Table

All Games Esports Manager: a Flutter tournament manager with configurable scoring, team cards, on-device scoreboard OCR, standings, and exportable graphics.

## Setup

Install the Flutter stable SDK and Android Studio with Android SDK Platform 35 and Java 17. Android Gradle host files are included. Set your local SDK paths by copying `android/local.properties.example` to `android/local.properties` and editing both paths, then run:

```sh
flutter pub get
flutter run -d <android-device-id>
```

For a fresh Flutter installation that requires the standard Gradle wrapper scripts, run `flutter create --platforms=android .` once after installing the SDK. Android uses `minSdk` 23 for on-device ML Kit OCR. Gallery save permission is requested at download time; legacy storage declarations are included for Android 10 and earlier. `assets/images/logo.png` is an original Point Table trophy badge and is configured for the app header, Android launcher, and native splash. The poster editor still uses replaceable remote esports-themed background imagery; replace it with licensed art before distribution. iOS host files are not included; if adding iOS, set its deployment target to 15.5 or later and add `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`.

## Features

- Create tournaments with BGMI, FreeFire, additional game presets, round-robin mode and editable kill/placement points.
- Choose open registration or manual team entry, build team cards with logos/player photos, and share rosters.
- Paste newline-separated team names into slots 1–12; explicit slots, duplicate names, team tags, logos and player photos are retained in tournament exports.
- Import tournaments from JSON, CSV, or XLSX; export JSON/backups; merge events; and preserve tournament data locally between launches.
- Read lobby and result screenshots on-device with Google ML Kit text recognition. Review 12 lobby slots, remember a lobby locally, map results to registered teams, correct player kills and confirm a match with Save All.
- Save match-specific standings, compare match and overall tables, and sort by points or kills. Deleted tournaments can be restored or permanently removed from Trash.
- Export standings as a shareable poster. Results can also be added manually.
- Customize standings, Warheads MVP, Fraggers, 12-slot team announcement, slot list and certificate graphics with hue/saturation/brightness/contrast, uploaded backgrounds, game selection, event/social labels, search, HD PNG download and native sharing.
- Use the device-local Admin Gate to protect tournament creation, OCR scanning and poster export. The passcode is salted and hashed locally; it is not a server identity system.
- Configure support email, Instagram and privacy-policy links in Account. Version is displayed in-app.

Tournament state is stored in the app documents directory; JSON backup/import is available for transfer. Firebase, remote device approvals, subscription tokens and theme sync are not configured. Production online authorization requires a Firebase project, backend verification and security rules; do not use the local Admin Gate as a substitute. Configure your published privacy-policy URL and support contacts in Account before release. An Android SDK is required to build or run the Android target.