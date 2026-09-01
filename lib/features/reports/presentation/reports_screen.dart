import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../expenses/domain/expense_model.dart';
import '../../expenses/presentation/expense_providers.dart';
import '../../sales/domain/sale_model.dart';
import '../../sales/presentation/sales_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(todayStoreMetricsProvider);
    final salesAsync = ref.watch(salesStreamProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final expensesTotal = ref.watch(todayExpensesTotalProvider);
    
    final allSales = salesAsync.maybeWhen(data: (s) => s, orElse: () => <SaleModel>[]);
    final allExpenses = expensesAsync.maybeWhen(data: (e) => e, orElse: () => <ExpenseModel>[]);

    final netProfit = metrics.grossProfit - expensesTotal;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Export Report',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () => _showExportOptions(context, metrics, allSales, allExpenses, expensesTotal),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Daily Closing'),
            Tab(text: 'Seller Tracking'),
            Tab(text: 'Profit & Loss'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Daily Closing Tab
          _buildDailyClosingTab(context, metrics, allSales),

          // 2. Seller Tracking Tab (Who sold which product)
          _buildSellerTrackingTab(context, allSales),

          // 3. Profit & Loss Tab
          _buildProfitLossTab(context, metrics, expensesTotal, netProfit),
        ],
      ),
    );
  }

  Widget _buildDailyClosingTab(BuildContext context, StoreMetrics metrics, List<SaleModel> allSales) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DAILY CLOSING SUMMARY', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Text(Formatters.formatDate(DateTime.now()), style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
              const Divider(height: 20),
              _buildReportMetricRow('Total Sales Revenue', Formatters.currency(metrics.totalRevenue), isBold: true),
              const SizedBox(height: 6),
              _buildReportMetricRow('Cash Collected', Formatters.currency(metrics.cashTotal)),
              const SizedBox(height: 6),
              _buildReportMetricRow('UPI Received', Formatters.currency(metrics.upiTotal)),
              const SizedBox(height: 6),
              _buildReportMetricRow('Other Payments', Formatters.currency(metrics.otherTotal)),
              const SizedBox(height: 6),
              _buildReportMetricRow('Total Transactions', '${metrics.transactionCount} bills'),
              const SizedBox(height: 6),
              _buildReportMetricRow('Total Items Sold', Formatters.formatQuantity(metrics.totalItemsCount, '')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Seller Performance Breakdown', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppCard(
          child: metrics.sellerTotals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(child: Text('No sales recorded today', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight))),
                )
              : Column(
                  children: metrics.sellerTotals.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          Text(Formatters.currency(e.value), style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSellerTrackingTab(BuildContext context, List<SaleModel> allSales) {
    // Map seller -> Map<productName, quantity>
    final Map<String, Map<String, double>> sellerProductsMap = {};

    for (final sale in allSales) {
      if (!sale.isCompleted) continue;
      final seller = sale.sellerName ?? 'Seller';
      sellerProductsMap.putIfAbsent(seller, () => {});

      for (final item in sale.items) {
        final current = sellerProductsMap[seller]![item.productNameSnapshot] ?? 0.0;
        sellerProductsMap[seller]![item.productNameSnapshot] = current + item.quantity;
      }
    }

    if (sellerProductsMap.isEmpty) {
      return Center(
        child: Text('No seller product tracking data available', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: sellerProductsMap.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const Divider(height: 16),
                ...entry.value.entries.map((prod) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(prod.key, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          Formatters.formatQuantity(prod.value, ''),
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfitLossTab(
    BuildContext context,
    StoreMetrics metrics,
    double expensesTotal,
    double netProfit,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESTIMATED PROFIT & LOSS', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Divider(height: 20),
              _buildReportMetricRow('Sales Revenue (+)', Formatters.currency(metrics.totalRevenue)),
              const SizedBox(height: 6),
              _buildReportMetricRow('Cost of Goods Sold (-)', Formatters.currency(metrics.totalCost)),
              const SizedBox(height: 6),
              _buildReportMetricRow('Gross Profit (=)', Formatters.currency(metrics.grossProfit), isBold: true),
              const Divider(height: 16),
              _buildReportMetricRow('Shop Expenses (-)', Formatters.currency(expensesTotal)),
              const SizedBox(height: 6),
              _buildReportMetricRow('Estimated Net Profit (=)', Formatters.currency(netProfit), isBold: true, highlightColor: netProfit >= 0 ? AppColors.success : AppColors.error),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Note: Profit calculations are estimated based on recorded product cost purchase rates.',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildReportMetricRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: highlightColor ?? (isBold ? AppColors.primary : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }

  void _showExportOptions(
    BuildContext context,
    StoreMetrics metrics,
    List<SaleModel> allSales,
    List<ExpenseModel> allExpenses,
    double expensesTotal,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export Store Reports', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              title: const Text('Export Daily Closing Summary (PDF)'),
              subtitle: const Text('Print or share styled PDF document with clean currency'),
              onTap: () async {
                Navigator.pop(ctx);
                await _generatePdfReport(metrics, allSales, expensesTotal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_view, color: Color(0xFF107C41)), // Excel Green
              title: const Text('Export Full Store Audit (Excel .xlsx)'),
              subtitle: const Text('Multi-sheet workbook: Summary, Sales, Items & Expenses'),
              onTap: () async {
                Navigator.pop(ctx);
                await _exportExcelReport(metrics, allSales, allExpenses, expensesTotal);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdfReport(StoreMetrics metrics, List<SaleModel> allSales, double expensesTotal) async {
    pw.Font? regularFont;
    pw.Font? boldFont;

    // 1. First try bundled Unicode font asset (always available offline)
    try {
      final regData = await rootBundle.load('assets/fonts/Arial-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Arial-Bold.ttf');
      regularFont = pw.Font.ttf(regData);
      boldFont = pw.Font.ttf(boldData);
    } catch (_) {
      // 2. Fallback to dynamic Google Fonts
      try {
        regularFont = await PdfGoogleFonts.robotoRegular();
        boldFont = await PdfGoogleFonts.robotoBold();
      } catch (e) {
        debugPrint('PdfGoogleFonts load fallback: $e');
      }
    }

    final hasUnicodeFont = regularFont != null;
    final theme = pw.ThemeData.withFont(
      base: regularFont ?? pw.Font.helvetica(),
      bold: boldFont ?? pw.Font.helveticaBold(),
    );

    String fmtCur(num? amount) => hasUnicodeFont
        ? Formatters.currency(amount)
        : (amount == null ? 'Rs. 0.00' : 'Rs. ${amount.toStringAsFixed(2)}');

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Nammalvar Natural Store', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
              pw.Text('Daily Store Closing & Audit Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.Text('Date: ${Formatters.formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Text('Summary Figures:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Bullet(text: 'Total Revenue: ${fmtCur(metrics.totalRevenue)}'),
              pw.Bullet(text: 'Cash Collected: ${fmtCur(metrics.cashTotal)}'),
              pw.Bullet(text: 'UPI Received: ${fmtCur(metrics.upiTotal)}'),
              pw.Bullet(text: 'Other Payments: ${fmtCur(metrics.otherTotal)}'),
              pw.Bullet(text: 'Transaction Bills: ${metrics.transactionCount}'),
              pw.Bullet(text: 'Total Items Sold: ${Formatters.formatQuantity(metrics.totalItemsCount, "")}'),
              pw.Bullet(text: 'Estimated Gross Profit: ${fmtCur(metrics.grossProfit)}'),
              pw.Bullet(text: 'Daily Expenses: ${fmtCur(expensesTotal)}'),
              pw.Bullet(text: 'Net Margin: ${fmtCur(metrics.grossProfit - expensesTotal)}'),
              pw.SizedBox(height: 16),
              pw.Text('Seller Breakdown:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (metrics.sellerTotals.isEmpty)
                pw.Text('No sales recorded today', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600))
              else
                ...metrics.sellerTotals.entries.map((e) => pw.Bullet(text: '${e.key}: ${fmtCur(e.value)}')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportExcelReport(
    StoreMetrics metrics,
    List<SaleModel> allSales,
    List<ExpenseModel> allExpenses,
    double expensesTotal,
  ) async {
    try {
      final excel = Excel.createExcel();

      // Sheet 1: Summary
      excel.rename('Sheet1', 'Summary');
      final summarySheet = excel['Summary'];

      summarySheet.appendRow([TextCellValue('Nammalvar Natural Store - Daily Store Closing & Audit')]);
      summarySheet.appendRow([TextCellValue('Report Date'), TextCellValue(Formatters.formatDate(DateTime.now()))]);
      summarySheet.appendRow([TextCellValue('')]);
      summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
      summarySheet.appendRow([TextCellValue('Total Revenue'), DoubleCellValue(metrics.totalRevenue)]);
      summarySheet.appendRow([TextCellValue('Cash Collected'), DoubleCellValue(metrics.cashTotal)]);
      summarySheet.appendRow([TextCellValue('UPI Received'), DoubleCellValue(metrics.upiTotal)]);
      summarySheet.appendRow([TextCellValue('Other Payments'), DoubleCellValue(metrics.otherTotal)]);
      summarySheet.appendRow([TextCellValue('Transaction Bills'), IntCellValue(metrics.transactionCount)]);
      summarySheet.appendRow([TextCellValue('Total Items Sold'), DoubleCellValue(metrics.totalItemsCount)]);
      summarySheet.appendRow([TextCellValue('Estimated Gross Profit'), DoubleCellValue(metrics.grossProfit)]);
      summarySheet.appendRow([TextCellValue('Daily Expenses'), DoubleCellValue(expensesTotal)]);
      summarySheet.appendRow([TextCellValue('Net Margin'), DoubleCellValue(metrics.grossProfit - expensesTotal)]);

      // Sheet 2: Sales
      final salesSheet = excel['Sales'];
      salesSheet.appendRow([
        TextCellValue('Sale Number'),
        TextCellValue('Date/Time'),
        TextCellValue('Seller'),
        TextCellValue('Payment Method'),
        TextCellValue('Status'),
        TextCellValue('Total Amount'),
      ]);

      for (final s in allSales) {
        salesSheet.appendRow([
          IntCellValue(s.saleNumber),
          TextCellValue(Formatters.formatDateTime(s.saleDate)),
          TextCellValue(s.sellerName ?? 'Seller'),
          TextCellValue(s.paymentMethod.toUpperCase()),
          TextCellValue(s.status.toUpperCase()),
          DoubleCellValue(s.totalAmount),
        ]);
      }

      // Sheet 3: Sale Items
      final itemsSheet = excel['Sale Items'];
      itemsSheet.appendRow([
        TextCellValue('Sale Number'),
        TextCellValue('Product'),
        TextCellValue('Quantity'),
        TextCellValue('Unit Price'),
        TextCellValue('Total'),
      ]);

      for (final s in allSales) {
        for (final item in s.items) {
          itemsSheet.appendRow([
            IntCellValue(s.saleNumber),
            TextCellValue(item.productNameSnapshot),
            DoubleCellValue(item.quantity),
            DoubleCellValue(item.rateSnapshot),
            DoubleCellValue(item.amount),
          ]);
        }
      }

      // Sheet 4: Expenses
      final expensesSheet = excel['Expenses'];
      expensesSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Amount'),
        TextCellValue('Added By'),
      ]);

      for (final e in allExpenses) {
        expensesSheet.appendRow([
          TextCellValue(Formatters.formatDate(e.expenseDate)),
          TextCellValue(e.category.toUpperCase()),
          TextCellValue(e.description ?? '-'),
          DoubleCellValue(e.amount),
          TextCellValue(e.createdByName ?? 'Admin'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = 'Daily_Store_Audit_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        await Printing.sharePdf(
          bytes: Uint8List.fromList(fileBytes),
          filename: fileName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel Export Generated ($fileName)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate Excel: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

