import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/parking_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({super.key});

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  int? _selectedSpotId;
  String? _plateNumber;
  DateTime _startTime = DateTime.now().add(const Duration(minutes: 15));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _isLoading = false;
  double? _hourlyRate;

  @override
  void initState() {
    super.initState();
    _loadHourlyRate();
  }

  Future<void> _loadHourlyRate() async {
    try {
      final api = ref.read(apiServiceProvider);
      final lots = await api.getParkingLots();
      if (lots.isNotEmpty) {
        setState(
            () => _hourlyRate = (lots[0]['hourly_rate'] as num?)?.toDouble());
      }
    } catch (_) {}
  }

  Future<void> _pickTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
    );
    if (time == null) return;

    setState(() {
      final dt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startTime = dt;
        if (_endTime.isBefore(_startTime))
          _endTime = _startTime.add(const Duration(hours: 1));
      } else {
        _endTime = dt;
      }
    });
  }

  Future<void> _createReservation() async {
    if (_selectedSpotId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a spot')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.createReservation(
        spotId: _selectedSpotId!,
        plateNumber: _plateNumber,
        startTime: _startTime,
        endTime: _endTime,
      );
      ref.invalidate(reservationsProvider);
      ref.invalidate(parkingStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reservation created!'),
            backgroundColor: Colors.green));
        setState(() {
          _selectedSpotId = null;
          _plateNumber = null;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(availableSpotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reserve a Spot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plate Number
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'License Plate (optional)',
                  prefixIcon: Icon(Icons.directions_car)),
              onChanged: (v) =>
                  _plateNumber = v.isNotEmpty ? v.toUpperCase() : null,
            ),
            const SizedBox(height: 16),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    label: 'Start',
                    dateTime: _startTime,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeCard(
                    label: 'End',
                    dateTime: _endTime,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Spot Selection
            Text('Select a Spot',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            spotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text(e.toString(), style: const TextStyle(color: Colors.red)),
              data: (spots) {
                if (spots.isEmpty)
                  return const Card(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No available spots'))));
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8),
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot = spots[index];
                    final selected = spot.id == _selectedSpotId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSpotId = spot.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : AppTheme.secondaryColor),
                        ),
                        child: Center(
                          child: Text(
                            spot.spotNumber,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.secondaryColor),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Duration & Cost summary
            if (_selectedSpotId != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Spot', value: '#$_selectedSpotId'),
                      _SummaryRow(
                          label: 'Duration',
                          value:
                              '${_endTime.difference(_startTime).inHours}h ${_endTime.difference(_startTime).inMinutes % 60}m'),
                      _SummaryRow(
                          label: 'From',
                          value:
                              DateFormat('MMM d, h:mm a').format(_startTime)),
                      _SummaryRow(
                          label: 'Until',
                          value: DateFormat('MMM d, h:mm a').format(_endTime)),
                      if (_hourlyRate != null) ...[
                        const Divider(),
                        _SummaryRow(
                            label: 'Rate',
                            value: '\$${_hourlyRate!.toStringAsFixed(2)}/hr'),
                        _SummaryRow(
                          label: 'Estimated Cost',
                          value:
                              '\$${(_hourlyRate! * (_endTime.difference(_startTime).inHours + (_endTime.difference(_startTime).inMinutes % 60 > 0 ? 1 : 0))).toStringAsFixed(2)}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _isLoading || _selectedSpotId == null
                  ? null
                  : _createReservation,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Reservation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;
  const _TimeCard(
      {required this.label, required this.dateTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(DateFormat('MMM d').format(dateTime),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('h:mm a').format(dateTime),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}
