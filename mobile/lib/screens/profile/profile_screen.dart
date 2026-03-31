import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../vehicle/vehicle_list_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('This feature is coming soon.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SmartPS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Parking System v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                'AI-powered license plate recognition and parking management.'),
            SizedBox(height: 8),
            Text('Built with FastAPI, PaddleOCR, and Flutter.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Getting Started',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  '1. Register an account\n2. Add your vehicle in My Vehicles\n3. Scan a plate or reserve a spot\n4. View your reservation history'),
              SizedBox(height: 16),
              Text('Troubleshooting',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  '• Ensure you\'re connected to the server\n• Green dot = connected, Red dot = disconnected\n• Pull down to refresh any screen'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (authState.user?.fullName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(authState.user?.fullName ?? 'User',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(authState.user?.email ?? '',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  _ProfileTile(
                      icon: Icons.history,
                      title: 'Reservation History',
                      onTap: () => context.go('/history')),
                  const Divider(height: 1),
                  _ProfileTile(
                      icon: Icons.directions_car,
                      title: 'My Vehicles',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VehicleListScreen()));
                      }),
                  const Divider(height: 1),
                  _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () => _showComingSoon(context, 'Notifications')),
                  const Divider(height: 1),
                  _ProfileTile(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () => _showComingSoon(context, 'Settings')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _ProfileTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () => _showHelp(context)),
                  const Divider(height: 1),
                  _ProfileTile(
                      icon: Icons.info_outline,
                      title: 'About SmartPS',
                      onTap: () => _showAbout(context)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label:
                    const Text('Sign Out', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
