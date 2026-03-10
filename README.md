# WaterMemo

**WaterMemo** is a robust Flutter application designed for seamless water delivery management. It provides salesmen with efficient tools for inventory tracking, customer management, and transaction recording, even in areas with unreliable internet connectivity.

## Core Features

### Seamless Offline-Online Synchronization
WaterMemo utilizes Firebase's Offline Persistence capabilities to handle network inconsistencies. If a salesman enters data in a low-signal area, the app caches the transaction locally. Once a stable connection is re-established, the Firebase SDK automatically synchronizes the local changes with the server. 

To prevent data overwriting, Firebase Transactions are implemented for critical fields like **Stock Count** and **Cash Collection**, ensuring that concurrent updates from multiple devices are merged accurately without data loss.

### Real-time Communication
The app integrates an internet connectivity warning system that alerts users when they are offline, while continuing to allow data entry thanks to its offline-first architecture.

## Technical Details

- **State Management:** Flutter Bloc
- **Backend:** Firebase Realtime Database & Firebase Auth
- **Persistence:** Offline Disk Persistence (10MB Cache)
- **Dependency Injection:** GetIt (Service Locator)

## Getting Started

1.  **Dependencies:** Run `flutter pub get`.
2.  **Firebase:** Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are configured.
3.  **Run:** `flutter run`.

