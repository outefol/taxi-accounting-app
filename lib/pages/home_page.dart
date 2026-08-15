import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_keys.dart';
import '../i18n.dart';
import '../models/taxi_record.dart';
import '../models/vehicle.dart';
import 'login_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.account,
    required this.vehicleNumber,
    this.activeVehicleId,
  });

  final String account;
  final String vehicleNumber;
  final String? activeVehicleId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _recordsKey = 'taxi_records';
  static const _fileChannel = MethodChannel('taxi_accounting_app/files');
  final _audioPlayer = AudioPlayer();
  final List<TaxiRecord> _records = [];
  late String _account;
  late String _vehicleNumber;
  late String _activeVehicleId;
  DateTime _selectedMonth = DateTime.now();
  int _currentTab = 0;
  int _statisticsRange = 0;
  int _statisticsOffset = 0;
  bool _statisticsShowExpense = true;
  final Set<String> _expandedDateKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _vehicleNumber = widget.vehicleNumber;
    _activeVehicleId = widget.activeVehicleId ?? legacyVehicleId;
    _loadRecords();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCashSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/cash.wav'));
    } catch (_) {
      // 如果文件不存在或播放失败，静默处理，不干扰主逻辑
    }
  }

  Future<void> _loadRecords() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final activeVehicle = await VehicleStore.ensureActiveVehicle(
        preferences,
        preferredNumber: _vehicleNumber,
      );
      _activeVehicleId = activeVehicle.id;
      _vehicleNumber = activeVehicle.number;
      final stored =
          preferences.getString(VehicleStore.recordsKey(_activeVehicleId)) ??
          // Fallback keeps data readable if an interrupted migration left
          // only the old key behind.
          preferences.getString(_recordsKey);
      if (stored == null || stored.isEmpty) {
        return;
      }
      final decoded = jsonDecode(stored) as List<dynamic>;
      final records = decoded
          .map((item) => TaxiRecord.fromJson(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _records
            ..clear()
            ..addAll(records);
        });
      }
    } catch (_) {
      _showMessage(tr('loadRecordsFailed'));
    }
  }

  Future<void> _saveRecords() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _records.map((record) => record.toJson()).toList(),
    );
    await preferences.setString(
      VehicleStore.recordsKey(_activeVehicleId),
      encoded,
    );
    // Keep the legacy key mirrored for the first vehicle so older builds can
    // still open the current vehicle's data after an upgrade.
    if (_activeVehicleId == legacyVehicleId) {
      await preferences.setString(_recordsKey, encoded);
    }
  }

  Future<void> _updateVehicleNumber(String value) async {
    final preferences = await SharedPreferences.getInstance();
    final activeVehicle = await VehicleStore.ensureActiveVehicle(
      preferences,
      preferredNumber: value,
    );
    _activeVehicleId = activeVehicle.id;
    await preferences.setString(vehicleNumberKey, value);
    if (mounted) {
      setState(() => _vehicleNumber = value);
    }
  }

  Future<void> _updateAccount(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(accountKey, value);
    if (mounted) {
      setState(() => _account = value);
    }
  }

  Future<void> _clearAllRecords() async {
    setState(_records.clear);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(VehicleStore.recordsKey(_activeVehicleId));
    if (_activeVehicleId == legacyVehicleId) {
      await preferences.remove(_recordsKey);
    }
  }

  Future<void> _switchVehicle(Vehicle vehicle) async {
    final preferences = await SharedPreferences.getInstance();
    await VehicleStore.setActiveVehicle(preferences, vehicle.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _activeVehicleId = vehicle.id;
      _vehicleNumber = vehicle.number;
      _records.clear();
      _expandedDateKeys.clear();
    });
    await _loadRecords();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          account: _account,
          vehicleNumber: _vehicleNumber,
          recordCount: _records.length,
          onAccountChanged: _updateAccount,
          onVehicleNumberChanged: _updateVehicleNumber,
          onClearRecords: _clearAllRecords,
          activeVehicleId: _activeVehicleId,
          onVehicleChanged: _switchVehicle,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addRecord() async {
    final record = await Navigator.of(context).push<TaxiRecord>(
      MaterialPageRoute(builder: (_) => const AddRecordPage()),
    );

    if (record != null) {
      setState(() {
        _records.add(record);
        _selectedMonth = DateTime(record.date.year, record.date.month);
      });
      await _saveRecords();
      await _playCashSound();
    }
  }

  Future<void> _editRecord(TaxiRecord record) async {
    final updated = await Navigator.of(context).push<TaxiRecord>(
      MaterialPageRoute(builder: (_) => AddRecordPage(initialRecord: record)),
    );
    if (updated == null) {
      return;
    }
    final index = _records.indexOf(record);
    if (index < 0) {
      return;
    }
    setState(() => _records[index] = updated);
    await _saveRecords();
    _showMessage(tr('editRecord'));
  }

  Future<void> _deleteRecord(TaxiRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('deleteRecord')),
        content: Text(tr('confirmDeleteRecord')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF05C4D),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('deleteRecord')),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _records.remove(record));
    await _saveRecords();
    _showMessage(tr('recordDeleted'));
  }

  String _backupJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'account': _account,
      'vehicleNumber': _vehicleNumber,
      'exportedAt': DateTime.now().toIso8601String(),
      'records': _records.map((record) => record.toJson()).toList(),
    });
  }

  Future<void> _backupData() async {
    try {
      final now = DateTime.now();
      final filename =
          '出租车记账备份_${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.json';
      final saved = await _fileChannel.invokeMethod<bool>('saveText', {
        'filename': filename,
        'mimeType': 'application/json',
        'content': _backupJson(),
      });
      if (saved == true) {
        _showMessage(tr('backupSaved'));
      }
    } on PlatformException catch (error) {
      _showMessage('备份失败：${error.message ?? '无法保存文件'}');
    }
  }

  String _csvValue(Object value) {
    final text = value.toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<void> _exportCsv() async {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln('日期,车号,收入,里程,油费电费,车辆租金,总支出,净收入,备注');
    for (final record in _records) {
      buffer.writeln(
        [
          _csvValue(record.date.toIso8601String().split('T').first),
          _csvValue(_vehicleNumber),
          record.income.toStringAsFixed(2),
          record.distance.toStringAsFixed(1),
          record.energyCost.toStringAsFixed(2),
          record.vehicleRent.toStringAsFixed(2),
          record.totalCost.toStringAsFixed(2),
          (record.income - record.totalCost).toStringAsFixed(2),
          _csvValue(record.note),
        ].join(','),
      );
    }

    try {
      final now = DateTime.now();
      final filename =
          '出租车流水_${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.csv';
      final saved = await _fileChannel.invokeMethod<bool>('saveText', {
        'filename': filename,
        'mimeType': 'text/csv',
        'content': buffer.toString(),
      });
      if (saved == true) {
        _showMessage(tr('csvExported'));
      }
    } on PlatformException catch (error) {
      _showMessage('导出失败：${error.message ?? '无法保存文件'}');
    }
  }

  Future<void> _importData() async {
    try {
      final content = await _fileChannel.invokeMethod<String>('openText', {
        // 允许在同一个文件选择器里选择 JSON 或 CSV。
        'mimeType': '*/*',
      });
      if (content == null || content.isEmpty) {
        return;
      }
      final trimmedContent = content.trimLeft().replaceFirst('\uFEFF', '');
      final imported = trimmedContent.startsWith('{')
          ? _parseJsonRecords(trimmedContent)
          : _parseCsvRecords(trimmedContent);
      final existingKeys = _records.map((record) => record.uniqueKey).toSet();
      final newRecords = imported
          .where((record) => !existingKeys.contains(record.uniqueKey))
          .toList();
      if (!mounted) {
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('importBackup')),
          content: Text(
            '${trf('importSummary', {'found': '${imported.length}', 'new': '${newRecords.length}'})}\n'
            '${tr('importMergeNote')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('importAction')),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
      setState(() {
        _records.addAll(newRecords);
      });
      await _saveRecords();
      _showMessage(trf('importSuccess', {'count': '${newRecords.length}'}));
    } on FormatException {
      _showMessage(tr('importFailedFormat'));
    } on PlatformException catch (error) {
      _showMessage(
        trf('importFailedGeneric', {
          'reason': error.message ?? tr('cannotReadFile'),
        }),
      );
    } catch (_) {
      _showMessage(tr('importFailedIncomplete'));
    }
  }

  List<TaxiRecord> _parseJsonRecords(String content) {
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final items = decoded['records'] as List<dynamic>? ?? const [];
    return items
        .map((item) => TaxiRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<TaxiRecord> _parseCsvRecords(String csvContent) {
    if (csvContent.trim().isEmpty) {
      throw FormatException(tr('csvEmpty'));
    }

    final cleaned = csvContent
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    // Try the common CSV separators and keep the parse with the widest
    // meaningful rows. This supports both exports used by the app.
    const delimiters = [',', ';', '\t'];
    List<List<dynamic>> rows = const [];
    var selectedDelimiter = ',';
    var bestScore = -1;
    for (final delimiter in delimiters) {
      final parsed = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(cleaned);
      if (parsed.isEmpty) {
        continue;
      }
      final score = parsed.take(8).fold<int>(0, (sum, row) => sum + row.length);
      if (score > bestScore) {
        bestScore = score;
        rows = parsed;
        selectedDelimiter = delimiter;
      }
    }
    debugPrint('CSV delimiter: "$selectedDelimiter"');
    debugPrint('CSV parsed rows: ${rows.length}');

    if (rows.length < 2) {
      throw FormatException(tr('csvNoRecords'));
    }

    String normalize(Object? value) => value
        .toString()
        .replaceAll('\uFEFF', '')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_./\\()（）【】\[\]：:，,\-]'), '');

    bool hasHeaderWord(String text) {
      final normalized = normalize(text);
      return normalized.contains('日期') ||
          normalized.contains('时间') ||
          normalized.contains('金额') ||
          normalized.contains('收入') ||
          normalized.contains('收支');
    }

    var headerRowIndex = 0;
    for (var i = 0; i < rows.length && i < 10; i++) {
      if (hasHeaderWord(rows[i].join(' '))) {
        headerRowIndex = i;
        break;
      }
    }

    final headers = rows[headerRowIndex].map(normalize).toList();
    int findColumn(List<String> aliases) {
      final normalizedAliases = aliases.map(normalize).toList();
      for (final alias in normalizedAliases) {
        for (var i = 0; i < headers.length; i++) {
          if (headers[i] == alias ||
              (alias.length > 1 && headers[i].contains(alias))) {
            return i;
          }
        }
      }
      return -1;
    }

    final dateColumn = findColumn(['日期', '交易日期', '记账日期', '时间', '交易时间', 'date']);
    final typeColumn = findColumn([
      '收支类型',
      '收支',
      '收/支',
      '交易类型',
      '类型',
      'type',
      'inout',
    ]);
    final categoryColumn = findColumn(['类别', '分类', '子类', 'category']);
    final amountColumn = findColumn([
      '金额',
      '金额元',
      '收入金额',
      '流水金额',
      '交易金额',
      '收入',
      '流水',
      'amount',
      'money',
      'income',
    ]);
    final expenseColumn = findColumn([
      '支出金额',
      '支出',
      '扣款',
      'expense',
      'outflow',
    ]);
    final distanceColumn = findColumn([
      '里程',
      '公里数',
      '公里',
      '距离',
      'distance',
      'km',
    ]);
    final energyColumn = findColumn([
      '油费电费',
      '油费',
      '电费',
      'energy',
      'fuel',
      'electricity',
    ]);
    final rentColumn = findColumn(['车辆租金', '车租', '租金', 'rent']);
    final noteColumn = findColumn([
      '备注',
      '说明',
      '摘要',
      'note',
      'remark',
      'description',
    ]);

    if (dateColumn < 0 || (amountColumn < 0 && expenseColumn < 0)) {
      throw FormatException(
        trf('csvMissingColumns', {'cols': headers.join(', ')}),
      );
    }

    String cell(List<dynamic> row, int index) {
      if (index < 0 || index >= row.length) {
        return '';
      }
      return row[index].toString().trim();
    }

    double? parseNumber(String value) {
      var text = value
          .replaceAll('\u00A0', ' ')
          .replaceAll('￥', '')
          .replaceAll('¥', '')
          .replaceAll('，', ',')
          .replaceAll('．', '.')
          .trim();
      if (text.isEmpty || text == '-' || text == '—') {
        return null;
      }
      final match = RegExp(r'[-+]?\d[\d,\s]*(?:\.\d+)?').firstMatch(text);
      if (match == null) {
        return null;
      }
      final number = double.tryParse(
        match.group(0)!.replaceAll(RegExp(r'[\s,]'), ''),
      );
      if (number == null || number.isNaN || number.isInfinite) {
        return null;
      }
      return text.contains('(') && text.contains(')') ? -number.abs() : number;
    }

    DateTime? parseDate(String value) {
      final match = RegExp(
        r'(\d{4})\s*(?:年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日?|[-/.](\d{1,2})[-/.](\d{1,2}))',
      ).firstMatch(value.trim());
      if (match == null) {
        return null;
      }
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2) ?? match.group(4)!);
      final day = int.parse(match.group(3) ?? match.group(5)!);
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day
          ? date
          : null;
    }

    final records = <TaxiRecord>[];
    for (final row in rows.skip(headerRowIndex + 1)) {
      if (row.every((value) => value.toString().trim().isEmpty)) {
        continue;
      }

      final date = parseDate(cell(row, dateColumn));
      if (date == null) {
        continue;
      }

      final type = cell(row, typeColumn).toLowerCase();
      final category = cell(row, categoryColumn);
      final note = cell(row, noteColumn);
      final description = '$category $note'.toLowerCase();
      final isExpense =
          type.contains('支出') ||
          type.contains('expense') ||
          type.contains('outflow') ||
          type.contains('debit');

      final rawAmount = parseNumber(cell(row, amountColumn));
      final rawExpense = parseNumber(cell(row, expenseColumn));
      final incomeAmount = rawAmount?.abs();
      var income = 0.0;
      var energyCost = parseNumber(cell(row, energyColumn))?.abs() ?? 0.0;
      var vehicleRent = parseNumber(cell(row, rentColumn))?.abs() ?? 0.0;

      // The taxi export has dedicated expense columns. The 懒猫 export has
      // one amount column plus 收支类型/类别, so classify that amount here.
      if (isExpense) {
        final expenseAmount = (rawAmount ?? rawExpense)?.abs() ?? 0.0;
        if (description.contains('租')) {
          vehicleRent = vehicleRent == 0 ? expenseAmount : vehicleRent;
        } else if (energyCost == 0) {
          energyCost = expenseAmount;
        }
      } else if (incomeAmount != null) {
        income = incomeAmount;
      }

      // If a file only has a separate 支出 column, retain it as a cost.
      if (rawAmount == null && rawExpense != null && !isExpense) {
        energyCost = rawExpense.abs();
      }

      final distance = parseNumber(cell(row, distanceColumn))?.abs() ?? 0.0;
      final finalNote = category.isNotEmpty && note.isNotEmpty
          ? '$category: $note'
          : category.isNotEmpty
          ? category
          : note;

      records.add(
        TaxiRecord(
          date: date,
          income: income,
          distance: distance,
          energyCost: energyCost,
          vehicleRent: vehicleRent,
          note: finalNote,
        ),
      );
    }

    debugPrint('CSV parsed records: ${records.length}');
    if (records.isEmpty) {
      throw FormatException(tr('noValidRecords'));
    }
    return records;
  }

  Future<void> _chooseMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: tr('selectMonth'),
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month);
        _expandedDateKeys.clear();
      });
    }
  }

  void _showComingSoon(String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(trf('comingSoon', {'name': name}))));
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String _weekday(DateTime date) {
    final names = [
      tr('weekdayMon'),
      tr('weekdayTue'),
      tr('weekdayWed'),
      tr('weekdayThu'),
      tr('weekdayFri'),
      tr('weekdaySat'),
      tr('weekdaySun'),
    ];
    return names[date.weekday - 1];
  }

  Widget _buildStatisticsBody() {
    const yellow = Color(0xFFFFBE4F);
    final today = DateTime.now();
    late DateTime rangeStart;
    late DateTime rangeEnd;
    late String periodTitle;
    late List<String> labels;
    late List<DateTime> bucketStarts;
    late List<DateTime> bucketEnds;

    if (_statisticsRange == 0) {
      final thisMonday = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: today.weekday - 1));
      rangeStart = thisMonday.add(Duration(days: _statisticsOffset * 7));
      rangeEnd = rangeStart.add(const Duration(days: 7));
      periodTitle = _statisticsOffset == 0
          ? tr('thisWeek')
          : '${rangeStart.month}/${rangeStart.day} - '
                '${rangeEnd.subtract(const Duration(days: 1)).month}/'
                '${rangeEnd.subtract(const Duration(days: 1)).day}';
      bucketStarts = List.generate(
        7,
        (index) => rangeStart.add(Duration(days: index)),
      );
      bucketEnds = bucketStarts
          .map((date) => date.add(const Duration(days: 1)))
          .toList();
      labels = bucketStarts
          .map(
            (date) =>
                date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day
                ? tr('today')
                : '${date.month}/${date.day}',
          )
          .toList();
    } else if (_statisticsRange == 1) {
      final month = DateTime(today.year, today.month + _statisticsOffset);
      rangeStart = month;
      rangeEnd = DateTime(month.year, month.month + 1);
      periodTitle = trf('monthPeriod', {
        'year': '${month.year}',
        'month': '${month.month}',
      });
      final days = rangeEnd.difference(rangeStart).inDays;
      bucketStarts = <DateTime>[];
      bucketEnds = <DateTime>[];
      labels = <String>[];
      for (var day = 1; day <= days; day += 7) {
        final start = DateTime(month.year, month.month, day);
        final endDay = (day + 7).clamp(1, days + 1);
        bucketStarts.add(start);
        bucketEnds.add(DateTime(month.year, month.month, endDay));
        labels.add(trf('dayAxis', {'n': '$day'}));
      }
    } else {
      final year = today.year + _statisticsOffset;
      rangeStart = DateTime(year);
      rangeEnd = DateTime(year + 1);
      periodTitle = trf('yearPeriod', {'year': '$year'});
      bucketStarts = List.generate(12, (index) => DateTime(year, index + 1));
      bucketEnds = List.generate(12, (index) => DateTime(year, index + 2));
      labels = List.generate(
        12,
        (index) => trf('monthAxis', {'n': '${index + 1}'}),
      );
    }

    bool isInRange(DateTime date, DateTime start, DateTime end) =>
        !date.isBefore(start) && date.isBefore(end);

    double recordValue(TaxiRecord record) =>
        _statisticsShowExpense ? record.totalCost : record.income;

    final periodRecords = _records
        .where((record) => isInRange(record.date, rangeStart, rangeEnd))
        .toList();
    final values = List.generate(bucketStarts.length, (index) {
      return periodRecords
          .where(
            (record) =>
                isInRange(record.date, bucketStarts[index], bucketEnds[index]),
          )
          .fold<double>(0, (sum, record) => sum + recordValue(record));
    });
    final total = periodRecords.fold<double>(
      0,
      (sum, record) => sum + recordValue(record),
    );
    final energyTotal = periodRecords.fold<double>(
      0,
      (sum, record) => sum + record.energyCost,
    );
    final rentTotal = periodRecords.fold<double>(
      0,
      (sum, record) => sum + record.vehicleRent,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: yellow,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          trf('vehicleNumberLine', {'v': _vehicleNumber}),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _statisticsShowExpense,
                            dropdownColor: yellow,
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: true,
                                child: Text(tr('expense')),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text(tr('income')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _statisticsShowExpense = value;
                                });
                              }
                            },
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 72),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 0, label: Text(tr('week'))),
                        ButtonSegment(value: 1, label: Text(tr('month'))),
                        ButtonSegment(value: 2, label: Text(tr('year'))),
                      ],
                      selected: {_statisticsRange},
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? yellow
                              : Colors.white,
                        ),
                        side: const WidgetStatePropertyAll(
                          BorderSide(color: Colors.white),
                        ),
                      ),
                      onSelectionChanged: (selection) {
                        setState(() {
                          _statisticsRange = selection.first;
                          _statisticsOffset = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() => _statisticsOffset--);
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          periodTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _statisticsOffset++);
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
                  child: _LineChart(
                    values: values,
                    labels: labels,
                    color: yellow,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _statisticsShowExpense
                          ? tr('expenseRanking')
                          : tr('incomeSummary'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_statisticsShowExpense ? tr('totalExpense') : tr('totalIncome')} '
                      '¥${total.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (periodRecords.isEmpty)
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.black12,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr('noStatsData'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_statisticsShowExpense) ...[
                  _RankingRow(
                    label: tr('energy'),
                    value: energyTotal,
                    total: total,
                    color: const Color(0xFFF05C4D),
                  ),
                  const SizedBox(height: 18),
                  _RankingRow(
                    label: tr('rent'),
                    value: rentTotal,
                    total: total,
                    color: yellow,
                  ),
                ] else
                  _RankingRow(
                    label: tr('taxiIncome'),
                    value: total,
                    total: total,
                    color: yellow,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBody() {
    const yellow = Color(0xFFFFBE4F);
    final uniqueDays =
        _records
            .map(
              (record) => DateTime(
                record.date.year,
                record.date.month,
                record.date.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    var continuousDays = 0;
    if (uniqueDays.isNotEmpty) {
      var expected = uniqueDays.first;
      for (final day in uniqueDays) {
        if (day != expected) {
          break;
        }
        continuousDays++;
        expected = expected.subtract(const Duration(days: 1));
      }
    }

    Future<void> lockApp() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(loggedInKey, false);
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }

    void showAbout() async {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      showAboutDialog(
        context: context,
        applicationName: tr('appTitle'),
        applicationVersion:
            '${packageInfo.version} (Build ${packageInfo.buildNumber})',
        applicationIcon: const Icon(Icons.local_taxi, size: 48, color: yellow),
        children: [
          Text(tr('localAppDescription')),
          const SizedBox(height: 8),
          Text(tr('privacyDescription')),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 278,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 58,
                  child: Container(
                    color: yellow,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 18, 72),
                        child: Row(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_taxi,
                                size: 44,
                                color: yellow,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _account,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                          trf('vehicleNumberLine', {'v': _vehicleNumber}),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: tr('settings'),
                              onPressed: _openSettings,
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        children: [
                          _ProfileCount(
                            value: '$continuousDays',
                            label: tr('streak'),
                          ),
                          _ProfileCount(
                            value: '${uniqueDays.length}',
                            label: tr('days'),
                          ),
                          _ProfileCount(
                            value: '${_records.length}',
                            label: tr('entries'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ProfileSection(
                title: tr('common'),
                children: [
                  _ProfileAction(
                    icon: Icons.add_circle_outline,
                    label: tr('quickRecord'),
                    onTap: _addRecord,
                  ),
                  _ProfileAction(
                    icon: Icons.bar_chart,
                    label: tr('ledgerStats'),
                    onTap: () {
                      setState(() => _currentTab = 1);
                    },
                  ),
                  _ProfileAction(
                    icon: Icons.lock_outline,
                    label: tr('passwordLock'),
                    onTap: lockApp,
                  ),
                  _ProfileAction(
                    icon: Icons.cloud_upload_outlined,
                    label: tr('backup'),
                    onTap: _backupData,
                  ),
                  _ProfileAction(
                    icon: Icons.file_upload_outlined,
                    label: tr('export'),
                    onTap: _exportCsv,
                  ),
                  _ProfileAction(
                    icon: Icons.file_download_outlined,
                    label: tr('import'),
                    onTap: _importData,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ProfileMenuItem(
                icon: Icons.info_outline,
                title: tr('about'),
                onTap: showAbout,
              ),
              const Divider(height: 1, indent: 58),
              _ProfileMenuItem(
                icon: Icons.logout,
                title: tr('logout'),
                color: const Color(0xFFF05C4D),
                onTap: lockApp,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFBE4F);
    const orange = Color(0xFFF05C4D);
    final monthRecords =
        _records
            .where(
              (record) =>
                  record.date.year == _selectedMonth.year &&
                  record.date.month == _selectedMonth.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final monthIncome = monthRecords.fold<double>(
      0,
      (sum, record) => sum + record.income,
    );
    final monthCost = monthRecords.fold<double>(
      0,
      (sum, record) => sum + record.totalCost,
    );
    final monthBalance = monthIncome - monthCost;
    final groupedRecords = <String, List<TaxiRecord>>{};
    for (final record in monthRecords) {
      groupedRecords.putIfAbsent(_dateKey(record.date), () => []).add(record);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      extendBody: true,
      body: _currentTab == 1
          ? _buildStatisticsBody()
          : _currentTab == 3
          ? _buildProfileBody()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 310,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          bottom: 76,
                          child: Container(
                            color: yellow,
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 42,
                                  top: 44,
                                  child: Icon(
                                    Icons.local_taxi,
                                    size: 112,
                                    color: Colors.white.withValues(alpha: 0.36),
                                  ),
                                ),
                                SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      12,
                                      16,
                                      0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tr('appTitle'),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: tr('search'),
                                              onPressed: () =>
                                                  _showComingSoon(tr('search')),
                                              icon: const Icon(Icons.search),
                                            ),
                                            IconButton(
                                              tooltip: tr('selectMonthShort'),
                                              onPressed: _chooseMonth,
                                              icon: const Icon(
                                                Icons.calendar_month,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: tr('logout'),
                                              onPressed: () async {
                                                final preferences =
                                                    await SharedPreferences.getInstance();
                                                await preferences.setBool(
                                                  loggedInKey,
                                                  false,
                                                );
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                Navigator.of(
                                                  context,
                                                ).pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const LoginPage(),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.logout),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 22),
                                        InkWell(
                                          onTap: _chooseMonth,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  trf('monthPeriod', {
                                                    'year':
                                                        '${_selectedMonth.year}',
                                                    'month':
                                                        '${_selectedMonth.month}',
                                                  }),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text(
                          trf('vehicleNumberLine', {'v': _vehicleNumber}),
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          top: 158,
                          child: _MonthlySummaryCard(
                            income: monthIncome,
                            cost: monthCost,
                            balance: monthBalance,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (monthRecords.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 72,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(tr('noRecords')),
                            const SizedBox(height: 6),
                            Text(
                              tr('tapAdd'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate([
                      for (final entry in groupedRecords.entries) ...[
                        Builder(
                          builder: (context) {
                            final date = entry.value.first.date;
                            final dateKey = _dateKey(date);
                            final dailyIncome = entry.value.fold<double>(
                              0,
                              (sum, record) => sum + record.income,
                            );
                            final dailyExpense = entry.value.fold<double>(
                              0,
                              (sum, record) => sum + record.totalCost,
                            );
                            final dailyNet = dailyIncome - dailyExpense;
                            final expanded = _expandedDateKeys.contains(
                              dateKey,
                            );
                            return InkWell(
                              key: ValueKey('date-group-$dateKey'),
                              onTap: () {
                                setState(() {
                                  if (expanded) {
                                    _expandedDateKeys.remove(dateKey);
                                  } else {
                                    _expandedDateKeys.add(dateKey);
                                  }
                                });
                              },
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: yellow,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${trf('dateGrouped', {
                                              'm': date.month
                                                  .toString()
                                                  .padLeft(2, '0'),
                                              'd': date.day
                                                  .toString()
                                                  .padLeft(2, '0'),
                                            })} '
                                        '${_weekday(date)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          trf('incomeLine', {
                                            'v':
                                                '¥${dailyIncome.toStringAsFixed(2)}',
                                          }),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${trf('expenseLine', {
                                                'v':
                                                    '¥${dailyExpense.toStringAsFixed(2)}',
                                              })}  '
                                          '${trf('netIncomeLine', {
                                                'v':
                                                    '¥${dailyNet.toStringAsFixed(2)}',
                                              })}',
                                          style: TextStyle(
                                            color: dailyNet >= 0
                                                ? Colors.grey
                                                : orange,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      expanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_expandedDateKeys.contains(
                          _dateKey(entry.value.first.date),
                        ))
                          for (final record in entry.value)
                            InkWell(
                              onTap: () => _editRecord(record),
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  16,
                                  8,
                                  16,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(top: 9),
                                      decoration: const BoxDecoration(
                                        color: orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.note.isEmpty
                                                ? tr('taxiIncome')
                                                : record.note,
                                            style: const TextStyle(
                                              fontSize: 19,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            trf('distanceExpenseLine', {
                                              'd': record.distance
                                                  .toStringAsFixed(1),
                                              'c':
                                                  '¥${record.totalCost.toStringAsFixed(2)}',
                                            }),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+${record.income.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: tr('editRecord'),
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _editRecord(record);
                                        } else if (action == 'delete') {
                                          _deleteRecord(record);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(tr('editRecord')),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(tr('deleteRecord')),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        const Divider(height: 1, indent: 46),
                      ],
                      const SizedBox(height: 120),
                    ]),
                  ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 78,
        height: 78,
        child: FloatingActionButton(
          onPressed: _addRecord,
          tooltip: tr('addRecord'),
          backgroundColor: yellow,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 44),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 76,
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.receipt_long,
              label: tr('details'),
              selected: _currentTab == 0,
              onTap: () {
                setState(() => _currentTab = 0);
              },
            ),
            _BottomItem(
              icon: Icons.bar_chart,
              label: tr('statistics'),
              selected: _currentTab == 1,
              onTap: () {
                setState(() => _currentTab = 1);
              },
            ),
            const SizedBox(width: 72),
            _BottomItem(
              icon: Icons.person_outline,
              label: tr('mine'),
              selected: _currentTab == 3,
              onTap: () {
                setState(() => _currentTab = 3);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.income,
    required this.cost,
    required this.balance,
  });

  final double income;
  final double cost;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFFF05C4D),
                ),
                const SizedBox(width: 8),
                Text(
                  tr('monthBalance'),
                  style: const TextStyle(
                    color: Color(0xFFF05C4D),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥ ${balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${tr('monthIncome')}：¥ ${income.toStringAsFixed(2)}　　'
              '${tr('monthExpense')}：¥ ${cost.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFFB83E) : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProfileCount extends StatelessWidget {
  const _ProfileCount({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBE4F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF444444)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(values: values, color: color),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFECECEC)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) {
      return;
    }

    final maximum = values.fold<double>(0, (max, value) {
      return value > max ? value : max;
    });
    final chartMaximum = maximum <= 0 ? 1.0 : maximum * 1.15;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = color;
    final path = Path();

    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height - (values[index] / chartMaximum * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
            Text(
              '¥${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: color,
          backgroundColor: const Color(0xFFF0F0F0),
        ),
      ],
    );
  }
}

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key, this.initialRecord});

  final TaxiRecord? initialRecord;

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _distanceController = TextEditingController();
  final _energyController = TextEditingController();
  final _vehicleRentController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    if (record != null) {
      _date = record.date;
      _incomeController.text = record.income.toStringAsFixed(2);
      _distanceController.text = record.distance.toStringAsFixed(1);
      _energyController.text = record.energyCost.toStringAsFixed(2);
      _vehicleRentController.text = record.vehicleRent.toStringAsFixed(2);
      _noteController.text = record.note;
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _distanceController.dispose();
    _energyController.dispose();
    _vehicleRentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      TaxiRecord(
        date: _date,
        income: _number(_incomeController),
        distance: _number(_distanceController),
        energyCost: _number(_energyController),
        vehicleRent: _number(_vehicleRentController),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRecord == null ? tr('addRecord') : tr('editRecord'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('date')),
              subtitle: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _chooseDate,
            ),
            _NumberField(
              controller: _incomeController,
              label: '${tr('income')}（¥）',
              required: true,
            ),
            _NumberField(
              controller: _distanceController,
              label: '${tr('distance')}（km）',
            ),
            _NumberField(
              controller: _energyController,
              label: '${tr('energy')}（¥）',
            ),
            _NumberField(
              controller: _vehicleRentController,
              label: '${tr('rent')}（¥）',
            ),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: tr('note'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(tr('save'))),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) {
            return tr('invalidIncome');
          }
          if (text.isNotEmpty && double.tryParse(text) == null) {
            return tr('invalidNumber');
          }
          return null;
        },
      ),
    );
  }
}
