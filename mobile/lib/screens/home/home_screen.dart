import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../services/websocket_service.dart';
import '../../config/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketProvider).connect();
      ref.read(wsConnectedProvider.notifier).state = true;
    });
  }

  @override
  void dispose() {
    ref.read(webSocketProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(parkingStatsProvider);
    final reservationsAsync = ref.watch(reservationsProvider);
    final wsConnected = ref.watch(wsConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartPS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: wsConnected ? 'Connected to server' : 'Disconnected',
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: wsConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref.invalidate(parkingStatsProvider);
                      ref.invalidate(reservationsProvider);
                      ref.invalidate(spotsProvider);
                      ref.invalidate(availableSpotsProvider);
                    }),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parkingStatsProvider);
          ref.invalidate(reservationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${authState.user?.fullName ?? 'User'}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Find your perfect parking spot',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 24),
              statsAsync.when(
                loading: () => const _StatsSkeleton(),
                error: (e, _) => Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                            'Unable to load parking stats. Pull down to refresh.',
                            style: TextStyle(color: Colors.grey.shade600)))),
                data: (stats) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                                label: 'Available',
                                value: '${stats.available}',
                                color: AppTheme.secondaryColor,
                                icon: Icons.check_circle),
                            _StatItem(
                                label: 'Occupied',
                                value: '${stats.occupied}',
                                color: AppTheme.errorColor,
                                icon: Icons.car_rental),
                            _StatItem(
                                label: 'Reserved',
                                value: '${stats.reserved}',
                                color: AppTheme.warningColor,
                                icon: Icons.bookmark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRoundedClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: stats.occupancyRate,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              stats.occupancyRate > 0.8
                                  ? AppTheme.errorColor
                                  : stats.occupancyRate > 0.5
                                      ? AppTheme.warningColor
                                      : AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${stats.totalSpots} total spots',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Quick Actions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _QuickActionCard(
                          icon: Icons.qr_code_scanner,
                          label: 'Scan Plate',
                          color: AppTheme.primaryColor,
                          onTap: () => context.go('/scan'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _QuickActionCard(
                          icon: Icons.map,
                          label: 'View Map',
                          color: AppTheme.secondaryColor,
                          onTap: () => context.go('/map'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _QuickActionCard(
                          icon: Icons.bookmark_add,
                          label: 'Reserve',
                          color: AppTheme.warningColor,
                          onTap: () => context.go('/reservations'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _QuickActionCard(
                          icon: Icons.history,
                          label: 'History',
                          color: Colors.purple,
                          onTap: () => context.go('/history'))),
                ],
              ),
              const SizedBox(height: 24),
              Text('Active Reservations',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              reservationsAsync.when(
                loading: () => const Card(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()))),
                error: (e, _) => Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Unable to load reservations',
                            style: TextStyle(color: Colors.grey.shade600)))),
                data: (reservations) {
                  final active = reservations.where((r) => r.isActive).toList();
                  if (active.isEmpty) {
                    return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.bookmark_border,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('No active reservations',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => context.go('/reservations'),
                                child: const Text('Make a reservation'),
                              ),
                            ],
                          )),
                    );
                  }
                  return Column(
                      children: active
                          .map((r) => _ReservationCard(reservation: r))
                          .toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey)),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final dynamic reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(Icons.bookmark, color: AppTheme.primaryColor)),
        title: Text(
            'Spot ${reservation.spotId} - ${reservation.plateNumber ?? "N/A"}'),
        subtitle: Text(
            'Until ${reservation.endTime.hour}:${reservation.endTime.minute.toString().padLeft(2, '0')}'),
        trailing: Chip(
            label: Text(reservation.status),
            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1)),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
              3,
              (_) => Column(
                    children: [
                      Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(14))),
                      const SizedBox(height: 8),
                      Container(
                          width: 30,
                          height: 20,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 4),
                      Container(
                          width: 50,
                          height: 12,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4))),
                    ],
                  )),
        ),
      ),
    );
  }
}

class ClipRoundedClipRRect extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget child;
  const ClipRoundedClipRRect(
      {super.key, required this.borderRadius, required this.child});

  @override
  Widget build(BuildContext context) =>
      ClipRRect(borderRadius: borderRadius, child: child);
}
