import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class InvoiceService {
  // ─── Brand colours ───
  static const PdfColor brandGreen = PdfColor.fromInt(0xFF1DB98A);
  static const PdfColor brandDark  = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor lightGrey  = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor medGrey    = PdfColor.fromInt(0xFF9E9E9E);
  static const PdfColor white      = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor borderGrey = PdfColor.fromInt(0xFFE0E0E0);

  /// Generates a professional PDF invoice and returns the raw bytes.
  static Future<Uint8List> generateInvoicePdf({
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerEmail,
    DateTime? orderDate,
  }) async {
    final pdf = pw.Document();
    final DateTime date = orderDate ?? DateTime.now();
    final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final String invoiceNo = 'INV-${orderId.replaceAll('TXN-', '')}';

    // Load font for better rendering
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontSemiBold = await PdfGoogleFonts.interSemiBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ════════════════════════════════════════════
              // TOP GREEN HEADER BAR
              // ════════════════════════════════════════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                decoration: const pw.BoxDecoration(color: brandGreen),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TwinMart',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 28,
                            color: white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Tax Invoice / Receipt',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: PdfColor.fromInt(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 22,
                            color: white,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceNo,
                          style: pw.TextStyle(
                            font: fontSemiBold,
                            fontSize: 11,
                            color: PdfColor.fromInt(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ════════════════════════════════════════════
              // BODY CONTENT
              // ════════════════════════════════════════════
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // ── Order Info + Customer Info Row ──
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Bill To:', style: pw.TextStyle(font: fontBold, fontSize: 11, color: medGrey)),
                                pw.SizedBox(height: 6),
                                pw.Text(customerName, style: pw.TextStyle(font: fontBold, fontSize: 14, color: brandDark)),
                                pw.SizedBox(height: 2),
                                pw.Text(customerEmail, style: pw.TextStyle(font: font, fontSize: 10, color: medGrey)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                _infoRow('Invoice Date', formattedDate, font, fontSemiBold),
                                pw.SizedBox(height: 5),
                                _infoRow('Order ID', orderId, font, fontSemiBold),
                                pw.SizedBox(height: 5),
                                _infoRow('Payment', paymentMethod, font, fontSemiBold),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 25),

                      // ── Divider ──
                      pw.Container(height: 1, color: borderGrey),

                      pw.SizedBox(height: 20),

                      // ════════════════════════════════════
                      // ITEMS TABLE
                      // ════════════════════════════════════
                      // Table Header
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: const pw.BoxDecoration(
                          color: brandGreen,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(6),
                            topRight: pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(width: 40, child: pw.Text('#', style: pw.TextStyle(font: fontBold, fontSize: 10, color: white))),
                            pw.Expanded(flex: 5, child: pw.Text('Product', style: pw.TextStyle(font: fontBold, fontSize: 10, color: white))),
                            pw.SizedBox(width: 50, child: pw.Text('Qty', style: pw.TextStyle(font: fontBold, fontSize: 10, color: white), textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 80, child: pw.Text('Unit Price', style: pw.TextStyle(font: fontBold, fontSize: 10, color: white), textAlign: pw.TextAlign.right)),
                            pw.SizedBox(width: 80, child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 10, color: white), textAlign: pw.TextAlign.right)),
                          ],
                        ),
                      ),

                      // Table Rows
                      ...List.generate(items.length, (i) {
                        final item = items[i];
                        final String name = item['name'] ?? 'Item';
                        final int qty = (item['quantity'] ?? 1) as int;
                        final double price = (item['price'] ?? 0).toDouble();
                        final double lineTotal = price * qty;
                        final bool isEven = i % 2 == 0;

                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: pw.BoxDecoration(
                            color: isEven ? lightGrey : white,
                            border: pw.Border(bottom: pw.BorderSide(color: borderGrey, width: 0.5)),
                          ),
                          child: pw.Row(
                            children: [
                              pw.SizedBox(width: 40, child: pw.Text('${i + 1}', style: pw.TextStyle(font: font, fontSize: 10, color: medGrey))),
                              pw.Expanded(flex: 5, child: pw.Text(name, style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: brandDark))),
                              pw.SizedBox(width: 50, child: pw.Text('$qty', style: pw.TextStyle(font: font, fontSize: 10, color: brandDark), textAlign: pw.TextAlign.center)),
                              pw.SizedBox(width: 80, child: pw.Text('Rs.${price.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10, color: brandDark), textAlign: pw.TextAlign.right)),
                              pw.SizedBox(width: 80, child: pw.Text('Rs.${lineTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: brandDark), textAlign: pw.TextAlign.right)),
                            ],
                          ),
                        );
                      }),

                      // ── Subtotal / Total Section ──
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 1)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text('Subtotal: ', style: pw.TextStyle(font: font, fontSize: 10, color: medGrey)),
                                pw.SizedBox(width: 10),
                                pw.SizedBox(
                                  width: 80,
                                  child: pw.Text('Rs.${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: brandDark), textAlign: pw.TextAlign.right),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text('Delivery: ', style: pw.TextStyle(font: font, fontSize: 10, color: medGrey)),
                                pw.SizedBox(width: 10),
                                pw.SizedBox(
                                  width: 80,
                                  child: pw.Text('FREE', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: brandGreen), textAlign: pw.TextAlign.right),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Grand Total ──
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: const pw.BoxDecoration(
                          color: brandGreen,
                          borderRadius: pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(6),
                            bottomRight: pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GRAND TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 13, color: white, letterSpacing: 1)),
                            pw.Text('Rs.${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 15, color: white)),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 30),

                      // ── Payment Status Badge ──
                      pw.Center(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFE8F5E9),
                            borderRadius: pw.BorderRadius.circular(20),
                            border: pw.Border.all(color: PdfColor.fromInt(0xFF4CAF50), width: 0.5),
                          ),
                          child: pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF2E7D32),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      pw.Spacer(),

                      // ════════════════════════════════════
                      // FOOTER NOTE
                      // ════════════════════════════════════
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: lightGrey,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Terms & Notes', style: pw.TextStyle(font: fontBold, fontSize: 9, color: brandDark)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '• This is a computer-generated invoice and does not require a signature.\n'
                              '• For returns & refunds, please contact support@twinmart.com within 7 days.\n'
                              '• Thank you for shopping with TwinMart!',
                              style: pw.TextStyle(font: font, fontSize: 8, color: medGrey, lineSpacing: 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ════════════════════════════════════════════
              // BOTTOM GREEN FOOTER BAR
              // ════════════════════════════════════════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: const pw.BoxDecoration(color: brandGreen),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TwinMart — Smart Shopping Starts Here',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromInt(0xCCFFFFFF)),
                    ),
                    pw.Text(
                      'support@twinmart.com',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromInt(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Helper: builds a label-value info row (right-aligned)
  static pw.Widget _infoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(font: font, fontSize: 9, color: medGrey)),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 9, color: brandDark)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // PUBLIC API: Preview, Download, Share
  // ─────────────────────────────────────────────────────────

  /// Shows a native print / preview dialog (works on all platforms)
  static Future<void> previewInvoice(BuildContext context, {
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerEmail,
    DateTime? orderDate,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerEmail: customerEmail,
      orderDate: orderDate,
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  /// Saves the PDF to the device and returns the file path.
  /// On web, triggers a direct download instead.
  static Future<String?> saveInvoicePdf(BuildContext context, {
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerEmail,
    DateTime? orderDate,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerEmail: customerEmail,
      orderDate: orderDate,
    );

    if (kIsWeb) {
      // On web, use Printing to trigger a browser download
      await Printing.sharePdf(bytes: pdfBytes, filename: 'TwinMart_Invoice_$orderId.pdf');
      return null;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/TwinMart_Invoice_$orderId.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Shares the PDF invoice via the native share sheet.
  static Future<void> shareInvoice({
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerEmail,
    DateTime? orderDate,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      orderId: orderId,
      totalAmount: totalAmount,
      items: items,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerEmail: customerEmail,
      orderDate: orderDate,
    );

    await Printing.sharePdf(bytes: pdfBytes, filename: 'TwinMart_Invoice_$orderId.pdf');
  }
}
