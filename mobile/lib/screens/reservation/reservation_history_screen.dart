import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/parking_provider.dart';

class ReservationHistoryScreen extends ConsumerWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(reservationHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No history found')),
        data: (reservations) {
          if (reservations.isEmpty)
            return const Center(child: Text('No reservation history'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final r = reservations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Icon(r.isCompleted ? Icons.check : Icons.close,
                        color: r.isCompleted ? Colors.green : Colors.red),
                  ),
                  title: Text('Spot #${r.spotId} - ${r.plateNumber ?? "N/A"}'),
                  subtitle:
                      Text(DateFormat('MMM d, h:mm a').format(r.startTime)),
                  trailing: r.totalAmount != null
                      ? Text('\$${r.totalAmount!.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : Chip(
                          label: Text(r.status,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: r.isCompleted
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
