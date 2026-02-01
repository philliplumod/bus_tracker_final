# Quick Reference Guide - Local Persistence & State Management

## 🚀 Quick Start

### Access Favorites

```dart
// Get cubit
final favoritesCubit = context.read<FavoritesCubit>();

// Add favorite
await favoritesCubit.addFavorite(
  FavoriteLocation(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'SM Cebu',
    latitude: 10.3113,
    longitude: 123.9183,
    addedAt: DateTime.now(),
  ),
);

// Check if favorite
bool isFavorite = favoritesCubit.isFavorite('SM Cebu');

// Get all favorites
List<FavoriteLocation> favorites = favoritesCubit.state.favorites;

// Remove favorite
await favoritesCubit.removeFavorite(favoriteId);
```

### Access Recent Searches

```dart
// Get cubit
final recentSearchesCubit = context.read<RecentSearchesCubit>();

// Add search (automatically deduplicates and limits to 10)
await recentSearchesCubit.addSearch('Ayala Center');

// Get recent query strings
List<String> recentQueries = recentSearchesCubit.getRecentQueries();

// Get full search objects (with timestamps)
List<RecentSearch> searches = recentSearchesCubit.state.searches;

// Remove specific search
await recentSearchesCubit.removeSearch('Ayala Center');

// Clear all
await recentSearchesCubit.clearRecentSearches();
```

### Listen to State Changes

```dart
// Favorites
BlocBuilder<FavoritesCubit, FavoritesState>(
  builder: (context, state) {
    if (state.isLoading) return CircularProgressIndicator();
    if (state.error != null) return Text('Error: ${state.error}');

    return ListView.builder(
      itemCount: state.favorites.length,
      itemBuilder: (context, index) {
        final fav = state.favorites[index];
        return ListTile(
          title: Text(fav.name),
          subtitle: Text('${fav.latitude}, ${fav.longitude}'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => context.read<FavoritesCubit>().removeFavorite(fav.id),
          ),
        );
      },
    );
  },
);

// Recent Searches
BlocBuilder<RecentSearchesCubit, RecentSearchesState>(
  builder: (context, state) {
    return ListView.builder(
      itemCount: state.searches.length,
      itemBuilder: (context, index) {
        final search = state.searches[index];
        return ListTile(
          title: Text(search.query),
          subtitle: Text(search.searchedAt.toString()),
          onTap: () {
            // Use the search query
            context.read<TripSolutionBloc>().add(
              SearchTripSolution(search.query),
            );
          },
        );
      },
    );
  },
);
```

### App Preferences (Direct Access)

```dart
// Initialize in DI
final prefs = await SharedPreferences.getInstance();
final appPrefs = AppPreferencesDataSourceImpl(prefs: prefs);

// Use preferences
bool notificationsOn = await appPrefs.getNotificationsEnabled();
await appPrefs.setNotificationsEnabled(false);

String mapType = await appPrefs.getMapType(); // 'normal', 'satellite', 'terrain', 'hybrid'
await appPrefs.setMapType('satellite');

bool showTraffic = await appPrefs.getShowTraffic();
await appPrefs.setShowTraffic(true);

bool trackingOn = await appPrefs.getTrackingEnabled();
await appPrefs.setTrackingEnabled(true);
```

## 📦 All Available Features

| Feature         | Access                                | Auto-Persisted |
| --------------- | ------------------------------------- | -------------- |
| Authentication  | `context.read<AuthBloc>()`            | ✅             |
| Theme           | `context.read<ThemeCubit>()`          | ✅             |
| Bus Search      | `context.read<BusSearchBloc>()`       | ✅             |
| Trip Solution   | `context.read<TripSolutionBloc>()`    | ✅             |
| Favorites       | `context.read<FavoritesCubit>()`      | ✅             |
| Recent Searches | `context.read<RecentSearchesCubit>()` | ✅             |
| App Preferences | Direct SharedPreferences              | ✅             |
| Bus Cache       | `BusLocalDataSource`                  | ✅ (5 min TTL) |

## 🎯 Common Use Cases

### 1. Show Recent Searches in Search UI

```dart
Widget buildSearchSuggestions() {
  return BlocBuilder<RecentSearchesCubit, RecentSearchesState>(
    builder: (context, state) {
      if (state.searches.isEmpty) {
        return Text('No recent searches');
      }

      return Column(
        children: [
          Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold)),
          ...state.searches.map((search) => ListTile(
            leading: Icon(Icons.history),
            title: Text(search.query),
            onTap: () {
              // Perform search
              context.read<TripSolutionBloc>().add(
                SearchTripSolution(search.query),
              );
            },
          )),
        ],
      );
    },
  );
}
```

