import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/firebase_realtime_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/bus_remote_data_source.dart';
import '../../data/datasources/location_local_data_source.dart';
import '../../data/datasources/bus_local_data_source.dart';
import '../../data/datasources/app_preferences_data_source.dart';
import '../../data/datasources/favorites_local_data_source.dart';
import '../../data/datasources/recent_searches_data_source.dart';
import '../../data/datasources/rider_location_remote_data_source.dart';
import '../../data/datasources/route_remote_data_source.dart';
import '../../data/datasources/supabase_user_assignment_data_source.dart';
import '../../data/datasources/api_client.dart';
import '../../data/datasources/backend_api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bus_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/repositories/recent_searches_repository_impl.dart';
import '../../data/repositories/rider_location_repository_impl.dart';
import '../../data/repositories/user_assignment_repository_impl.dart';
import '../../data/repositories/route_repository_impl.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/repositories/bus_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/recent_searches_repository.dart';
import '../../domain/repositories/rider_location_repository.dart';
import '../../domain/repositories/user_assignment_repository.dart';
import '../../service/location_tracking_service.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_nearby_buses.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/watch_bus_updates.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/add_favorite.dart';
import '../../domain/usecases/remove_favorite.dart';
import '../../domain/usecases/is_favorite.dart';
import '../../domain/usecases/get_recent_searches.dart';
import '../../domain/usecases/add_recent_search.dart';
import '../../domain/usecases/remove_recent_search.dart';
import '../../domain/usecases/store_rider_location.dart';
import '../../domain/usecases/get_rider_location_history.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_event.dart';
import '../../presentation/bloc/map/map_bloc.dart';
import '../../presentation/bloc/bus_search/bus_search_bloc.dart';
import '../../presentation/bloc/trip_solution/trip_solution_bloc.dart';
import '../../presentation/bloc/settings/app_settings_bloc.dart';
import '../../presentation/bloc/settings/app_settings_event.dart';
import '../../presentation/cubit/favorites_cubit.dart';
import '../../presentation/cubit/recent_searches_cubit.dart';
import '../../presentation/bloc/rider_tracking/rider_tracking_bloc.dart';
import '../../theme/theme_cubit.dart';

class DependencyInjection {
  // Core Services
  static late final HiveService hiveService;
  static late final FirebaseRealtimeService firebaseRealtimeService;

  // API Services
  static late final ApiClient apiClient;
  static late final BackendApiService backendApiService;

  // Data Sources - Remote
  static late final AuthRemoteDataSource authRemoteDataSource;
  static late final BusRemoteDataSource busRemoteDataSource;
  static late final RiderLocationRemoteDataSource riderLocationRemoteDataSource;
  static late final RouteRemoteDataSource routeRemoteDataSource;
  static late final SupabaseUserAssignmentDataSource
  supabaseUserAssignmentDataSource;

  // Data Sources - Local
  static late final LocationLocalDataSource locationLocalDataSource;
  static late final BusLocalDataSource busLocalDataSource;
  static late final AppPreferencesDataSource appPreferencesDataSource;
  static late final FavoritesLocalDataSource favoritesLocalDataSource;
  static late final RecentSearchesDataSource recentSearchesDataSource;

  // Services
  static late final LocationTrackingService locationTrackingService;

  // Repositories
  static late final AuthRepository authRepository;
  static late final BusRepository busRepository;
  static late final LocationRepository locationRepository;
  static late final FavoritesRepository favoritesRepository;
  static late final RecentSearchesRepository recentSearchesRepository;
  static late final RiderLocationRepository riderLocationRepository;
  static late final UserAssignmentRepository userAssignmentRepository;
  static late final RouteRepository routeRepository;
  static late final AppSettingsRepository appSettingsRepository;

  // Use Cases
  static late final SignIn signIn;
  static late final SignUp signUp;
  static late final SignOut signOut;
  static late final GetCurrentUser getCurrentUser;
  static late final GetUserLocation getUserLocation;
  static late final GetNearbyBuses getNearbyBuses;
  static late final WatchBusUpdates watchBusUpdates;
  static late final GetFavorites getFavorites;
  static late final AddFavorite addFavorite;
  static late final RemoveFavorite removeFavorite;
  static late final IsFavorite isFavorite;
  static late final GetRecentSearches getRecentSearches;
  static late final AddRecentSearch addRecentSearch;
  static late final RemoveRecentSearch removeRecentSearch;
  static late final StoreRiderLocation storeRiderLocation;
  static late final GetRiderLocationHistory getRiderLocationHistory;

