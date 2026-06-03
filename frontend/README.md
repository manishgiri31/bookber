# BookBer Flutter Frontend

A modern Flutter mobile & web app for barber shop booking, built with Riverpod state management and a comprehensive design system.

## Architecture

### Design System (`lib/core/theme/`)
- **AppTheme**: Dark-only theme with electric teal (#00E5C3) accent
- **AppColors**: Centralized color tokens matching BookBer design spec
  - Backgrounds: Primary (#0D0D0F), Secondary (#141417), Tertiary (#1C1C21)
  - Text: Primary (#F5F5F7), Secondary (#8A8A9A), Tertiary (#4A4A5A)
  - Semantic: Success (#22C55E), Error (#EF4444), Warning (#F59E0B)

### Shared Widgets (`lib/core/widgets/`)
- **BookerTextField**: Custom text input with password toggle, validation
- **BookerButton**: Multi-variant button (primary, outlined, ghost, danger) with loading state
- **BookerBottomSheet**: Draggable bottom sheet with handle bar and title
- **ShimmerLoader**: Teal-based shimmer loading indicator
- **StatusBadge**: Semantic status pills (active/inactive/pending/warning/error)
- **EmptyState**: Centered icon + title + subtitle + optional action

### Utils (`lib/core/utils/`)
- **BookerSnackbar**: Static notification methods (.success, .error, .info, .warning)

### Navigation (`lib/core/router/`)
- **GoRouter** with route guards for authentication/role-based access
- Customer routes: `/home`, `/explore`, `/bookings`, `/profile`
- Barber routes: `/barber/queue`, `/barber/schedule`, `/barber/profile`
- Admin routes: `/admin`
- Guards: `customerGuard`, `barberGuard`, `adminGuard` (redirect to `/login` if unauthorized)

## Dependencies

- **State Management**: `flutter_riverpod`, `hooks_riverpod`
- **Routing**: `go_router`
- **HTTP**: `dio`
- **Location**: `geolocator`, `latlong2`, `flutter_map`
- **UI**: `shimmer`, `cached_network_image`, `lottie`
- **Auth**: `firebase_core`, `firebase_messaging`
- **Storage**: `hive`, `hive_flutter`, `flutter_secure_storage`
- **Codegen**: `freezed`, `json_serializable`, `retrofit_generator`

## Build & Run

### Prerequisites
- Flutter SDK 3.11.5+
- Dart 3.11.5+

### Web Build (Recommended for testing)
```bash
cd frontend/app
flutter pub get
flutter build web --release
# Output: build/web/
# Serve with any HTTP server or deploy to Netlify/Firebase Hosting
```

### Android Build
```bash
# Requires Android SDK, Gradle, and internet connection for Maven repos
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### iOS Build
```bash
# Requires Xcode, CocoaPods
flutter build ios --release
# Output: build/ios/iphoneos/
```

### Development Mode
```bash
flutter run
# Starts app in debug mode (hot reload enabled)
```

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart    # Theme definition
│   ├── widgets/               # Shared UI components
│   │   ├── booker_button.dart
│   │   ├── booker_text_field.dart
│   │   ├── booker_bottom_sheet.dart
│   │   ├── shimmer_loader.dart
│   │   ├── status_badge.dart
│   │   └── empty_state.dart
│   ├── utils/
│   │   └── snackbar.dart      # Notification utilities
│   ├── router/
│   │   └── app_router.dart    # GoRouter configuration
│   ├── config/                # App config & constants
│   ├── middleware/            # Interceptors, guards
│   └── errors/                # Error handling
├── features/                  # Feature modules
│   ├── auth/
│   ├── booking/
│   ├── queue/
│   ├── payment/
│   └── ...
├── app/                       # App-level providers
└── services/                  # API, storage, location clients
```

## Typography

- **Display Font**: Satoshi (32px, 24px, 18px)
- **Body Font**: DM Sans (16px, 14px, 12px)
- Weights: 700 (headings), 600 (subheadings), 400 (body)

## Design Tokens Summary

| Token | Value |
|-------|-------|
| Accent Primary | #00E5C3 |
| Background Primary | #0D0D0F |
| Background Secondary | #141417 |
| Text Primary | #F5F5F7 |
| Success | #22C55E |
| Error | #EF4444 |
| Warning | #F59E0B |

**Spacing**: 4/8/12/16/20/24/32/48px  
**Border Radius**: 8 (small), 12 (medium), 16 (large), 24 (xl), 999 (pill)  
**Animations**: 300ms page transitions (slide+fade), 150ms button press (scale 0.96)

## State Management with Riverpod

All feature modules follow Riverpod patterns:

```dart
// Providers (lib/features/booking/providers.dart)
final bookingProvider = FutureProvider<Booking>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getBooking(...);
});

// Widget consumption
Consumer(builder: (ctx, ref, _) {
  final booking = ref.watch(bookingProvider);
  return booking.when(
    data: (b) => BookingCard(booking: b),
    loading: () => ShimmerLoader(),
    error: (err, st) => Text('Error: $err'),
  );
})
```

## Placeholder Screens

All route endpoints have minimal placeholder screens. Replace these with full implementations:
- `SplashScreen` → App initialization, auth check
- `LoginScreen` → Email/password form + social login
- `RegisterScreen` → User signup flow
- `ExploreScreen` → Search & filter barber shops
- `BookingFlowScreen` → Multi-step booking wizard
- `CustomerHomeScreen` → Bookings list & quick actions

## Next Steps

1. **Complete Auth Flow**: Integrate Firebase Auth + JWT
2. **Implement API Integration**: Connect to backend endpoints via Dio + Retrofit
3. **Add Feature Screens**: Replace placeholders with real UI
4. **Set Up State Providers**: Create Riverpod providers for each feature
5. **Testing**: Unit tests, widget tests, integration tests
6. **Deployment**: Set up CI/CD for web, iOS, Android releases

---

**Built with ❤️ using Flutter, Riverpod, and the BookBer Design System**
