# Local Persistence & State Management Implementation

## Overview

This document details the comprehensive local persistence and state management implementation for the Bus Tracker app. All features now include robust offline support, state persistence across app restarts, and efficient caching mechanisms.

## 🏗️ Architecture

### State Management Pattern

- **HydratedBloc**: Used for automatic state persistence across app restarts
- **Shared Preferences**: Used for custom caching and user preferences
- **Clean Architecture**: Maintained with dedicated data sources for local storage

## 📦 Implemented Features

### 1. Authentication State Persistence

**Implementation**: `AuthBloc` (HydratedBloc)

**Features**:

- ✅ Automatic login persistence
- ✅ User profile cached locally
- ✅ Survives app restarts
- ✅ Secure state serialization

**Files**:

- `lib/presentation/bloc/auth/auth_bloc.dart` - Hydrated bloc with JSON serialization
- `lib/presentation/bloc/auth/auth_state.dart` - State with toJson/fromJson methods
- `lib/domain/entities/user.dart` - User entity with JSON support

**Usage**:

```dart
// Auth state automatically persists
context.read<AuthBloc>().add(SignInRequested(...));
// On app restart, user remains authenticated
```

---

### 2. Bus Search State Persistence

**Implementation**: `BusSearchBloc` (HydratedBloc)

**Features**:

- ✅ Last search query persisted
- ✅ Filtered bus results cached
- ✅ All buses list cached
- ✅ Search history maintained

**Files**:

- `lib/presentation/bloc/bus_search/bus_search_bloc.dart`
- `lib/presentation/bloc/bus_search/bus_search_state.dart`
- `lib/data/datasources/bus_local_data_source.dart` - Additional caching layer

**Benefits**:

- Users see last search results immediately on app open
- Reduced API calls
- Faster app startup

---

### 3. Trip Solution State Persistence

**Implementation**: `TripSolutionBloc` (HydratedBloc)

**Features**:

- ✅ Last destination search saved
- ✅ Matching buses cached
- ✅ User location persisted
- ✅ Destination coordinates saved

**Files**:

- `lib/presentation/bloc/trip_solution/trip_solution_bloc.dart`
- `lib/presentation/bloc/trip_solution/trip_solution_state.dart`
- `lib/domain/entities/user_location.dart` - Location entity with JSON support

**Usage Example**:

```dart
// Last search is restored on app restart
context.read<TripSolutionBloc>().add(SearchTripSolution('SM Cebu'));
```

---

### 4. Bus Data Caching

**Implementation**: `BusLocalDataSource` (SharedPreferences)

**Features**:

- ✅ 5-minute cache validity
- ✅ Automatic cache expiration
- ✅ Offline data access
- ✅ Timestamp tracking

**File**: `lib/data/datasources/bus_local_data_source.dart`

**Key Methods**:

```dart
Future<List<Bus>> getCachedBuses();
Future<void> cacheBuses(List<Bus> buses);
Future<void> clearCachedBuses();
Future<DateTime?> getLastUpdateTime();
```

**Cache Strategy**:

- Fresh data cached for 5 minutes
- Stale cache automatically cleared
- Fallback to empty list if cache invalid

---

### 5. Favorite Locations Feature

**Implementation**: `FavoritesCubit` (HydratedBloc) + `FavoritesLocalDataSource`

**Features**:

- ✅ Save favorite destinations
- ✅ Quick access to frequent locations
- ✅ Add/remove favorites
- ✅ Persistent across sessions

**Files**:

- `lib/presentation/cubit/favorites_cubit.dart` - State management
- `lib/data/datasources/favorites_local_data_source.dart` - Persistence layer
- `lib/domain/entities/favorite_location.dart` - Entity model

**Usage**:

```dart
// Access favorites cubit
final favoritesCubit = context.read<FavoritesCubit>();

// Add favorite
await favoritesCubit.addFavorite(
  FavoriteLocation(
    id: 'sm-cebu',
    name: 'SM Cebu',
    latitude: 10.3113,
    longitude: 123.9183,
    addedAt: DateTime.now(),
  ),
);

// Check if favorite
bool isFav = favoritesCubit.isFavorite('SM Cebu');

// Remove favorite
await favoritesCubit.removeFavorite('sm-cebu');

// Get all favorites
final favorites = favoritesCubit.state.favorites;
```

---

### 6. Recent Searches Feature

