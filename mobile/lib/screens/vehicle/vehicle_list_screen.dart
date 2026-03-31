import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getVehicles();
      setState(() => _vehicles = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load vehicles')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addVehicle() async {
    final plateController = TextEditingController();
    final typeController = TextEditingController();
    final colorController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: plateController,
                decoration: const InputDecoration(
                    labelText: 'Plate Number',
                    prefixIcon: Icon(Icons.directions_car))),
            const SizedBox(height: 12),
            TextField(
                controller: typeController,
                decoration: const InputDecoration(
                    labelText: 'Type (sedan, suv, truck)')),
            const SizedBox(height: 12),
            TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );

    if (result != true) return;

    try {
      final api = ref.read(apiServiceProvider);
      await api.addVehicle(
        plateNumber: plateController.text.toUpperCase(),
        vehicleType: typeController.text.isEmpty ? null : typeController.text,
        color: colorController.text.isEmpty ? null : colorController.text,
      );
      await _loadVehicles();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vehicle added'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteVehicle(int id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteVehicle(id);
      await _loadVehicles();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vehicle removed')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No vehicles added yet',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                          onPressed: _addVehicle,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Vehicle')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final v = _vehicles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.directions_car,
                                  color: AppTheme.primaryColor)),
                          title: Text(v['plate_number'] ?? 'Unknown'),
                          subtitle: Text([v['vehicle_type'], v['color']]
                              .where((e) => e != null)
                              .join(' • ')),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteVehicle(v['id'])),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _vehicles.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addVehicle, child: const Icon(Icons.add))
          : null,
    );
  }
}
