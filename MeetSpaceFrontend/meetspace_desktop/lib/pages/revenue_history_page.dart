import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../models/revenue.dart';
import '../services/revenue_service.dart';
import '../utils/pdf_helper.dart';
import 'package:open_file/open_file.dart';
import 'payment_reference_data_dialog.dart';
import 'package:printing/printing.dart';

class RevenueHistoryPage extends StatefulWidget {
  const RevenueHistoryPage({super.key});

  @override
  State<RevenueHistoryPage> createState() => _RevenueHistoryPageState();
}

class _RevenueHistoryPageState extends State<RevenueHistoryPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<RevenueResponse> _data = [];

  bool _loading = true;

  String _search = "";
  String _sort = "Date ↓";

  DateTime? _fromDate;
  DateTime? _toDate;

  int _page = 0;
final int _pageSize = 5;
int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  final auth = context.read<AuthProvider>();
  final service = RevenueService(auth.api);

final sort = _getSortParams();

final result = await service.getPaged(
  page: _page,
  pageSize: _pageSize,
  search: _search.isNotEmpty ? _search : null,
  sortBy: sort["sortBy"],
  desc: sort["desc"],
  from: _fromDate,
  to: _toDate,
);

if (!mounted) return;

  setState(() {
    _data = result.items;
    _totalPages = result.totalPages;
    _loading = false;
  });
}

 Map<String, dynamic> _getSortParams() {
  String? sortBy;
  bool desc = false;

  switch (_sort) {
    case "Date ↓":
      sortBy = "PaymentDate"; 
      desc = true;
      break;

    case "Date ↑":
      sortBy = "PaymentDate";
      desc = false;
      break;

    case "Amount ↓":
      sortBy = "Amount";
      desc = true;
      break;

    case "Amount ↑":
      sortBy = "Amount";
      desc = false;
      break;
  }

  return {
    "sortBy": sortBy,
    "desc": desc,
  };
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
  _page = 0;
});

_load();
    }
  }

Future<void> _generatePdf() async {
  try {
    final pdf = await PdfHelper.generateRevenuePdf(
      _data,
      from: _fromDate,
      to: _toDate,
    );

    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/revenue_report.pdf");

    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);

  } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Failed to generate PDF")),
  );
}
}

Future<void> _printPdf() async {
  try {
    final pdf = await PdfHelper.generateRevenuePdf(
      _data,
      from: _fromDate,
      to: _toDate,
    );

    await Printing.layoutPdf(
      name: "revenue_report.pdf",
      onLayout: (_) async => pdf.save(),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to print PDF")),
    );
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
Row(
  children: [
    InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
      ),
    ),

    const SizedBox(width: 16),

    const Text(
      "MEETSPACE",
      style: TextStyle(
        color: Colors.white70,
        letterSpacing: 4,
        fontSize: 18,
      ),
    ),
  ],
),

const SizedBox(height: 10),
           
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

                OutlinedButton.icon(
  onPressed: () async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const PaymentReferenceDataDialog(),
    );
  },
  icon: const Icon(Icons.settings),
  label:
      const Text("Manage system data"),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side:
        const BorderSide(color: Colors.white24),
    padding:
        const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    minimumSize:
        const Size(0, 52),
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(14),
    ),
  ),
),

const SizedBox(width: 16),

                _dateButton("From", _fromDate, () => _pickDate(true)),
const SizedBox(width: 8),
_dateButton("To", _toDate, () => _pickDate(false)),
                const SizedBox(width: 8),

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
    _page = 0;
  });

  _load();
},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              onChanged: (value) {
  setState(() {
    _search = value;
    _page = 0;
  });

  _load();
},
              decoration: InputDecoration(
                hintText: "Search transactions by space name",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

        Expanded(
  child: _loading
      ? const Center(
          child: CircularProgressIndicator(color: brandOrange),
        )
      : SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final r = _data[index];

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

              const SizedBox(height: 12),

              _buildPagination(),

                     const SizedBox(height: 20),

Align(
  alignment: Alignment.centerRight,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ElevatedButton.icon(
        onPressed: _generatePdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Generate PDF"),
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      const SizedBox(width: 12),
      ElevatedButton.icon(
        onPressed: _printPdf,
        icon: const Icon(Icons.print),
        label: const Text("Print"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  ),
),
            ],
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

  Widget _buildPagination() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _page > 0
              ? () {
                  setState(() => _page--);
                  _load();
                }
              : null,
          child: Icon(
            Icons.chevron_left,
            color: _page > 0 ? Colors.white : Colors.white24,
          ),
        ),

        const SizedBox(width: 8),

        for (int i = 0; i < _totalPages; i++)
          GestureDetector(
            onTap: () {
              setState(() => _page = i);
              _load();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _page == i
                    ? const Color(0xFFA56E09)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${i + 1}",
                style: TextStyle(
                  fontSize: 13,
                  color: _page == i ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(width: 8),

        GestureDetector(
          onTap: _page < _totalPages - 1
              ? () {
                  setState(() => _page++);
                  _load();
                }
              : null,
          child: Icon(
            Icons.chevron_right,
            color: _page < _totalPages - 1
                ? Colors.white
                : Colors.white24,
          ),
        ),
      ],
    ),
  );
}
}