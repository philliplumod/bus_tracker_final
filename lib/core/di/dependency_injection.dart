import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/bus_remote_data_source.dart';
import '../../data/datasources/location_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bus_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bus_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_nearby_buses.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/watch_bus_updates.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_event.dart';
import '../../presentation/bloc/map/map_bloc.dart';
import '../../presentation/bloc/bus_search/bus_search_bloc.dart';
import '../../presentation/bloc/trip_solution/trip_solution_bloc.dart';
import '../../theme/theme_cubit.dart';

class DependencyInjection {
  // Data Sources
  static late final AuthRemoteDataSource authRemoteDataSource;
  static late final BusRemoteDataSource busRemoteDataSource;
  static late final LocationLocalDataSource locationLocalDataSource;

  // Repositories
  static late final AuthRepository authRepository;
  static late final BusRepository busRepository;
  static late final LocationRepository locationRepository;

  // Use Cases
  static late final SignIn signIn;
  static late final SignUp signUp;
  static late final SignOut signOut;
  static late final GetCurrentUser getCurrentUser;
  static late final GetUserLocation getUserLocation;
  static late final GetNearbyBuses getNearbyBuses;
  static late final WatchBusUpdates watchBusUpdates;

  static Future<void> init() async {
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Initialize data sources
    authRemoteDataSource = AuthRemoteDataSourceImpl(
      client: http.Client(),
      prefs: prefs,
    );
    busRemoteDataSource = BusRemoteDataSourceImpl(
      busRef: FirebaseDatabase.instance.ref(),
    );
    locationLocalDataSource = LocationLocalDataSourceImpl();

    // Initialize repositories
    authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);
    busRepository = BusRepositoryImpl(remoteDataSource: busRemoteDataSource);
    locationRepository = LocationRepositoryImpl(
      localDataSource: locationLocalDataSource,
    );

    // Initialize use cases
    signIn = SignIn(authRepository);
    signUp = SignUp(authRepository);
    signOut = SignOut(authRepository);
    getCurrentUser = GetCurrentUser(authRepository);
    getUserLocation = GetUserLocation(locationRepository);
    getNearbyBuses = GetNearbyBuses(busRepository);
    watchBusUpdates = WatchBusUpdates(busRepository);
  }

  static List<BlocProvider> get providers => [
    BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
    BlocProvider<AuthBloc>(
      create:
          (_) => AuthBloc(
            signIn: signIn,
            signUp: signUp,
            signOut: signOut,
            getCurrentUser: getCurrentUser,
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
      create: (_) => BusSearchBloc(getNearbyBuses: getNearbyBuses),
    ),
    BlocProvider<TripSolutionBloc>(
      create:
          (_) => TripSolutionBloc(
            getUserLocation: getUserLocation,
            getNearbyBuses: getNearbyBuses,
          ),
    ),
  ];
}
