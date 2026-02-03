import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../theme/theme_cubit.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<AuthBloc>().add(SignOutRequested());
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Not authenticated'));
          }

          final user = state.user;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile Header
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.role.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Information Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        icon: Icons.email,
                        label: 'Email',
                        value: user.email,
                      ),
                      if (user.role == UserRole.rider && user.busName != null)
                        _buildInfoCard(
                          context,
                          icon: Icons.directions_bus,
                          label: 'Bus Name',
                          value: user.busName!,
                        ),
                      if (user.role == UserRole.rider &&
                          user.assignedRoute != null)
                        _buildInfoCard(
                          context,
                          icon: Icons.route,
                          label: 'Assigned Route',
                          value: user.assignedRoute!,
                        ),
                      _buildInfoCard(
                        context,
                        icon: Icons.badge,
                        label: 'User ID',
                        value: user.id,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Settings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.brightness_6,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: const Text('Dark Mode'),
                          trailing: Switch(
                            value:
                                Theme.of(context).brightness == Brightness.dark,
                            onChanged: (value) {
                              context.read<ThemeCubit>().toggleTheme();
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Out Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSignOut(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
