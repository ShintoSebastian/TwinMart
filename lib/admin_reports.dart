import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ManageReportsPage extends StatelessWidget {
  const ManageReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);
    const Color twinGreen = Color(0xFF10B981);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect if we are in Mobile preview
        bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isMobile 
            ? AppBar(
                title: const Text("Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: bgDark,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              )
            : null,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 32.0, vertical: isMobile ? 16.0 : 32.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile)
                    const Text("Reports", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 32),
                  
                  // --- TOP BAR: FILTER & EXPORT ---
                  isMobile 
                    ? Column(
                        children: [
                          _buildFilterDropdown(),
                          const SizedBox(height: 16),
                          _buildExportButton(context, twinGreen, true),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFilterDropdown(),
                          _buildExportButton(context, twinGreen, false),
                        ],
                      ),
                  
                  const SizedBox(height: 32),
                  
                  // --- STAT CARDS GRID ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                    builder: (context, snapshot) {
                      double totalRevenue = 0;
                      int transactions = 0;
                      double avgOrderValue = 0;

                      if (snapshot.hasData) {
                        transactions = snapshot.data!.docs.length;
                        for (var doc in snapshot.data!.docs) {
                          totalRevenue += (doc['totalAmount'] ?? 0).toDouble();
                        }
                        if (transactions > 0) {
                          avgOrderValue = totalRevenue / transactions;
                        }
                      }

                      return isMobile 
                        ? Column(
                            children: [
                              _buildStatCard("Total Revenue", "₹${totalRevenue.toInt()}", Icons.attach_money, Colors.green.withOpacity(0.1), Colors.green),
                              const SizedBox(height: 16),
                              _buildStatCard("Transactions", transactions.toString(), Icons.receipt_long, Colors.blue.withOpacity(0.1), Colors.blue),
                              const SizedBox(height: 16),
                              _buildStatCard("Avg. Order Value", "₹${avgOrderValue.toInt()}", Icons.trending_up, Colors.purple.withOpacity(0.1), Colors.purple),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildStatCard("Total Revenue", "₹${totalRevenue.toInt()}", Icons.attach_money, Colors.green.withOpacity(0.1), Colors.green)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard("Transactions", transactions.toString(), Icons.receipt_long, Colors.blue.withOpacity(0.1), Colors.blue)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard("Avg. Order Value", "₹${avgOrderValue.toInt()}", Icons.trending_up, Colors.purple.withOpacity(0.1), Colors.purple)),
                            ],
                          );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // --- UI ATOM COMPONENTS ---

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: "Last 7 days",
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: ["Last 7 days", "Last 30 days", "Last 90 days", "Last year"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {},
        ),
      ),
    );
  }

  Future<void> _generateOrdersPDF(BuildContext context) async {
    try {
      // 1. Fetch Orders 
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No transactions to export")),
          );
        }
        return;
      }

      final doc = pw.Document();

      // Table data rows
      final List<List<String>> tableData = [
        ["Order ID", "Date", "Items", "Amount", "Method", "Type"]
      ];

      for (var order in snapshot.docs) {
        final data = order.data() as Map<String, dynamic>;
        final DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
        final String dateStr = date != null ? DateFormat('dd/MM/yy').format(date) : "N/A";
        
        tableData.add([
          order.id.substring(0, 8),
          dateStr,
          (data['itemsCount'] ?? 0).toString(),
          "Rs.${(data['totalAmount'] ?? 0).toInt()}",
          data['paymentMethod'] ?? "N/A",
          data['type'] ?? "Offline"
        ]);
      }

      // Add Page to PDF
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("TwinMart Reports", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text(DateFormat('dd MMMM yyyy').format(DateTime.now()), style: pw.TextStyle(color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
                data: tableData,
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Text("Generated by TwinMart Admin Panel", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              )
            ];
          },
        ),
      );

      // 3. Share or Preview PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'TwinMart_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      debugPrint("🔥 PDF Export Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF Generation failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildExportButton(BuildContext context, Color twinGreen, bool isFullWidth) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB98A), Color(0xFF10B981)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _generateOrdersPDF(context),
        icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 18),
        label: const Text("Export PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 14, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}