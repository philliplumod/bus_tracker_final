# Architecture Diagram

## Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                          │
│                                                                     │
│  ┌─────────────────────┐         ┌──────────────────────┐         │
│  │  FavoritesCubit     │         │ RecentSearchesCubit  │         │
│  │  (HydratedBloc)     │         │  (HydratedBloc)      │         │
│  │                     │         │                      │         │
│  │  • State Management │         │  • State Management  │         │
│  │  • Auto Persistence │         │  • Auto Persistence  │         │
│  └──────────┬──────────┘         └──────────┬───────────┘         │
└─────────────┼─────────────────────────────────┼──────────────────────┘
              │                                 │
              ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          DOMAIN LAYER                               │
│                         (Use Cases)                                 │
│                                                                     │
│  ┌────────────────┐  ┌─────────────┐  ┌─────────────────┐        │
│  │ GetFavorites   │  │ AddFavorite │  │ RemoveFavorite  │        │
│  └────────┬───────┘  └──────┬──────┘  └────────┬────────┘        │
│           │                 │                    │                 │
│  ┌────────────────────┐  ┌────────────────┐  ┌──────────────────┐ │
│  │ GetRecentSearches  │  │ AddRecentSearch│  │RemoveRecentSearch│ │
│  └──────────┬─────────┘  └───────┬────────┘  └────────┬─────────┘ │
└─────────────┼────────────────────┼─────────────────────┼───────────┘
              │                    │                     │
              ▼                    ▼                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER (Repositories)                      │
│                         (Interfaces)                                │
│                                                                     │
│     ┌──────────────────────┐      ┌────────────────────────┐      │
│     │ FavoritesRepository  │      │RecentSearchesRepository│      │
│     │    (Interface)       │      │      (Interface)       │      │
│     └──────────┬───────────┘      └──────────┬─────────────┘      │
└────────────────┼─────────────────────────────┼─────────────────────┘
                 │                             │
                 ▼                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      DATA LAYER (Repositories)                      │
│                      (Implementations)                              │
│                                                                     │
│  ┌───────────────────────────┐  ┌────────────────────────────────┐ │
│  │ FavoritesRepositoryImpl   │  │ RecentSearchesRepositoryImpl   │ │
│  │                           │  │                                │ │
│  │  • Error Handling         │  │  • Error Handling              │ │
│  │  • Either<Failure, T>     │  │  • Either<Failure, T>          │ │
│  └─────────────┬─────────────┘  └─────────────┬──────────────────┘ │
└────────────────┼────────────────────────────────┼───────────────────┘
                 │                                │
                 ▼                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     DATA LAYER (Data Sources)                       │
│                                                                     │
│  ┌─────────────────────────────┐  ┌──────────────────────────────┐ │
│  │ FavoritesLocalDataSource    │  │ RecentSearchesDataSource     │ │
│  │                             │  │                              │ │
│  │  • Validation               │  │  • Validation                │ │
│  │  • Duplicate Detection      │  │  • Duplicate Detection       │ │
│  │  • Logging                  │  │  • Logging                   │ │
│  │  • Error Recovery           │  │  • Error Recovery            │ │
│  └──────────────┬──────────────┘  └──────────────┬───────────────┘ │
└─────────────────┼────────────────────────────────┼──────────────────┘
                  │                                │
                  ▼                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         STORAGE LAYER                               │
│                                                                     │
│    ┌─────────────────────┐           ┌────────────────────┐       │
│    │ SharedPreferences   │           │  HydratedBloc      │       │
│    │                     │           │    Storage         │       │
│    │ • Key-Value Store   │◄─────────►│                    │       │
│    │ • Manual Ops        │   Sync    │ • Auto Persistence │       │
│    │ • Explicit Saves    │           │ • State Restore    │       │
│    └─────────────────────┘           └────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

## State Synchronization Flow

```
App Start
    │
    ├─► HydratedBloc restores state automatically
    │
    ├─► Cubit._initializeWithSync() called
    │
    ├─► loadFavorites() / loadRecentSearches()
    │
    ├─► Use Case called
    │
    ├─► Repository fetches from DataSource
    │
    ├─► DataSource reads from SharedPreferences
    │
    └─► State emitted and synced back to HydratedBloc


User Action (e.g., Add Favorite)
    │
    ├─► UI calls cubit.addFavorite()
    │
    ├─► Cubit calls AddFavorite use case
    │
    ├─► Use case calls repository.addFavorite()
    │
    ├─► Repository calls dataSource.addFavorite()
    │
    ├─► DataSource:
    │   ├─► Validates input
    │   ├─► Checks for duplicates
    │   ├─► Writes to SharedPreferences
    │   └─► Logs operation
    │
    ├─► Success/Failure returned up the chain
    │
    ├─► Cubit updates state
    │
    └─► HydratedBloc auto-saves state
```

## Error Handling Flow

```
Operation Fails (e.g., SharedPreferences write error)
    │
    ├─► DataSource catches exception
    │   ├─► Logs error with stack trace
    │   └─► Rethrows exception
    │
    ├─► Repository catches exception
    │   ├─► Wraps in CacheFailure
    │   └─► Returns Left(CacheFailure)
    │
    ├─► Use case returns Either to Cubit
    │
    ├─► Cubit processes result
    │   ├─► Success: Updates state
    │   └─► Failure: Sets error state
    │
    └─► UI displays error or success
```

## Component Responsibilities

### Presentation Layer (Cubits)
- ✅ Manage UI state
- ✅ Coordinate use cases
- ✅ Handle user interactions
- ✅ Emit state changes
- ❌ Direct data access
- ❌ Business logic

### Domain Layer (Use Cases)
- ✅ Single business operation
- ✅ Coordinate repositories
- ✅ Input validation (if needed)
- ❌ State management
- ❌ Data storage
- ❌ UI concerns

### Domain Layer (Repositories - Interfaces)
- ✅ Define data operations contract
- ✅ Return Either<Failure, T>
- ❌ Implementation details
- ❌ Storage mechanism

### Data Layer (Repository Implementations)
- ✅ Implement repository contracts
- ✅ Error handling
- ✅ Data transformation
- ✅ Coordinate data sources
- ❌ Business logic
- ❌ State management

### Data Layer (Data Sources)
- ✅ Direct storage operations
- ✅ Data serialization
- ✅ Validation
- ✅ Duplicate detection
- ✅ Logging
- ❌ Business logic
- ❌ Error wrapping (returns exceptions)

### Storage Layer
- ✅ Persist data
- ✅ Auto-restore (HydratedBloc)
- ❌ Business logic
- ❌ Data validation

## Key Design Principles

1. **Separation of Concerns**: Each layer has a clear, single responsibility
2. **Dependency Inversion**: High-level modules don't depend on low-level modules
3. **Interface Segregation**: Repository interfaces define clear contracts
4. **Single Responsibility**: Each class does one thing well
5. **DRY**: Reusable components throughout the architecture
6. **Fail-Safe**: Comprehensive error handling at every layer
7. **Observable**: Logging at critical points for debugging
8. **Testable**: Each component can be tested in isolation

## Testing Strategy

```
Unit Tests
├─► Use Cases (mock repositories)
├─► Repository Implementations (mock data sources)
├─► Data Sources (mock SharedPreferences)
└─► Cubits (mock use cases)

Integration Tests
├─► Complete data flow
├─► State synchronization
└─► Error scenarios

Widget Tests
├─► UI interactions
└─► State rendering
```
