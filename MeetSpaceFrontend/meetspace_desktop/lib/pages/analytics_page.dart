import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/space_demand.dart';
import '../models/space_demand_period.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/admin_pagination.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const _background = Color(0xFF3B3B3B);
  static const _accent = Color.fromARGB(255, 165, 110, 9);

  final DateTimeRange _initialRange = DateTimeRange(
    start: DateTime(2025, 1, 1),
    end: DateTime(2025, 12, 31),
  );

  late DateTimeRange _dateRange = _initialRange;
  List<SpaceDemand> _data = [];
  List<SpaceDemandPeriod> _periods = [];
  bool _loading = true;
  bool _loadingPeriods = false;
  String? _error;
  String? _periodError;
  int _periodRequestId = 0;

  String _cityCode = '';
  String _facilityCode = '';
  String _spaceTypeCode = '';
  String _spaceCode = '';
  String _periodSpaceCode = '';
  int _sortColumn = 4;
  bool _sortAscending = false;
  static const _tablePageSize = 8;
  int _tablePage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _tablePage = 0;
    });

    try {
      final auth = context.read<AuthProvider>();
      final rows = await AnalyticsService(auth.api).getSpaceDemand(
        fromDate: _dateRange.start,
        toDate: _dateRange.end,
      );
      if (!mounted) return;
      setState(() {
        _data = rows;
        _loading = false;
        if (!_data.any((row) => row.cityCode == _cityCode)) _cityCode = '';
        if (!_data.any((row) => row.facilityCode == _facilityCode)) {
          _facilityCode = '';
        }
        if (!_data.any((row) => row.spaceTypeCode == _spaceTypeCode)) {
          _spaceTypeCode = '';
        }
        if (!_data.any((row) => row.spaceCode == _spaceCode)) _spaceCode = '';
      });
      await _loadPeriods(resetSelection: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadPeriods({bool resetSelection = false}) async {
    final candidates = _visibleRows;
    if (candidates.isEmpty) {
      _periodRequestId++;
      if (!mounted) return;
      setState(() {
        _periodSpaceCode = '';
        _periods = [];
        _loadingPeriods = false;
        _periodError = null;
      });
      return;
    }

    final hasSelection = candidates.any((row) => row.spaceCode == _periodSpaceCode);
    final selectedCode = !resetSelection && hasSelection
        ? _periodSpaceCode
        : candidates.first.spaceCode;
    final requestId = ++_periodRequestId;
    setState(() {
      _periodSpaceCode = selectedCode;
      _loadingPeriods = true;
      _periodError = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final periods = await AnalyticsService(auth.api).getSpaceDemandPeriods(
        spaceCode: selectedCode,
        fromDate: _dateRange.start,
        toDate: _dateRange.end,
      );
      if (!mounted || requestId != _periodRequestId) return;
      setState(() {
        _periods = periods.take(5).toList();
        _loadingPeriods = false;
      });
    } catch (error) {
      if (!mounted || requestId != _periodRequestId) return;
      setState(() {
        _loadingPeriods = false;
        _periodError = error.toString();
      });
    }
  }

  List<SpaceDemand> get _cityRows => _data
      .where((row) => _cityCode.isEmpty || row.cityCode == _cityCode)
      .toList();

  List<SpaceDemand> get _facilityRows => _cityRows
      .where((row) => _facilityCode.isEmpty || row.facilityCode == _facilityCode)
      .toList();

  List<SpaceDemand> get _typeRows => _facilityRows
      .where((row) => _spaceTypeCode.isEmpty || row.spaceTypeCode == _spaceTypeCode)
      .toList();

  List<SpaceDemand> get _visibleRows {
    final rows = _typeRows
        .where((row) => _spaceCode.isEmpty || row.spaceCode == _spaceCode)
        .toList();
    rows.sort((a, b) {
      final comparison = switch (_sortColumn) {
        0 => a.spaceName.compareTo(b.spaceName),
        1 => a.facilityName.compareTo(b.facilityName),
        2 => a.cityName.compareTo(b.cityName),
        3 => a.spaceTypeName.compareTo(b.spaceTypeName),
        5 => a.reservedHours.compareTo(b.reservedHours),
        _ => a.confirmedReservations.compareTo(b.confirmedReservations),
      };
      return _sortAscending ? comparison : -comparison;
    });
    return rows;
  }

  List<_Option> _options(
    List<SpaceDemand> rows,
    String Function(SpaceDemand) codeOf,
    String Function(SpaceDemand) nameOf,
  ) {
    final byCode = <String, String>{};
    for (final row in rows) {
      byCode[codeOf(row)] = nameOf(row);
    }
    final options = byCode.entries
        .map((entry) => _Option(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  Future<void> _chooseDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _dateRange,
      helpText: 'Select analysis period',
    );
    if (selected == null) return;
    setState(() => _dateRange = selected);
    _tablePage = 0;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visibleRows;
    final reservations = rows.fold<int>(
      0,
      (total, row) => total + row.confirmedReservations,
    );
    final hours = rows.fold<double>(0, (total, row) => total + row.reservedHours);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'MEETSPACE',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 4,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Refresh demand data',
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Space demand analysis',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Confirmed reservations',
                          _formatInteger(reservations),
                          Icons.event_available,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          'Reserved hours',
                          _formatHours(hours),
                          Icons.schedule,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          'Spaces in view',
                          rows.length.toString(),
                          Icons.meeting_room_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 12),
                  _buildPeakDemand(rows),
                  const SizedBox(height: 12),
                  _buildTable(rows),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final cities = _options(_data, (r) => r.cityCode, (r) => r.cityName);
    final facilities = _options(
      _cityRows,
      (r) => r.facilityCode,
      (r) => r.facilityName,
    );
    final types = _options(
      _facilityRows,
      (r) => r.spaceTypeCode,
      (r) => r.spaceTypeName,
    );
    final spaces = _options(_typeRows, (r) => r.spaceCode, (r) => r.spaceName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterDropdown(
            label: 'City',
            value: _cityCode,
            options: cities,
            onChanged: (value) {
              setState(() {
                _cityCode = value;
                _facilityCode = '';
                _spaceTypeCode = '';
                _spaceCode = '';
                _tablePage = 0;
              });
              _loadPeriods(resetSelection: true);
            },
          ),
          _filterDropdown(
            label: 'Facility',
            value: _facilityCode,
            options: facilities,
            onChanged: (value) {
              setState(() {
                _facilityCode = value;
                _spaceTypeCode = '';
                _spaceCode = '';
                _tablePage = 0;
              });
              _loadPeriods(resetSelection: true);
            },
          ),
          _filterDropdown(
            label: 'Space type',
            value: _spaceTypeCode,
            options: types,
            onChanged: (value) {
              setState(() {
                _spaceTypeCode = value;
                _spaceCode = '';
                _tablePage = 0;
              });
              _loadPeriods(resetSelection: true);
            },
          ),
          _filterDropdown(
            label: 'Space',
            value: _spaceCode,
            options: spaces,
            onChanged: (value) {
              setState(() {
                _spaceCode = value;
                _tablePage = 0;
              });
              _loadPeriods(resetSelection: true);
            },
          ),
          OutlinedButton.icon(
            onPressed: _chooseDateRange,
            icon: const Icon(Icons.date_range),
            label: Text('${_dateLabel(_dateRange.start)} – ${_dateLabel(_dateRange.end)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<_Option> options,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: options.any((option) => option.code == value) ? value : '',
        isExpanded: true,
        menuMaxHeight: 420,
        dropdownColor: _background,
        iconEnabledColor: Colors.white70,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: _background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('All', overflow: TextOverflow.ellipsis),
          ),
          ...options.map(
            (option) => DropdownMenuItem(
              value: option.code,
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        onChanged: (selected) => onChanged(selected ?? ''),
      ),
    );
  }

  Widget _buildTable(List<SpaceDemand> rows) {
    final totalPages = (rows.length / _tablePageSize).ceil();
    final currentPage = totalPages == 0
        ? 0
        : _tablePage.clamp(0, totalPages - 1).toInt();
    final start = currentPage * _tablePageSize;
    final pageRows = rows.skip(start).take(_tablePageSize).toList();

    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              : rows.isEmpty
                  ? const Center(child: Text('No spaces match the selected filters.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                          child: Text(
                            'Demand by space  ·  ${rows.length} spaces',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortColumnIndex: _sortColumn,
                            sortAscending: _sortAscending,
                            horizontalMargin: 10,
                            columnSpacing: 16,
                            headingRowHeight: 42,
                            dataRowMinHeight: 42,
                            dataRowMaxHeight: 42,
                            headingTextStyle: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            dataTextStyle: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                            columns: [
                              _column('Space', 0, width: 178),
                              _column('Facility', 1, width: 175),
                              _column('City', 2, width: 105),
                              _column('Type', 3, width: 170),
                              _column('Confirmed reservations', 4, numeric: true, width: 155),
                              _column('Reserved hours', 5, numeric: true, width: 125),
                            ],
                            rows: pageRows.map(_dataRow).toList(),
                          ),
                        ),
                        if (totalPages > 1) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${start + 1}–${start + pageRows.length} of ${rows.length}',
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E2E2E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: AdminPagination(
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  onPageSelected: (page) => setState(() => _tablePage = page),
                                  onPrevious: currentPage > 0
                                      ? () => setState(() => _tablePage = currentPage - 1)
                                      : null,
                                  onNext: currentPage < totalPages - 1
                                      ? () => setState(() => _tablePage = currentPage + 1)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
    );
  }

  Widget _buildPeakDemand(List<SpaceDemand> rows) {
    final options = _options(rows, (row) => row.spaceCode, (row) => row.spaceName);
    final selected = rows.where((row) => row.spaceCode == _periodSpaceCode);
    final selectedSpace = selected.isEmpty ? null : selected.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Peak demand periods',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<String>(
                  value: options.any((option) => option.code == _periodSpaceCode)
                      ? _periodSpaceCode
                      : null,
                  isExpanded: true,
                  menuMaxHeight: 420,
                  decoration: const InputDecoration(
                    labelText: 'Selected space',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(),
                  ),
                  items: options
                      .map((option) => DropdownMenuItem(
                            value: option.code,
                            child: Text(option.label, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (code) {
                    if (code == null) return;
                    setState(() => _periodSpaceCode = code);
                    _loadPeriods();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingPeriods)
            const LinearProgressIndicator(minHeight: 2, color: _accent)
          else if (_periodError != null)
            Row(
              children: [
                Expanded(child: Text(_periodError!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                TextButton(
                  onPressed: selectedSpace == null ? null : _loadPeriods,
                  child: const Text('Try again'),
                ),
              ],
            )
          else if (selectedSpace == null)
            const Text('No spaces match the selected filters.')
          else if (_periods.isEmpty)
            const Text('No confirmed demand in the selected period.')
          else
            Row(
              children: [
                for (var index = 0; index < _periods.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: _periodCard(index + 1, _periods[index])),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _periodCard(int rank, SpaceDemandPeriod period) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFECE1CE), shape: BoxShape.circle),
            child: Text('$rank', style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_dayName(period.dayOfWeekNumber)}, ${period.hourLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatInteger(period.confirmedReservations)} reservations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int number) => const {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      }[number] ?? 'Day';

  DataColumn _column(
    String label,
    int index, {
    bool numeric = false,
    required double width,
  }) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: numeric ? TextAlign.right : TextAlign.left,
        ),
      ),
      numeric: numeric,
      onSort: (_, ascending) => setState(() {
        _sortColumn = index;
        _sortAscending = ascending;
        _tablePage = 0;
      }),
    );
  }

  DataRow _dataRow(SpaceDemand row) {
    return DataRow(cells: [
      _textCell(row.spaceName, 178),
      _textCell(row.facilityName, 175),
      _textCell(row.cityName, 105),
      _textCell(row.spaceTypeName, 170),
      DataCell(SizedBox(
        width: 155,
        child: Text(
          _formatInteger(row.confirmedReservations),
          textAlign: TextAlign.right,
          maxLines: 1,
        ),
      )),
      DataCell(SizedBox(
        width: 125,
        child: Text(
          _formatHours(row.reservedHours),
          textAlign: TextAlign.right,
          maxLines: 1,
        ),
      )),
    ]);
  }

  DataCell _textCell(String value, double width) {
    return DataCell(
      Tooltip(
        message: value,
        child: SizedBox(
          width: width,
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  String _formatInteger(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  String _formatHours(double value) {
    final fixed = value.toStringAsFixed(1).split('.');
    return '${_formatInteger(int.parse(fixed[0]))},${fixed[1]}';
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class _Option {
  final String code;
  final String label;

  const _Option(this.code, this.label);
}
