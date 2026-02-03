import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings/app_settings_bloc.dart';
import '../bloc/settings/app_settings_event.dart';
import '../bloc/settings/app_settings_state.dart';
import '../widgets/common/ui_components.dart';

class EnhancedSettingsPage extends StatelessWidget {
  const EnhancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, state) {
          if (state is AppSettingsLoading) {
            return const LoadingStateWidget(message: 'Loading settings...');
          }

          if (state is AppSettingsError) {
            return ErrorStateWidget(
              message: 'Failed to load settings',
              details: state.message,
              onRetry: () {
                context.read<AppSettingsBloc>().add(const LoadAppSettings());
              },
            );
          }

          if (state is! AppSettingsLoaded) {
            return const EmptyStateWidget(
              icon: Icons.settings_outlined,
              title: 'No Settings Available',
            );
          }

          return ListView(
            children: [
              _buildAppearanceSection(context, state),
              const Divider(height: 1),
              _buildNotificationsSection(context, state),
              const Divider(height: 1),
              _buildMapSection(context, state),
              const Divider(height: 1),
              _buildPreferencesSection(context, state),
              const Divider(height: 1),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    AppSettingsLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Appearance',
          subtitle: 'Customize how the app looks',
        ),
        CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [_buildThemeSelector(context, state)]),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, AppSettingsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme Mode', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode_outlined,
                isSelected: state.themeMode == ThemeMode.light,
                onTap: () {
                  context.read<AppSettingsBloc>().add(
                    const UpdateThemeMode(ThemeMode.light),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                isSelected: state.themeMode == ThemeMode.dark,
                onTap: () {
                  context.read<AppSettingsBloc>().add(
                    const UpdateThemeMode(ThemeMode.dark),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                label: 'System',
                icon: Icons.settings_suggest_outlined,
                isSelected: state.themeMode == ThemeMode.system,
                onTap: () {
                  context.read<AppSettingsBloc>().add(
                    const UpdateThemeMode(ThemeMode.system),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(
    BuildContext context,
    AppSettingsLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
        ),
        CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive bus arrival notifications'),
                value: state.notificationsEnabled,
                onChanged: (value) {
                  context.read<AppSettingsBloc>().add(
                    ToggleNotifications(value),
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (state.notificationsEnabled) ...[
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sound for notifications'),
                  value: state.soundEnabled,
                  onChanged: (value) {
                    context.read<AppSettingsBloc>().add(ToggleSound(value));
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate for notifications'),
                  value: state.vibrationEnabled,
                  onChanged: (value) {
                    context.read<AppSettingsBloc>().add(ToggleVibration(value));
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context, AppSettingsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Map', subtitle: 'Customize map display'),
        CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: const Text('Map Style'),
                subtitle: Text(state.mapStyle.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  _showMapStylePicker(context, state.mapStyle);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Traffic Layer'),
                subtitle: const Text('Show traffic conditions'),
                value: state.showTrafficLayer,
                onChanged: (value) {
                  context.read<AppSettingsBloc>().add(
                    ToggleTrafficLayer(value),
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    AppSettingsLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Preferences',
          subtitle: 'App behavior settings',
        ),
        CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: const Text('Auto Refresh Interval'),
                subtitle: Text('${state.autoRefreshInterval} seconds'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  _showRefreshIntervalPicker(
                    context,
                    state.autoRefreshInterval,
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Keep Screen On'),
                subtitle: const Text('Prevent screen from dimming'),
                value: state.keepScreenOn,
                onChanged: (value) {
                  context.read<AppSettingsBloc>().add(
                    ToggleKeepScreenOn(value),
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About', subtitle: 'App information'),
        CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: const Text('0.1.0'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  // Navigate to terms page
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  // Navigate to privacy page
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              _showResetConfirmation(context);
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showMapStylePicker(BuildContext context, String currentStyle) {
    showModalBottomSheet(
      context: context,
      builder: (bottomContext) {
        final styles = ['standard', 'satellite', 'terrain', 'hybrid'];
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Map Style',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...styles.map((style) {
                return ListTile(
                  title: Text(style.toUpperCase()),
                  leading: Radio<String>(
                    value: style,
                    groupValue: currentStyle,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AppSettingsBloc>().add(
                          UpdateMapStyle(value),
                        );
                        Navigator.pop(bottomContext);
                      }
                    },
                  ),
                  onTap: () {
                    context.read<AppSettingsBloc>().add(UpdateMapStyle(style));
                    Navigator.pop(bottomContext);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showRefreshIntervalPicker(BuildContext context, int currentInterval) {
    showModalBottomSheet(
      context: context,
      builder: (bottomContext) {
        final intervals = [10, 15, 30, 45, 60];
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Refresh Interval',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...intervals.map((interval) {
                return ListTile(
                  title: Text('$interval seconds'),
                  leading: Radio<int>(
                    value: interval,
                    groupValue: currentInterval,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AppSettingsBloc>().add(
                          UpdateAutoRefreshInterval(value),
                        );
                        Navigator.pop(bottomContext);
                      }
                    },
                  ),
                  onTap: () {
                    context.read<AppSettingsBloc>().add(
                      UpdateAutoRefreshInterval(interval),
                    );
                    Navigator.pop(bottomContext);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to their default values?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AppSettingsBloc>().add(const ResetSettings());
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primaryColor.withOpacity(0.1) : theme.cardColor,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? primaryColor : theme.iconTheme.color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? primaryColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
