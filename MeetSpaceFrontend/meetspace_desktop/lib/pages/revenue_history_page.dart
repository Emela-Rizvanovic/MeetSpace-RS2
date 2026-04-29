import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../models/revenue.dart';
import '../services/revenue_service.dart';
import '../utils/pdf_helper.dart';
import 'package:open_file/open_file.dart';

class RevenueHistoryPage extends StatefulWidget {
  const RevenueHistoryPage({super.key});

  @override
  State<RevenueHistoryPage> createState() => _RevenueHistoryPageState();
}

class _RevenueHistoryPageState extends State<RevenueHistoryPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<RevenueResponse> _data = [];
  List<RevenueResponse> _filtered = [];

  bool _loading = true;

  String _search = "";
  String _sort = "Date ↓";

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final service = RevenueService(auth.api);

    final all = await service.getAll();

    setState(() {
      _data = all;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    List<RevenueResponse> temp = [..._data];

    /// SEARCH
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();

      temp = temp.where((r) {
        return r.user.toLowerCase().contains(query) ||
            r.location.toLowerCase().contains(query) ||
            r.paymentMethod.toLowerCase().contains(query);
      }).toList();
    }

    /// DATE FILTER
    if (_fromDate != null) {
      temp = temp.where((r) => !r.date.isBefore(_fromDate!)).toList();
    }

    if (_toDate != null) {
      temp = temp.where((r) => !r.date.isAfter(_toDate!)).toList();
    }

    /// SORT
    switch (_sort) {
      case "Date ↓":
        temp.sort((a, b) => b.date.compareTo(a.date));
        break;
      case "Date ↑":
        temp.sort((a, b) => a.date.compareTo(b.date));
        break;
      case "Amount ↓":
        temp.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case "Amount ↑":
        temp.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    _filtered = temp;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _applyFilters();
      });
    }
  }

Future<void> _generatePdf() async {
  try {
    final pdf = await PdfHelper.generateRevenuePdf(
      _filtered,
      from: _fromDate,
      to: _toDate,
    );

    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/revenue_report.pdf");

    await file.writeAsBytes(bytes);

    /// 🔥 OTVORI FAJL
    await OpenFile.open(file.path);

  } catch (e) {
    debugPrint("PDF error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + ACTIONS
            Row(
              children: [
                const Text(
                  "Revenue history",
                  style: TextStyle(
                    color: brandOrange,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                /// DATE FILTER
                _dateButton("From", _fromDate, () => _pickDate(true)),
const SizedBox(width: 8),
_dateButton("To", _toDate, () => _pickDate(false)),
                const SizedBox(width: 8),


                /// SORT
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: "Date ↓", child: Text("Date ↓")),
                      DropdownMenuItem(value: "Date ↑", child: Text("Date ↑")),
                      DropdownMenuItem(value: "Amount ↓", child: Text("Amount ↓")),
                      DropdownMenuItem(value: "Amount ↑", child: Text("Amount ↑")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sort = value!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// SEARCH
            TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: "Search transactions",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// LIST
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandOrange),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final r = _filtered[index];

                          return ListTile(
                            leading: const Icon(Icons.payments),
                            title: Text("BAM ${r.amount.toStringAsFixed(0)}"),
                            subtitle: Text(
                                "${r.user} • ${r.location}\n${_formatDate(r.date)}"),
                            trailing: Text(r.paymentMethod),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 20),

/// 🔥 PDF BUTTON (BOTTOM)
Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton.icon(
    onPressed: _generatePdf,
    icon: const Icon(Icons.picture_as_pdf),
    label: const Text("Generate PDF"),
    style: ElevatedButton.styleFrom(
      backgroundColor: brandOrange,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day}.${d.month}.${d.year}";
  }

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            date == null
                ? label
                : "${date.day}.${date.month}.${date.year}",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
}