### 2. Add to Favorites Button

```dart
IconButton buildFavoriteButton(String locationName, LatLng coords) {
  return BlocBuilder<FavoritesCubit, FavoritesState>(
    builder: (context, state) {
      final cubit = context.read<FavoritesCubit>();
      final isFav = cubit.isFavorite(locationName);

      return IconButton(
        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
        color: isFav ? Colors.red : null,
        onPressed: () async {
          if (isFav) {
            // Find and remove
            final fav = state.favorites.firstWhere(
              (f) => f.name.toLowerCase() == locationName.toLowerCase(),
            );
            await cubit.removeFavorite(fav.id);
          } else {
            // Add new favorite
            await cubit.addFavorite(
              FavoriteLocation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: locationName,
                latitude: coords.latitude,
                longitude: coords.longitude,
                addedAt: DateTime.now(),
              ),
            );
          }
        },
      );
    },
  );
}
```

### 3. Favorites List Page

```dart
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Locations'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              context.read<FavoritesCubit>().clearFavorites();
            },
          ),
        ],
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorites yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.favorites.length,
            itemBuilder: (context, index) {
              final fav = state.favorites[index];
              return ListTile(
                leading: Icon(Icons.place),
                title: Text(fav.name),
                subtitle: Text('Added ${fav.addedAt.toString().split('.')[0]}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    context.read<FavoritesCubit>().removeFavorite(fav.id);
                  },
                ),
                onTap: () {
                  // Navigate to location
                  context.read<TripSolutionBloc>().add(
                    SearchTripSolution(fav.name),
                  );
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

### 4. Save Search Query

```dart
void performSearch(BuildContext context, String query) {
  // Save to recent searches
  context.read<RecentSearchesCubit>().addSearch(query);

  // Perform actual search
  context.read<TripSolutionBloc>().add(SearchTripSolution(query));
}
```

### 5. Settings Page with Preferences

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // Theme Toggle
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return SwitchListTile(
                title: Text('Dark Mode'),
                value: state.isDarkMode,
                onChanged: (value) {
                  context.read<ThemeCubit>().toggleTheme();
                },
              );
            },
          ),

          // Clear Recent Searches
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Clear Recent Searches'),
            onTap: () {
              context.read<RecentSearchesCubit>().clearRecentSearches();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Recent searches cleared')),
              );
            },
          ),

          // Clear Favorites
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text('Clear Favorites'),
            onTap: () {
              context.read<FavoritesCubit>().clearFavorites();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Favorites cleared')),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

## 🔄 Automatic Behaviors

### What Persists Automatically:

- ✅ User authentication state
- ✅ Theme preference (light/dark)
- ✅ Last bus search query and results
- ✅ Last trip solution search and results
- ✅ All favorite locations
- ✅ Recent search history (last 10)
- ✅ App preferences (notifications, map type, etc.)

### What Gets Refreshed:

- 🔄 Bus locations (cached for 5 minutes)
- 🔄 User GPS location (fetched on demand)
- 🔄 Real-time bus updates (via Firebase stream)

## 💡 Tips

1. **Add to Recent Searches**: Call after user submits search, not on every keystroke
2. **Favorites**: Use unique IDs (timestamp or UUID) to avoid conflicts
3. **Error Handling**: All persistence methods fail silently - check state.error if needed
4. **Performance**: HydratedBloc automatically debounces saves
5. **Testing**: Use `HydratedBloc.storage = await HydratedStorage.build(...)` in tests

## 🐛 Debugging

### Clear All Cached Data (for testing):

```dart
// In your test or debug menu
Future<void> clearAllCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  context.read<FavoritesCubit>().clearFavorites();
  context.read<RecentSearchesCubit>().clearRecentSearches();
  context.read<AuthBloc>().add(SignOutRequested());
}
```

### Check if Data is Persisting:

```dart
// Add logging to observe persistence
class DebugFavoritesCubit extends FavoritesCubit {
  @override
  void onChange(Change<FavoritesState> change) {
    super.onChange(change);
    debugPrint('FavoritesState changed: ${change.currentState.favorites.length} -> ${change.nextState.favorites.length}');
  }
}
```

## 📱 Platform Differences

| Platform | Storage Location                     | Notes             |
| -------- | ------------------------------------ | ----------------- |
| Android  | `/data/data/[package]/shared_prefs/` | XML files         |
| iOS      | `NSUserDefaults`                     | Binary plist      |
| Windows  | Registry or app folder               | Platform-specific |
| Web      | LocalStorage                         | JSON strings      |

All handled automatically by shared_preferences and HydratedBloc! 🎉
