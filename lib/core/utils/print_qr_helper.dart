import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';
import 'dart:ui' as ui;

class PrintQRHelper {
  /// Print QR Code with shipment details
  static Future<void> printShipmentQR(
    BuildContext context,
    ShipmentModel shipment,
  ) async {
    try {
      // Generate QR image
      final qrDataRaw = shipment.qrCodeData ?? '{}';
      final qrSafeString = qrDataRaw.replaceAll('"', '@');
      final qrImageData = await _generateQRImage(qrSafeString);

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Title
                  pw.Text(
                    'DELIVERY NOTE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // QR Code
                  if (qrImageData != null)
                    pw.Container(
                      width: 200,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 2),
                      ),
                      child: pw.Image(pw.MemoryImage(qrImageData)),
                    ),
                  pw.SizedBox(height: 30),

                  // Shipment Details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            'Shipment Number', shipment.shipmentNumber),
                        _buildDetailRow('PO Number', shipment.poNumber ?? '-'),
                        _buildDetailRow(
                            'Delivery Note', shipment.deliveryNoteNumber),
                        _buildDetailRow(
                          'Shipment Date',
                          '${shipment.shipmentDate.day}/${shipment.shipmentDate.month}/${shipment.shipmentDate.year}',
                        ),
                        if (shipment.notes != null &&
                            shipment.notes!.isNotEmpty)
                          _buildDetailRow('Notes', shipment.notes!),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 30),

                  // Items
                  if (shipment.items != null && shipment.items!.isNotEmpty) ...[
                    pw.Text(
                      'ITEMS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            _buildTableCell('Item Name', isHeader: true),
                            _buildTableCell('Quantity', isHeader: true),
                            _buildTableCell('Unit', isHeader: true),
                          ],
                        ),
                        // Rows
                        ...shipment.items!.map((item) {
                          return pw.TableRow(
                            children: [
                              _buildTableCell(item.itemName),
                              _buildTableCell(item.quantityShipped.toString()),
                              _buildTableCell(item.unit),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],

                  pw.SizedBox(height: 40),

                  // Footer
                  pw.Text(
                    'Scan QR code on warehouse arrival',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Show print preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generate QR code as image bytes
  static Future<Uint8List?> _generateQRImage(String data) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        final picData = await painter.toImageData(
          300,
          format: ui.ImageByteFormat.png,
        );
        return picData?.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Error generating QR image: $e');
    }
    return null;
  }

  /// Build detail row for PDF
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Download QR as image (alternative to print)
  static Future<void> downloadQRImage(
    BuildContext context,
    ShipmentModel shipment,
  ) async {
    try {
      final qrImageData = await _generateQRImage(shipment.qrCodeData ?? '');

      if (qrImageData == null) {
        throw Exception('Failed to generate QR image');
      }

      // Share or save image
      await Printing.sharePdf(
        bytes: qrImageData,
        filename: '${shipment.shipmentNumber}_QR.png',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
