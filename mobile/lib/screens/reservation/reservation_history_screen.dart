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
      appBar: AppBar(
        title: const Text('Reservation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reservationHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child:
                Text(e.toString(), style: const TextStyle(color: Colors.red))),
        data: (reservations) {
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No reservation history',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(reservationHistoryProvider.future),
            child: ListView.builder(
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
                          : r.isCancelled
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      child: Icon(
                        r.isCompleted
                            ? Icons.check
                            : r.isCancelled
                                ? Icons.close
                                : Icons.pending,
                        color: r.isCompleted
                            ? Colors.green
                            : r.isCancelled
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                    title:
                        Text('Spot #${r.spotId} - ${r.plateNumber ?? "N/A"}'),
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
                                : r.isCancelled
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
