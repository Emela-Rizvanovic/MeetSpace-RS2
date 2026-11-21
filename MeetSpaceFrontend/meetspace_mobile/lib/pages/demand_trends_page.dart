import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class DemandTrendsPage extends StatefulWidget {
  const DemandTrendsPage({super.key});

  @override
  State<DemandTrendsPage> createState() => _DemandTrendsPageState();
}

class _DemandTrendsPageState extends State<DemandTrendsPage> {
  static const _background = Color.fromARGB(255, 59, 59, 59);
  static const _accent = Color.fromARGB(255, 165, 110, 9);

  List<Map<String, dynamic>> _spaces = [];
  List<Map<String, dynamic>> _periods = [];
  String? _selectedCode;
  bool _loadingSpaces = true;
  bool _loadingPeriods = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final response = await context.read<AuthProvider>().api.get(
            'Analytics/mobile-spaces',
          );
      if (response.statusCode != 200) {
        throw Exception('Failed to load spaces (${response.statusCode}).');
      }
      final values = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _spaces = values;
        _loadingSpaces = false;
      });
      if (values.isNotEmpty) {
        await _selectSpace(values.first['spaceCode'].toString());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSpaces = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _selectSpace(String code) async {
    setState(() {
      _selectedCode = code;
      _loadingPeriods = true;
      _error = null;
      _periods = [];
    });
    try {
      final response = await context.read<AuthProvider>().api.get(
        'Analytics/space-periods',
        queryParameters: {'spaceCode': code},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load time slots (${response.statusCode}).');
      }
      final values = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _periods = values.take(5).toList();
        _loadingPeriods = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPeriods = false;
        _error = error.toString();
      });
    }
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

  String _spaceTypeName(String? name) => switch (name) {
        'Radni prostor' => 'Workspace',
        'Prostor za sastanke' => 'Meeting space',
        'Prostor za edukacije' => 'Training space',
        'Prostor za poslovne događaje' => 'Event space',
        _ => name ?? 'Space type unavailable',
      };

  @override
  Widget build(BuildContext context) {
    final selected = _spaces.where((s) => s['spaceCode'] == _selectedCode);
    final selectedSpace = selected.isEmpty ? null : selected.first;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('MEETSPACE',
            style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w300)),
      ),
      body: SafeArea(
        child: _loadingSpaces
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  const Text(
                    'Demand trends',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Top time slots by confirmed reservations for the selected space.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 22),
                  DropdownButtonFormField<String>(
                    value: _selectedCode,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF424242),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Space',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF353535),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accent, width: 2),
                      ),
                    ),
                    items: _spaces
                        .map((space) => DropdownMenuItem<String>(
                              value: space['spaceCode'].toString(),
                              child: Text(
                                '${space['spaceName']} · ${space['facilityName']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _selectSpace(value);
                    },
                  ),
                  if (selectedSpace != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      '${selectedSpace['cityName']} · ${_spaceTypeName(selectedSpace['spaceTypeName']?.toString())}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_error != null)
                    _message(_error!, isError: true)
                  else if (_loadingPeriods)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (_periods.isEmpty)
                    _message('No confirmed time slots for this space in the selected period.')
                  else ...[
                    const Text(
                      'Most requested time slots',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._periods.asMap().entries.map((entry) {
                      final period = entry.value;
                      final count = (period['confirmedReservations'] as num).toInt();
                      final maxCount = (_periods.first['confirmedReservations'] as num).toDouble();
                      final progress = maxCount == 0 ? 0.0 : count / maxCount;
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: _accent.withOpacity(.12),
                                    child: Text('${entry.key + 1}',
                                        style: const TextStyle(
                                            color: _accent,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${_dayName((period['dayOfWeekNumber'] as num).toInt())}, ${period['hourLabel']}',
                                      style: const TextStyle(
                                        color: Color(0xFF25232A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                      '$count ${count == 1 ? 'reservation' : 'reservations'}',
                                      style: const TextStyle(
                                          color: Color(0xFF625E67))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  color: _accent,
                                  backgroundColor: const Color(0xFFE9E5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _message(String text, {bool isError = false}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? Colors.red.shade900 : const Color(0xFF353535),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      );
}