**Implementation**: `RecentSearchesCubit` (HydratedBloc) + `RecentSearchesDataSource`

**Features**:

- ✅ Track last 10 searches
- ✅ Auto-deduplication
- ✅ Sorted by recency
- ✅ Clear individual or all searches

**Files**:

- `lib/presentation/cubit/recent_searches_cubit.dart` - State management
- `lib/data/datasources/recent_searches_data_source.dart` - Persistence layer

**Usage**:

```dart
// Access recent searches cubit
final recentSearchesCubit = context.read<RecentSearchesCubit>();

// Add search
await recentSearchesCubit.addSearch('Ayala Center');

// Get recent queries
List<String> queries = recentSearchesCubit.getRecentQueries();

// Remove specific search
await recentSearchesCubit.removeSearch('Ayala Center');

// Clear all
await recentSearchesCubit.clearRecentSearches();

// Access searches with timestamps
final searches = recentSearchesCubit.state.searches;
```

---

### 7. App Preferences

**Implementation**: `AppPreferencesDataSource` (SharedPreferences)

**Features**:

- ✅ Notification preferences
- ✅ Tracking enabled/disabled
- ✅ Map type selection
- ✅ Traffic overlay toggle

**File**: `lib/data/datasources/app_preferences_data_source.dart`

**Available Preferences**:

```dart
// Notifications
bool notificationsEnabled = await prefs.getNotificationsEnabled();
await prefs.setNotificationsEnabled(true);

// Tracking (for riders)
bool trackingEnabled = await prefs.getTrackingEnabled();
await prefs.setTrackingEnabled(true);

// Map type (normal, satellite, terrain, hybrid)
String mapType = await prefs.getMapType();
await prefs.setMapType('satellite');

// Traffic overlay
bool showTraffic = await prefs.getShowTraffic();
await prefs.setShowTraffic(true);
```

---

### 8. Theme Persistence

**Implementation**: `ThemeCubit` (HydratedBloc) - Already Implemented

**Features**:

- ✅ Light/Dark mode toggle
- ✅ Persists across restarts
- ✅ System theme support

**File**: `lib/theme/theme_cubit.dart`

---

## 🔧 Technical Details

### JSON Serialization

All entities now have `toJson()` and `fromJson()` methods:

**Entities with JSON Support**:

1. `Bus` - Bus information
2. `User` - User profile with role
3. `UserLocation` - GPS coordinates
4. `FavoriteLocation` - Saved destinations
5. `RecentSearch` - Search history entry

### HydratedBloc Configuration

Location: `lib/main.dart`

```dart
// Initialize HydratedBloc storage
final appDoc = await getApplicationDocumentsDirectory();
HydratedBloc.storage = await HydratedStorage.build(
  storageDirectory: HydratedStorageDirectory(appDoc.path),
);
```

All HydratedBlocs automatically:

- Save state on changes
- Restore state on app start
- Handle serialization errors gracefully

---

## 📊 Dependency Injection

**File**: `lib/core/di/dependency_injection.dart`

All new features are registered in DI:

```dart
static List<BlocProvider> get providers => [
  BlocProvider<ThemeCubit>(...),
  BlocProvider<AuthBloc>(...),
  BlocProvider<MapBloc>(...),
  BlocProvider<BusSearchBloc>(...),
  BlocProvider<TripSolutionBloc>(...),
  BlocProvider<FavoritesCubit>(...),      // NEW
  BlocProvider<RecentSearchesCubit>(...), // NEW
];
```

---

## 🚀 Usage Guidelines

### Accessing State

```dart
// Read state
final favorites = context.read<FavoritesCubit>().state.favorites;

// Listen to changes
BlocBuilder<FavoritesCubit, FavoritesState>(
  builder: (context, state) {
    return ListView.builder(
      itemCount: state.favorites.length,
      itemBuilder: (context, index) {
        final fav = state.favorites[index];
        return ListTile(title: Text(fav.name));
      },
    );
  },
);
```

### Triggering Actions

```dart
// Add to favorites
context.read<FavoritesCubit>().addFavorite(location);

// Add to recent searches
context.read<RecentSearchesCubit>().addSearch(query);

// Search for bus
context.read<BusSearchBloc>().add(SearchBusByNumber('123'));
```

---

## 💾 Storage Locations

### HydratedBloc Storage

