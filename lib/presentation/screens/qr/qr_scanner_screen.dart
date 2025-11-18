import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/shipment_provider.dart';
import 'package:erp_purchasing_apps/presentation/screens/qr/shipment_verification_screen.dart';
import 'package:erp_purchasing_apps/data/repositories/shipment_repository.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final TextEditingController _qrController = TextEditingController();
  final FocusNode _qrFocusNode = FocusNode();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus ke input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qrFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _qrController.dispose();
    _qrFocusNode.dispose();
    super.dispose();
  }

  // Handle QR scan from USB scanner
  Future<void> _handleScan(String qrData) async {
    if (_isProcessing || qrData.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Scan QR via backend (validates integrity)
      final shipment =
          await ref.read(shipmentDetailProvider.notifier).scanQR(qrData.trim());

      if (shipment == null) {
        // Error dari provider
        final error = ref.read(shipmentDetailProvider).error;
        setState(() {
          _errorMessage = error ?? 'Failed to scan QR code';
          _isProcessing = false;
        });
        return;
      }

      // navigate to verification screen
      if (mounted) {
        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ShipmentVerificationScreen(shipment: shipment),
            ));

        // Clear input
        _qrController.clear();
        _qrFocusNode.requestFocus();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Manual submit
  void _handleManualSubmit() {
    _handleScan(_qrController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Delivery QR Code'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Scanner
              Icon(
                _isProcessing ? Icons.hourglass_bottom : Icons.qr_code_scanner,
                size: 120,
                color: _errorMessage != null
                    ? Colors.red
                    : _isProcessing
                        ? Colors.orange
                        : Colors.blue,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _isProcessing ? 'Processing...' : 'Ready to Scan Delivery Note',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Instructions
              Text(
                _isProcessing
                    ? 'Please wait...'
                    : 'Use your barcode scanner to scan the QR code on the delivery note.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // QR Input Field (auto-submit ketika scanner selesai)
              TextField(
                controller: _qrController,
                focusNode: _qrFocusNode,
                enabled: !_isProcessing,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'QR Code Data',
                  hintText: 'Scan or paste QR code here...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: _qrController.text.isNotEmpty && !_isProcessing
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _qrController.clear();
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  _handleScan(value);
                },
                onChanged: (value) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Manual Submit Button
              ElevatedButton.icon(
                onPressed: _isProcessing || _qrController.text.trim().isEmpty
                    ? null
                    : _handleManualSubmit,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isProcessing ? 'Processing...' : 'Verify QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Troubleshooting',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Tips
              _buildTipCard(
                icon: Icons.usb,
                title: 'Scanner Not Working?',
                description:
                    'Make sure your USB barcode scanner is connected and this window is focused.',
              ),
              const SizedBox(height: 12),
              _buildTipCard(
                icon: Icons.content_paste,
                title: 'Manual Entry',
                description:
                    'You can also paste the QR code data manually if needed.',
              ),
              const SizedBox(height: 12),
              _buildTipCard(
                icon: Icons.refresh,
                title: 'invalid QR Code',
                description:
                    'Ask supplier to regenerate QR code from their portal.',
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
