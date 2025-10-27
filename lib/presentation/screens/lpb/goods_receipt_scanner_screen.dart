import 'dart:convert';
import 'package:erp_purchasing_apps/presentation/screens/qr/goods_receipt_from_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';

class GoodsReceiptScannerScreen extends ConsumerStatefulWidget {
  const GoodsReceiptScannerScreen({super.key});

  @override
  ConsumerState<GoodsReceiptScannerScreen> createState() =>
      _GoodsReceiptScannerScreenState();
}

class _GoodsReceiptScannerScreenState
    extends ConsumerState<GoodsReceiptScannerScreen> {
  final _scanController = TextEditingController();
  final _focusNode = FocusNode();
  String? _lastScanned;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus TextField untuk terima input scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _processScannedData(String rawData) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      print('📦 Raw scan data: $rawData');

      // Parse JSON dari scanner
      final Map<String, dynamic> jsonData = jsonDecode(rawData);

      // Convert ke ShipmentQRData
      final qrData = ShipmentQRData.fromJson(jsonData);

      print('✅ QR parsed successfully');
      print('   Shipment: ${qrData.shipmentNumber}');
      print('   PO: ${qrData.poNumber}');

      // Navigate ke form receipt
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoodsReceiptFromQRScreen(qrData: qrData),
          ),
        );

        // Clear & refocus after return
        _scanController.clear();
        _focusNode.requestFocus();
      }
    } catch (e) {
      print('❌ Error processing QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR Code: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _scanController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Delivery QR Code'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Scanner Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 120,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 48),

              // Instructions
              Text(
                _isProcessing
                    ? 'Processing...'
                    : 'Scan QR Code from Delivery Note',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Use your barcode scanner to scan the QR code',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Hidden TextField untuk terima input scanner
              Container(
                width: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.shade50,
                ),
                child: TextField(
                  controller: _scanController,
                  focusNode: _focusNode,
                  autofocus: true,
                  enabled: !_isProcessing,
                  decoration: InputDecoration(
                    hintText: 'Scanner input will appear here...',
                    prefixIcon:
                        Icon(Icons.scanner, color: Colors.green.shade700),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && value != _lastScanned) {
                      _lastScanned = value;
                      _processScannedData(value);
                    }
                  },
                  onChanged: (value) {
                    // Auto-submit when Enter pressed (some scanners auto-send Enter)
                    if (value.endsWith('\n') || value.endsWith('\r')) {
                      final cleanValue = value.trim();
                      if (cleanValue.isNotEmpty && cleanValue != _lastScanned) {
                        _lastScanned = cleanValue;
                        _processScannedData(cleanValue);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure the scanner is connected and this window is focused',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isProcessing) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