- **Path**: App Documents Directory
- **Format**: JSON files
- **Auto-managed**: Yes
- **Size**: Minimal (~1-5MB total)

### SharedPreferences

- **Platform**: Native storage
- **Android**: XML files in SharedPreferences
- **iOS**: NSUserDefaults
- **Windows**: Registry/App folder

---

## 🔒 Data Privacy & Security

1. **Local Only**: All persistence is local to device
2. **No Sensitive Data**: Passwords are not stored
3. **Auth Tokens**: Stored securely via SharedPreferences
4. **User Control**: Clear methods available for all cached data

---

## 🎯 Benefits

### For Users

- ✅ **Instant app startup** - Last viewed data loads immediately
- ✅ **Offline access** - View cached buses without internet
- ✅ **Seamless experience** - No re-login required
- ✅ **Quick searches** - Recent searches readily available
- ✅ **Favorites** - One-tap access to frequent destinations

### For Developers

- ✅ **Clean architecture** - Separation of concerns maintained
- ✅ **Testable** - Data sources can be mocked
- ✅ **Maintainable** - Clear state management pattern
- ✅ **Scalable** - Easy to add new persisted features

---

## 🐛 Error Handling

All persistence operations have built-in error handling:

```dart
try {
  // Serialization/deserialization
  return state.toJson();
} catch (e) {
  // Gracefully return null, bloc uses default initial state
  return null;
}
```

This ensures:

- App never crashes due to corrupted cache
- Automatic fallback to fresh state
- Silent recovery from storage errors

---

## 📝 Future Enhancements

Potential additions:

1. **Export/Import Settings** - Backup favorites & preferences
2. **Cloud Sync** - Sync favorites across devices
3. **Search Analytics** - Track most searched destinations
4. **Route History** - Remember frequently traveled routes
5. **Offline Maps** - Cache map tiles for offline use

---

## 🔍 Testing Persistence

### Test Scenarios

1. **App Restart Test**:
   - Search for buses
   - Close app completely
   - Reopen app
   - ✅ Search results should be visible immediately

2. **Favorites Test**:
   - Add favorite location
   - Kill app
   - Reopen app
   - ✅ Favorite should still be present

3. **Theme Test**:
   - Toggle dark mode
   - Restart app
   - ✅ Dark mode should persist

4. **Cache Expiry Test**:
   - Wait 5+ minutes
   - Reopen app
   - ✅ Cached buses should be refreshed

---

## 📚 Related Files

### Core Files

- `lib/main.dart` - HydratedBloc initialization
- `lib/core/di/dependency_injection.dart` - All providers

### State Management

- `lib/presentation/bloc/auth/*` - Auth persistence
- `lib/presentation/bloc/bus_search/*` - Search persistence
- `lib/presentation/bloc/trip_solution/*` - Trip persistence
- `lib/presentation/cubit/favorites_cubit.dart` - Favorites
- `lib/presentation/cubit/recent_searches_cubit.dart` - Recent searches

### Data Sources

- `lib/data/datasources/bus_local_data_source.dart` - Bus caching
- `lib/data/datasources/app_preferences_data_source.dart` - App settings
- `lib/data/datasources/favorites_local_data_source.dart` - Favorites storage
- `lib/data/datasources/recent_searches_data_source.dart` - Search history

### Entities

- `lib/domain/entities/bus.dart` - Bus with JSON
- `lib/domain/entities/user.dart` - User with JSON
- `lib/domain/entities/user_location.dart` - Location with JSON
- `lib/domain/entities/favorite_location.dart` - Favorite location

---

## ✅ Summary

The Bus Tracker app now has comprehensive local persistence and state management:

| Feature         | Technology                       | Status      |
| --------------- | -------------------------------- | ----------- |
| Authentication  | HydratedBloc                     | ✅ Complete |
| Bus Search      | HydratedBloc                     | ✅ Complete |
| Trip Solution   | HydratedBloc                     | ✅ Complete |
| Theme           | HydratedBloc                     | ✅ Complete |
| Favorites       | HydratedBloc + SharedPreferences | ✅ Complete |
| Recent Searches | HydratedBloc + SharedPreferences | ✅ Complete |
| Bus Caching     | SharedPreferences                | ✅ Complete |
| App Preferences | SharedPreferences                | ✅ Complete |

All features are production-ready and follow Flutter best practices! 🎉
