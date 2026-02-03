/// Export file for easy access to all UI/UX improvements
///
/// Usage:
/// ```dart
/// import 'package:bus_tracker/improvements.dart';
/// ```

// UI Components
export 'presentation/widgets/common/ui_components.dart';

// Settings
export 'presentation/bloc/settings/app_settings_bloc.dart';
export 'presentation/bloc/settings/app_settings_event.dart';
export 'presentation/bloc/settings/app_settings_state.dart';
export 'presentation/pages/enhanced_settings_page.dart';

// Core Services
export 'core/services/hive_service.dart';
export 'core/services/app_lifecycle_manager.dart';

// Repositories
export 'data/repositories/app_settings_repository.dart';

// Utils
export 'core/utils/page_transitions.dart';

// Theme
export 'theme/app_theme.dart';