  static Future<void> init() async {
    // Initialize Hive
    hiveService = HiveService();
    await hiveService.init();

    // Initialize Firebase Realtime Service
    firebaseRealtimeService = FirebaseRealtimeService(
      dbRef: FirebaseDatabase.instance.ref(),
    );

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Initialize API services
    // TODO: Replace with your actual backend URL
    // For physical device: Use your computer's local IP (e.g., 'http://192.168.1.100:3000')
    // For emulator: Use 'http://10.0.2.2:3000'
    // Or use adb reverse: adb reverse tcp:3000 tcp:3000
    apiClient = ApiClient(
      baseUrl:
          'http://localhost:3000', // Change this to your computer's IP for physical devices
      client: http.Client(),
    );
    backendApiService = BackendApiService(apiClient: apiClient);

    // Initialize remote data sources
    authRemoteDataSource = AuthRemoteDataSourceImpl(
      client: http.Client(),
      prefs: prefs,
      apiClient: apiClient,
    );
    busRemoteDataSource = BusRemoteDataSourceImpl(
      busRef: FirebaseDatabase.instance.ref(),
    );
    riderLocationRemoteDataSource = RiderLocationRemoteDataSourceImpl(
      dbRef: FirebaseDatabase.instance.ref(),
      firebaseService: firebaseRealtimeService,
    );
    routeRemoteDataSource = RouteRemoteDataSourceImpl(
      dbRef: FirebaseDatabase.instance.ref(),
    );
    supabaseUserAssignmentDataSource = SupabaseUserAssignmentDataSource();

    // Initialize local data sources
    locationLocalDataSource = LocationLocalDataSourceImpl();
    busLocalDataSource = BusLocalDataSourceImpl(prefs: prefs);
    appPreferencesDataSource = AppPreferencesDataSourceImpl(prefs: prefs);
    favoritesLocalDataSource = FavoritesLocalDataSourceImpl(prefs: prefs);
    recentSearchesDataSource = RecentSearchesDataSourceImpl(prefs: prefs);

    // Initialize services
    locationTrackingService = LocationTrackingService(
      dbRef: FirebaseDatabase.instance.ref(),
      firebaseService: firebaseRealtimeService,
    );

    // Initialize repositories
    authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);
    busRepository = BusRepositoryImpl(remoteDataSource: busRemoteDataSource);
    locationRepository = LocationRepositoryImpl(
      localDataSource: locationLocalDataSource,
    );
    favoritesRepository = FavoritesRepositoryImpl(
      localDataSource: favoritesLocalDataSource,
    );
    recentSearchesRepository = RecentSearchesRepositoryImpl(
      dataSource: recentSearchesDataSource,
    );
    riderLocationRepository = RiderLocationRepositoryImpl(
      remoteDataSource: riderLocationRemoteDataSource,
    );
    userAssignmentRepository = UserAssignmentRepositoryImpl(
      supabaseDataSource: supabaseUserAssignmentDataSource,
    );
    routeRepository = RouteRepositoryImpl(
      remoteDataSource: routeRemoteDataSource,
    );
    appSettingsRepository = AppSettingsRepository(hiveService);

    // Initialize use cases
    signIn = SignIn(authRepository);
    signUp = SignUp(authRepository);
    signOut = SignOut(authRepository);
    getCurrentUser = GetCurrentUser(authRepository);
    getUserLocation = GetUserLocation(locationRepository);
    getNearbyBuses = GetNearbyBuses(busRepository);
    watchBusUpdates = WatchBusUpdates(busRepository);
    getFavorites = GetFavorites(favoritesRepository);
    addFavorite = AddFavorite(favoritesRepository);
    removeFavorite = RemoveFavorite(favoritesRepository);
    isFavorite = IsFavorite(favoritesRepository);
    getRecentSearches = GetRecentSearches(recentSearchesRepository);
    addRecentSearch = AddRecentSearch(recentSearchesRepository);
    removeRecentSearch = RemoveRecentSearch(recentSearchesRepository);
    storeRiderLocation = StoreRiderLocation(riderLocationRepository);
    getRiderLocationHistory = GetRiderLocationHistory(riderLocationRepository);
  }

  static List<BlocProvider> get providers => [
    BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
    BlocProvider<AppSettingsBloc>(
      create:
          (_) =>
              AppSettingsBloc(appSettingsRepository)
                ..add(const LoadAppSettings()),
    ),
    BlocProvider<AuthBloc>(
      create:
          (_) => AuthBloc(
            signIn: signIn,
            signUp: signUp,
            signOut: signOut,
            getCurrentUser: getCurrentUser,
            locationTrackingService: locationTrackingService,
            apiClient: apiClient,
          )..add(CheckAuthStatus()),
    ),
    BlocProvider<MapBloc>(
      create:
          (_) => MapBloc(
            getUserLocation: getUserLocation,
            getNearbyBuses: getNearbyBuses,
            watchBusUpdates: watchBusUpdates,
          ),
    ),
    BlocProvider<BusSearchBloc>(
      create:
          (_) => BusSearchBloc(
            getNearbyBuses: getNearbyBuses,
            busRepository: busRepository,
          ),
    ),
    BlocProvider<TripSolutionBloc>(
      create:
          (_) => TripSolutionBloc(
            getUserLocation: getUserLocation,
            getNearbyBuses: getNearbyBuses,
            busRepository: busRepository,
          ),
    ),
    BlocProvider<FavoritesCubit>(
      create:
          (_) => FavoritesCubit(
            getFavoritesUseCase: getFavorites,
            addFavoriteUseCase: addFavorite,
            removeFavoriteUseCase: removeFavorite,
            isFavoriteUseCase: isFavorite,
          ),
    ),
    BlocProvider<RecentSearchesCubit>(
      create:
          (_) => RecentSearchesCubit(
            getRecentSearchesUseCase: getRecentSearches,
            addRecentSearchUseCase: addRecentSearch,
            removeRecentSearchUseCase: removeRecentSearch,
          ),
    ),
    BlocProvider<RiderTrackingBloc>(
      create:
          (_) => RiderTrackingBloc(
            locationService: locationTrackingService,
            storeRiderLocation: storeRiderLocation,
            userAssignmentRepository: userAssignmentRepository,
            routeRepository: routeRepository,
            apiClient: apiClient,
          ),
    ),
  ];
}
