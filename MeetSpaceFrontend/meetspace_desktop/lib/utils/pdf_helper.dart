import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/revenue.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

class PdfHelper {
  static Future<pw.Document> generateRevenuePdf(
    List<RevenueResponse> data, {
    DateTime? from,
    DateTime? to,
  }) async {
    final font = await pw.Font.ttf(
      await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
    );

    final boldFont = await pw.Font.ttf(
      await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
    );

    final pdf = pw.Document();

    final filtered = data.where((e) {
      if (from != null && e.date.isBefore(from)) return false;
      if (to != null && e.date.isAfter(to)) return false;
      return true;
    }).toList();

    final total = filtered.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "MEETSPACE",
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 18,
                  letterSpacing: 3,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                "Revenue Report",
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 22,
                  color: PdfColor.fromHex("#A56E09"), 
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          if (from != null || to != null)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                "Period: "
                "${from != null ? "${from.day}.${from.month}.${from.year}" : "-"}"
                " - "
                "${to != null ? "${to.day}.${to.month}.${to.year}" : "-"}",
                style: pw.TextStyle(font: font),
              ),
            ),

          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#A56E09").shade(0.1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Total revenue",
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  "BAM ${total.toStringAsFixed(0)}",
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: PdfColor.fromHex("#A56E09"),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          pw.Table.fromTextArray(
            headers: ["Amount", "User", "Location", "Payment", "Date"],

            headerStyle: pw.TextStyle(
              font: boldFont,
              color: PdfColors.white,
            ),

            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFA56E09),
            ),

            cellStyle: pw.TextStyle(
              font: font,
              fontSize: 10,
            ),

            cellPadding: const pw.EdgeInsets.all(8),

            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),

            data: filtered.map((e) {
              return [
                "BAM ${e.amount.toStringAsFixed(0)}",
                e.user,
                e.location,
                e.paymentMethod,
                "${e.date.day}.${e.date.month}.${e.date.year}",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generated on ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

static Future<pw.Document> generateUsersPdf(
  List<UserResponse> users,
) async {
  final font = await pw.Font.ttf(
    await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
  );

  final boldFont = await pw.Font.ttf(
    await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
  );

  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(40),

      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "MEETSPACE",
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 18,
                letterSpacing: 3,
                color: PdfColors.grey600,
              ),
            ),

            pw.Text(
              "Users Report",
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 22,
                color: PdfColor.fromHex("#A56E09"),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 25),

        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex("#A56E09").shade(0.1),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Total users",
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                ),
              ),

              pw.Text(
                "${users.length}",
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 18,
                  color: PdfColor.fromHex("#A56E09"),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 14),

        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                "Active users",
                "${users.where((e) => e.isActive).length}",
                boldFont,
              ),
            ),

            pw.SizedBox(width: 10),

            pw.Expanded(
              child: _buildStatCard(
                "Admins",
                "${users.where((e) => e.roleName == AppRoles.admin).length}",
                boldFont,
              ),
            ),

            pw.SizedBox(width: 10),

            pw.Expanded(
              child: _buildStatCard(
                "Regular users",
                "${users.where((e) => e.roleName != AppRoles.admin).length}",
                boldFont,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 25),

        pw.Table.fromTextArray(
          headers: [
            "Name",
            "Username",
            "Email",
            "Phone",
            "Role",
            "Status",
            "Created",
          ],

          headerStyle: pw.TextStyle(
            font: boldFont,
            color: PdfColors.white,
            fontSize: 10,
          ),

          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFA56E09),
          ),

          cellStyle: pw.TextStyle(
            font: font,
            fontSize: 9,
          ),

          cellPadding: const pw.EdgeInsets.all(6),

          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.grey300,
              ),
            ),
          ),

          data: users.map((u) {
            return [
              "${u.firstName ?? ""} ${u.lastName ?? ""}",

              u.username,

              u.email,

              u.phoneNumber ?? "-",

              u.roleName,

              u.isActive ? "Active" : "Inactive",

              u.createdAt != null
                  ? "${u.createdAt!.day}.${u.createdAt!.month}.${u.createdAt!.year}"
                  : "-",
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 30),

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            "Generated on ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    ),
  );

  return pdf;
}

static pw.Widget _buildStatCard(
  String title,
  String value,
  pw.Font boldFont,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),

        pw.SizedBox(height: 6),

        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 18,
            color: PdfColor.fromHex("#A56E09"),
          ),
        ),
      ],
    ),
  );
}
}