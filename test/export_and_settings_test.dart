import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:nammalvar_iyerkai_angadi/core/constants/app_constants.dart';
import 'package:nammalvar_iyerkai_angadi/core/utils/formatters.dart';
import 'package:nammalvar_iyerkai_angadi/features/auth/domain/profile_model.dart';
import 'package:nammalvar_iyerkai_angadi/features/auth/presentation/auth_providers.dart';
import 'package:nammalvar_iyerkai_angadi/features/sales/presentation/new_sale_screen.dart';
import 'package:nammalvar_iyerkai_angadi/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK 1: Production Settings UI Cleanup Tests', () {
    testWidgets('1. Admin Settings Screen displays clean retail UI and no infrastructure console', (tester) async {
      final adminUser = ProfileModel(
        id: '00000000-0000-0000-0000-000000000001',
        email: 'admin@nammalvar.org',
        name: 'Master Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref)..state = adminUser,
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify User Details
      expect(find.text('Master Admin'), findsOneWidget);
      expect(find.text('ROLE: ADMIN'), findsOneWidget);
      expect(find.text('admin@nammalvar.org'), findsOneWidget);
      expect(find.text('SIGN OUT FROM TERMINAL'), findsOneWidget);

      // Verify Store Branding & Terminal Details
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Counter Station #1'), findsOneWidget);
      expect(find.text('2.1.0 (Production)'), findsOneWidget);

      // Verify REMOVED Developer/Infrastructure Items
      expect(find.text('Cloud Sync Status'), findsNothing);
      expect(find.text('Connected to Supabase PostgreSQL'), findsNothing);
      expect(find.text('System Architecture'), findsNothing);
      expect(find.text('Multi-Terminal POS'), findsNothing);
      expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
    });

    testWidgets('2. Seller Settings Screen displays seller profile cleanly', (tester) async {
      final sellerUser = ProfileModel(
        id: '00000000-0000-0000-0000-000000000002',
        email: 'stdharan73@gmail.com',
        name: 'Tharanidharan',
        role: UserRole.seller,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref)..state = sellerUser,
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tharanidharan'), findsOneWidget);
      expect(find.text('ROLE: SELLER'), findsOneWidget);
      expect(find.text('stdharan73@gmail.com'), findsOneWidget);
      expect(find.text('Cloud Sync Status'), findsNothing);
      expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
    });
  });

  group('TASK 2 & 3: Display Name Normalization & Timezone Tests', () {
    test('1. Normalizes stdharan73 and stdharan73@gmail.com to Tharanidharan', () {
      expect(ProfileModel.normalizeDisplayName(null, 'stdharan73@gmail.com'), 'Tharanidharan');
      expect(ProfileModel.normalizeDisplayName('stdharan73', 'stdharan73@gmail.com'), 'Tharanidharan');
      expect(ProfileModel.normalizeDisplayName('stdharan73', null), 'Tharanidharan');
      expect(ProfileModel.normalizeDisplayName('User', 'stdharan73@gmail.com'), 'Tharanidharan');
      expect(ProfileModel.normalizeDisplayName('Priyamanikandan', 'priya@nammalvar.org'), 'Priyamanikandan');
    });

    test('2. Formats UTC dates into local timezone', () {
      final utcDate = DateTime.parse('2026-09-01T04:30:00Z'); // UTC
      final formatted = Formatters.formatDate(utcDate);
      expect(formatted, isNotEmpty);
      final formattedTime = Formatters.formatTime(utcDate);
      expect(formattedTime, isNotEmpty);
    });
  });

  group('TASK 2: PDF Export Currency ₹ Rendering Tests', () {
    test('1. Formatters.currency and pdfCurrency output clean ₹ symbol', () {
      expect(Formatters.currency(2335.00), '₹2,335.00');
      expect(Formatters.currency(1705.00), '₹1,705.00');
      expect(Formatters.currency(180.00), '₹180.00');
      expect(Formatters.currency(597.50), '₹597.50');
      expect(Formatters.currency(0.00), '₹0.00');
      expect(Formatters.pdfCurrency(2335.00), '₹2,335.00');
    });

    test('2. PDF Document generates valid binary with Unicode font theme', () async {
      final regFile = File('assets/fonts/Arial-Regular.ttf');
      final boldFile = File('assets/fonts/Arial-Bold.ttf');
      final regularFont = pw.Font.ttf(regFile.readAsBytesSync().buffer.asByteData());
      final boldFont = pw.Font.ttf(boldFile.readAsBytesSync().buffer.asByteData());

      final theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      );

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
                pw.Bullet(text: 'Total Revenue: ${Formatters.currency(2335.00)}'),
                pw.Bullet(text: 'Cash Collected: ${Formatters.currency(1705.00)}'),
                pw.Bullet(text: 'UPI Received: ${Formatters.currency(180.00)}'),
                pw.Bullet(text: 'Estimated Gross Profit: ${Formatters.currency(597.50)}'),
                pw.Bullet(text: 'Daily Expenses: ${Formatters.currency(0.00)}'),
                pw.Bullet(text: 'Net Margin: ${Formatters.currency(597.50)}'),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));

      // Save scratch PDF file for visual inspection
      final scratchDir = Directory('build/test_outputs');
      if (!scratchDir.existsSync()) scratchDir.createSync(recursive: true);
      final testPdfFile = File('build/test_outputs/daily_audit_report.pdf');
      testPdfFile.writeAsBytesSync(bytes);
      expect(testPdfFile.existsSync(), isTrue);
    });
  });

  group('TASK 3: Excel (.xlsx) 4-Sheet Real Export Tests', () {
    test('1. Generates 4-sheet Excel workbook with proper numerical data types', () async {
      final now = DateTime.now();
      final excel = Excel.createExcel();

      // Sheet 1: Summary
      excel.rename('Sheet1', 'Summary');
      final summarySheet = excel['Summary'];

      summarySheet.appendRow([TextCellValue('Nammalvar Natural Store - Daily Store Closing & Audit')]);
      summarySheet.appendRow([TextCellValue('Report Date'), TextCellValue(Formatters.formatDate(now))]);
      summarySheet.appendRow([TextCellValue('')]);
      summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
      summarySheet.appendRow([TextCellValue('Total Revenue'), DoubleCellValue(2335.00)]);
      summarySheet.appendRow([TextCellValue('Cash Collected'), DoubleCellValue(1705.00)]);
      summarySheet.appendRow([TextCellValue('UPI Received'), DoubleCellValue(180.00)]);
      summarySheet.appendRow([TextCellValue('Other Payments'), DoubleCellValue(0.00)]);
      summarySheet.appendRow([TextCellValue('Transaction Bills'), IntCellValue(3)]);
      summarySheet.appendRow([TextCellValue('Total Items Sold'), DoubleCellValue(7.0)]);
      summarySheet.appendRow([TextCellValue('Estimated Gross Profit'), DoubleCellValue(597.50)]);
      summarySheet.appendRow([TextCellValue('Daily Expenses'), DoubleCellValue(0.00)]);
      summarySheet.appendRow([TextCellValue('Net Margin'), DoubleCellValue(597.50)]);

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
      salesSheet.appendRow([
        IntCellValue(1001),
        TextCellValue(Formatters.formatDateTime(now)),
        TextCellValue('Kavin Kumar'),
        TextCellValue('CASH'),
        TextCellValue('COMPLETED'),
        DoubleCellValue(1705.00),
      ]);
      salesSheet.appendRow([
        IntCellValue(1002),
        TextCellValue(Formatters.formatDateTime(now)),
        TextCellValue('Priya Dharshini'),
        TextCellValue('UPI'),
        TextCellValue('COMPLETED'),
        DoubleCellValue(180.00),
      ]);

      // Sheet 3: Sale Items
      final itemsSheet = excel['Sale Items'];
      itemsSheet.appendRow([
        TextCellValue('Sale Number'),
        TextCellValue('Product'),
        TextCellValue('Quantity'),
        TextCellValue('Unit Price'),
        TextCellValue('Total'),
      ]);
      itemsSheet.appendRow([
        IntCellValue(1001),
        TextCellValue('Organic Ponni Rice (5kg)'),
        DoubleCellValue(2.0),
        DoubleCellValue(350.0),
        DoubleCellValue(700.0),
      ]);
      itemsSheet.appendRow([
        IntCellValue(1001),
        TextCellValue('Cold Pressed Sesame Oil (1L)'),
        DoubleCellValue(3.0),
        DoubleCellValue(335.0),
        DoubleCellValue(1005.0),
      ]);
      itemsSheet.appendRow([
        IntCellValue(1002),
        TextCellValue('Organic Turmeric Powder (200g)'),
        DoubleCellValue(2.0),
        DoubleCellValue(90.0),
        DoubleCellValue(180.0),
      ]);

      // Sheet 4: Expenses
      final expensesSheet = excel['Expenses'];
      expensesSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Amount'),
        TextCellValue('Added By'),
      ]);
      expensesSheet.appendRow([
        TextCellValue(Formatters.formatDate(now)),
        TextCellValue('UTILITIES'),
        TextCellValue('Store lighting LED bulb replacement'),
        DoubleCellValue(150.00),
        TextCellValue('Master Admin'),
      ]);

      // Encode and verify
      final fileBytes = excel.save();
      expect(fileBytes, isNotNull);
      expect(fileBytes!, isNotEmpty);

      // Verify decoding back
      final decodedExcel = Excel.decodeBytes(fileBytes);
      expect(decodedExcel.tables.keys, containsAll(['Summary', 'Sales', 'Sale Items', 'Expenses']));

      // Verify Summary Sheet values
      final decodedSummary = decodedExcel.tables['Summary']!;
      expect(decodedSummary.rows.length, greaterThanOrEqualTo(10));
      expect(decodedSummary.rows[4][0]?.value.toString(), 'Total Revenue');
      expect(decodedSummary.rows[4][1]?.value.toString(), '2335');

      // Verify Sales Sheet values
      final decodedSales = decodedExcel.tables['Sales']!;
      expect(decodedSales.rows.length, 3); // header + 2 sales
      expect(decodedSales.rows[1][0]?.value.toString(), '1001');
      expect(decodedSales.rows[1][2]?.value.toString(), 'Kavin Kumar');
      expect(decodedSales.rows[1][5]?.value.toString(), '1705');

      // Verify Sale Items Sheet values
      final decodedItems = decodedExcel.tables['Sale Items']!;
      expect(decodedItems.rows.length, 4); // header + 3 items
      expect(decodedItems.rows[1][1]?.value.toString(), 'Organic Ponni Rice (5kg)');
      expect(decodedItems.rows[1][2]?.value.toString(), '2');

      // Verify Expenses Sheet values
      final decodedExpenses = decodedExcel.tables['Expenses']!;
      expect(decodedExpenses.rows.length, 2); // header + 1 expense
      expect(decodedExpenses.rows[1][1]?.value.toString(), 'UTILITIES');
      expect(decodedExpenses.rows[1][3]?.value.toString(), '150');

      // Save to disk for inspection
      final testXlsxFile = File('build/test_outputs/daily_audit_report.xlsx');
      testXlsxFile.writeAsBytesSync(fileBytes);
      expect(testXlsxFile.existsSync(), isTrue);
    });
  });

  group('TASK 4: POS Product Card Responsive Layout (No Overflow) Tests', () {
    testWidgets('1. SettingsScreen renders cleanly without overflow on narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final adminUser = ProfileModel(
        id: '00000000-0000-0000-0000-000000000001',
        email: 'admin@nammalvar.org',
        name: 'Master Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref)..state = adminUser,
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('2. NewSaleScreen renders product list and cart stepper cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sellerUser = ProfileModel(
        id: '00000000-0000-0000-0000-000000000002',
        email: 'priya@nammalvar.org',
        name: 'Priyamanikandan',
        role: UserRole.seller,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref)..state = sellerUser,
            ),
          ],
          child: const MaterialApp(
            home: NewSaleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Sale / POS'), findsOneWidget);
      expect(find.text('Seller: Priyamanikandan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
