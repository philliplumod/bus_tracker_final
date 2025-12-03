import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/bus_remote_data_source.dart';
import '../../data/datasources/location_local_data_source.dart';
import '../../data/repositories/bus_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/bus_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_nearby_buses.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/usecases/watch_bus_updates.dart';
import '../../presentation/bloc/map_bloc.dart';
import '../../theme/theme_cubit.dart';

class DependencyInjection {
  // Data Sources
  static late final BusRemoteDataSource busRemoteDataSource;
  static late final LocationLocalDataSource locationLocalDataSource;

  // Repositories
  static late final BusRepository busRepository;
  static late final LocationRepository locationRepository;

  // Use Cases
  static late final GetUserLocation getUserLocation;
  static late final GetNearbyBuses getNearbyBuses;
  static late final WatchBusUpdates watchBusUpdates;

  static void init() {
    // Initialize data sources
    busRemoteDataSource = BusRemoteDataSourceImpl(
      busRef: FirebaseDatabase.instance.ref(),
    );
    locationLocalDataSource = LocationLocalDataSourceImpl();

    // Initialize repositories
    busRepository = BusRepositoryImpl(remoteDataSource: busRemoteDataSource);
    locationRepository = LocationRepositoryImpl(
      localDataSource: locationLocalDataSource,
    );

    // Initialize use cases
    getUserLocation = GetUserLocation(locationRepository);
    getNearbyBuses = GetNearbyBuses(busRepository);
    watchBusUpdates = WatchBusUpdates(busRepository);
  }

  static List<BlocProvider> get providers => [
    BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
    BlocProvider<MapBloc>(
      create:
          (_) => MapBloc(
            getUserLocation: getUserLocation,
            getNearbyBuses: getNearbyBuses,
            watchBusUpdates: watchBusUpdates,
          ),
    ),
  ];
}
