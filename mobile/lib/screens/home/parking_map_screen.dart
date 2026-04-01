import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/parking_provider.dart';
import '../../config/theme.dart';

class ParkingMapScreen extends ConsumerWidget {
  const ParkingMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(spotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Parking Map')),
      body: spotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Unable to load parking map. Pull down to refresh.')),
        data: (spots) {
          if (spots.isEmpty) {
            return const Center(child: Text('No parking spots configured'));
          }

          final sections = <String, List<dynamic>>{};
          for (final spot in spots) {
            final key = spot.section ?? 'A';
            sections.putIfAbsent(key, () => []).add(spot);
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(spotsProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _LegendItem(
                          color: AppTheme.secondaryColor, label: 'Available'),
                      _LegendItem(
                          color: AppTheme.errorColor, label: 'Occupied'),
                      _LegendItem(
                          color: AppTheme.warningColor, label: 'Reserved'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Spots grid by section
                  ...sections.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Section ${entry.key}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: entry.value.length,
                            itemBuilder: (context, index) {
                              final spot = entry.value[index];
                              return _SpotCell(spot: spot);
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpotCell extends StatelessWidget {
  final dynamic spot;
  const _SpotCell({required this.spot});

  Color get _color {
    if (spot.isAvailable) return AppTheme.secondaryColor;
    if (spot.isOccupied) return AppTheme.errorColor;
    return AppTheme.warningColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSpotDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(spot.spotNumber,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12, color: _color)),
            Icon(spot.isAvailable ? Icons.check : Icons.car_rental,
                size: 16, color: _color),
          ],
        ),
      ),
    );
  }

  void _showSpotDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spot ${spot.spotNumber}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _DetailRow(
                label: 'Status',
                value: spot.status.toUpperCase(),
                color: _color),
            _DetailRow(label: 'Type', value: spot.spotType),
            _DetailRow(label: 'Floor', value: '${spot.floor}'),
            if (spot.section != null)
              _DetailRow(label: 'Section', value: spot.section),
            const SizedBox(height: 16),
            if (spot.isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/reservations');
                  },
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Reserve This Spot'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _DetailRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
