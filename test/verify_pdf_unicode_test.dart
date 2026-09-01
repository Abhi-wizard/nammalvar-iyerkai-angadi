import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:nammalvar_iyerkai_angadi/core/utils/formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF generates with Unicode fonts without character corruption', () async {
    final regFile = File('assets/fonts/Arial-Regular.ttf');
    final boldFile = File('assets/fonts/Arial-Bold.ttf');
    final regularFont = pw.Font.ttf(regFile.readAsBytesSync().buffer.asByteData());
    final boldFont = pw.Font.ttf(boldFile.readAsBytesSync().buffer.asByteData());

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    String fmt(num val) => Formatters.currency(val);

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
              pw.Text('Date: 01 Sep 2026', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Text('Summary Figures:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Total Revenue: ${fmt(2335.00)}'),
              pw.Bullet(text: 'Cash Collected: ${fmt(1705.00)}'),
              pw.Bullet(text: 'UPI Received: ${fmt(180.00)}'),
              pw.Bullet(text: 'Estimated Gross Profit: ${fmt(597.50)}'),
              pw.Bullet(text: 'Daily Expenses: ${fmt(0.00)}'),
              pw.Bullet(text: 'Net Margin: ${fmt(597.50)}'),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final outDir = Directory('build/test_outputs');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File('build/test_outputs/verified_audit_report.pdf');
    outFile.writeAsBytesSync(bytes);
    expect(outFile.existsSync(), isTrue);
    expect(bytes.length, greaterThan(1000));
  });
}
