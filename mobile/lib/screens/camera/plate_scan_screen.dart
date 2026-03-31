import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../providers/parking_provider.dart';

class PlateScanScreen extends ConsumerStatefulWidget {
  const PlateScanScreen({super.key});

  @override
  ConsumerState<PlateScanScreen> createState() => _PlateScanScreenState();
}

class _PlateScanScreenState extends ConsumerState<PlateScanScreen> {
  final _picker = ImagePicker();
  bool _isProcessing = false;
  String? _detectedPlate;
  double? _confidence;
  String? _error;

  Future<void> _captureAndScan(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _detectedPlate = null;
      _confidence = null;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.recognizePlate(image.path);

      final plates = result['plates'] as List;
      if (plates.isNotEmpty) {
        final best = plates.first;
        setState(() {
          _detectedPlate = best['plate_number'];
          _confidence = (best['confidence'] as num).toDouble();
        });
      } else {
        setState(() => _error = 'No license plate detected. Try again.');
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _recordEntry() async {
    if (_detectedPlate == null) return;
    setState(() => _isProcessing = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.recordEntry(_detectedPlate!);
      if (mounted) {
        ref.invalidate(parkingStatsProvider);
        _showResultDialog('Entry Recorded',
            'Plate: $_detectedPlate\nSpot: ${result['spot_number'] ?? 'Auto-assigned'}');
      }
    } catch (e) {
      setState(() => _error = 'Entry failed: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _recordExit() async {
    if (_detectedPlate == null) return;
    setState(() => _isProcessing = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.recordExit(_detectedPlate!);
      if (mounted) {
        ref.invalidate(parkingStatsProvider);
        _showResultDialog('Exit Recorded',
            'Plate: $_detectedPlate\nDuration: ${result['duration_minutes'] ?? 0} min\nAmount: \$${result['amount'] ?? 0}');
      }
    } catch (e) {
      setState(() => _error = 'Exit failed: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan License Plate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.camera_alt,
                      size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('Capture a license plate',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Position the plate clearly in the camera frame',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _captureAndScan(ImageSource.camera),
                          icon: const Icon(Icons.camera),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _captureAndScan(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Processing indicator
            if (_isProcessing) const Center(child: CircularProgressIndicator()),

            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)))
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Detected plate
            if (_detectedPlate != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 48),
                    const SizedBox(height: 12),
                    const Text('Plate Detected',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.green)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Text(_detectedPlate!,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _recordEntry,
                            icon: const Icon(Icons.login),
                            label: const Text('Record Entry'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _recordExit,
                            icon: const Icon(Icons.logout),
                            label: const Text('Record Exit'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: () => setState(() => _detectedPlate = null),
                        child: const Text('Scan Another')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
