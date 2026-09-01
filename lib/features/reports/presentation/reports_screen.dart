import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/seller_switcher_modal.dart';
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
    final expensesTotal = ref.watch(todayExpensesTotalProvider);
    final allSales = salesAsync.maybeWhen(data: (s) => s, orElse: () => <SaleModel>[]);

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
            tooltip: 'Switch User',
            icon: const Icon(Icons.switch_account_outlined, color: AppColors.primary),
            onPressed: () => SellerSwitcherModal.show(context),
          ),
          IconButton(
            tooltip: 'Export Report',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () => _showExportOptions(context, metrics, allSales, expensesTotal),
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
              subtitle: const Text('Print or share styled PDF document'),
              onTap: () async {
                Navigator.pop(ctx);
                await _generatePdfReport(metrics, allSales, expensesTotal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.success),
              title: const Text('Export Sales Ledger (CSV)'),
              subtitle: const Text('Spreadsheet format for Excel/Sheets'),
              onTap: () {
                Navigator.pop(ctx);
                _exportCsvReport(allSales);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdfReport(StoreMetrics metrics, List<SaleModel> allSales, double expensesTotal) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Nammalvar Iyerkai Angadi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('Daily Store Closing & Audit Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.Text('Date: ${Formatters.formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Text('Summary Figures:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Total Revenue: ${Formatters.pdfCurrency(metrics.totalRevenue)}'),
              pw.Bullet(text: 'Cash Collected: ${Formatters.pdfCurrency(metrics.cashTotal)}'),
              pw.Bullet(text: 'UPI Received: ${Formatters.pdfCurrency(metrics.upiTotal)}'),
              pw.Bullet(text: 'Transaction Bills: ${metrics.transactionCount}'),
              pw.Bullet(text: 'Total Items Sold: ${Formatters.formatQuantity(metrics.totalItemsCount, "")}'),
              pw.Bullet(text: 'Estimated Gross Profit: ${Formatters.pdfCurrency(metrics.grossProfit)}'),
              pw.Bullet(text: 'Daily Expenses: ${Formatters.pdfCurrency(expensesTotal)}'),
              pw.Bullet(text: 'Net Margin: ${Formatters.pdfCurrency(metrics.grossProfit - expensesTotal)}'),
              pw.SizedBox(height: 16),
              pw.Text('Seller Breakdown:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ...metrics.sellerTotals.entries.map((e) => pw.Bullet(text: '${e.key}: ${Formatters.pdfCurrency(e.value)}')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _exportCsvReport(List<SaleModel> allSales) {
    final List<List<dynamic>> rows = [];
    rows.add(['Sale #', 'Date', 'Seller', 'Payment Method', 'Status', 'Total Amount']);

    for (final s in allSales) {
      rows.add([
        s.saleNumber,
        s.saleDate.toIso8601String(),
        s.sellerName ?? 'Seller',
        s.paymentMethod,
        s.status,
        s.totalAmount,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV Export Generated (${allSales.length} rows)'),
        backgroundColor: AppColors.success,
      ),
    );
    debugPrint('Exported CSV:\n$csvString');
  }
}
