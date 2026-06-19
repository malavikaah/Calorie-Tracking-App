import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_state.dart';
import '../models/user_profile.dart';

class PdfExportService {
  static Future<Uint8List> generateReportBytes(UserProfile? profile, Map<String, dynamic> insights) async {
    final pdf = await _buildPdfDocument(profile, insights);
    return pdf.save();
  }

  static Future<void> generateAndPrintReport(UserProfile? profile, Map<String, dynamic> insights) async {
    final pdf = await _buildPdfDocument(profile, insights);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'CaloTrack_Health_Report_${profile?.name ?? "User"}.pdf',
    );
  }

  static Future<pw.Document> _buildPdfDocument(UserProfile? profile, Map<String, dynamic> insights) async {
    final pdf = pw.Document();
    final summary = insights;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('CaloTrack Nutritional Health Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              
              pw.Text('User Profile', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Name: ${profile?.name ?? "User"}'),
              pw.Text('Age: ${profile?.age ?? "-"}'),
              pw.Text('Health Condition: ${profile?.healthCondition.toUpperCase() ?? "NONE"}'),
              pw.Text('Report Date: ${DateTime.now().toString().split(' ')[0]}'),
              pw.SizedBox(height: 20),
              
              pw.Text('Weekly Analytics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('Avg Daily Calories', '${summary['avgDailyCalories'] ?? 0} kcal'),
                  _buildMetric('BMI Trend', summary['bmiTrend'] ?? 'N/A'),
                  _buildMetric('Stability', summary['lastSevenDaysStability'] ?? 'Stable'),
                ]
              ),
              pw.SizedBox(height: 30),
              
              if (profile?.healthCondition != 'none') ...[
                pw.Text('Health Alerts', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                pw.Divider(color: PdfColors.red),
                pw.Text(
                  'Monitoring: ${profile?.healthCondition.toUpperCase() ?? "NONE"}',
                  style: pw.TextStyle(color: PdfColors.red900, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'AI insights suggest focusing on specific macros to better manage your condition.',
                  style: const pw.TextStyle(color: PdfColors.red700),
                ),
              ],
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Generated automatically by CaloTrack',
                  style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildMetric(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ]
    );
  }
}
