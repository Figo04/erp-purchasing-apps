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

    // 🔥 MULTI-LAYER FOCUS STRATEGY

    // Layer 1: Immediate focus
    _focusNode.requestFocus();

    // Layer 2: Post-frame focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceFocus();
    });

    // Layer 3: Delayed focus (for desktop)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _forceFocus();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _forceFocus();
    });

    // Layer 4: Periodic re-focus
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isProcessing) {
        _forceFocus();
      }
      return mounted && !_isProcessing;
    });
  }

  void _forceFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      print('🎯 Focus requested - has focus: ${_focusNode.hasFocus}');
    }
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
      print('📦 Raw data length: ${rawData.length}');

      // 🔥 FIX: Handle format dengan @ (bukan JSON valid)
      String cleanedData = rawData.trim();

      // Cek apakah pakai format @ (dari bug QR generation)
      if (cleanedData.contains('@')) {
        print('⚠️  Detected @ format, converting to valid JSON...');
        cleanedData = cleanedData.replaceAll('@', '"');
      }

      print('🔄 Cleaned data: $cleanedData');

      // Parse JSON
      final Map<String, dynamic> jsonData = jsonDecode(cleanedData);
      print('✅ JSON parsed successfully');

      // Convert ke ShipmentQRData
      final qrData = ShipmentQRData.fromJson(jsonData);

      print('✅ QR data converted to model');
      print('   Shipment ID: ${qrData.shipmentId}');
      print('   Shipment: ${qrData.shipmentNumber}');
      print('   PO: ${qrData.poNumber}');
      print('   Items: ${qrData.items.length}');

      // Clear field sebelum navigate
      _scanController.clear();

      // 🔥 IMPORTANT: Tunggu sebentar biar UI stabil
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate ke form receipt
      if (!mounted) return;

      print('🚀 Navigating to form...');

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoodsReceiptFromQRScreen(qrData: qrData),
        ),
      );

      print('🔙 Returned from form with result: $result');

      // Refocus after return
      if (mounted) {
        _focusNode.requestFocus();
      }
    } catch (e, stackTrace) {
      print('❌ Error processing QR: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR Code: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _scanController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Delivery QR Code'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          print('🎯 Focus requested via tap');
        },
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (event) {
            // Re-focus kalau user pencet Space atau Enter
            if (event.isKeyPressed(LogicalKeyboardKey.space) ||
                event.isKeyPressed(LogicalKeyboardKey.enter)) {
              _focusNode.requestFocus();
              print('🎯 Focus requested via keyboard');
            }
          },
          child: Container( 
            color: Colors.green.shade50,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scanner Icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isProcessing
                            ? Icons.hourglass_bottom
                            : Icons.qr_code_scanner,
                        size: 120,
                        color: _isProcessing
                            ? Colors.orange
                            : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Status Text
                    Text(
                      _isProcessing
                          ? 'Processing...'
                          : _focusNode.hasFocus
                              ? '✓ Ready to Scan'
                              : '⚠ Click here to activate',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _isProcessing
                            ? Colors.orange
                            : _focusNode.hasFocus
                                ? Colors.green.shade900
                                : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isProcessing
                          ? 'Please wait...'
                          : 'Point your scanner at the QR code',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Scanner Input Field
                    // Hidden Scanner Input (tetap menerima input)
                    Opacity(
                      opacity: 0, // Tidak terlihat
                      child: SizedBox(
                        height: 0,
                        width: 0,
                        child: TextField(
                          controller: _scanController,
                          focusNode: _focusNode,
                          autofocus: true,
                          enabled: !_isProcessing,
                          onSubmitted: (value) {
                            final cleanValue = value.trim();
                            if (cleanValue.isNotEmpty &&
                                cleanValue != _lastScanned) {
                              _lastScanned = cleanValue;
                              _processScannedData(cleanValue);
                            }
                          },
                          onChanged: (value) {
                            if (value.endsWith('\n') || value.endsWith('\r')) {
                              final cleanValue = value.trim();
                              if (cleanValue.isNotEmpty &&
                                  cleanValue != _lastScanned) {
                                _lastScanned = cleanValue;
                                _processScannedData(cleanValue);
                              }
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Make sure the scanner is connected and this screen is active',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading Indicator
                    if (_isProcessing) ...[
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],

                    // Debug: Show last scanned (helpful for testing)
                    if (_lastScanned != null && !_isProcessing) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Last scan: ${_lastScanned!.substring(0, _lastScanned!.length > 30 ? 30 : _lastScanned!.length)}...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
