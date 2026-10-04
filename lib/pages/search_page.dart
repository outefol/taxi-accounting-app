import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../i18n.dart';
import '../models/expense_categories.dart';
import '../models/taxi_record.dart';

/// 按备注/日期搜索流水（只读展示）。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.records});

  final List<TaxiRecord> records;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TaxiRecord> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.records.where((record) {
      final dateText =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-'
          '${record.date.day.toString().padLeft(2, '0')}';
      final expenseText = record.expenses.entries
          .map(
            (e) =>
                '${tr(ExpenseCategories.labelKey(e.key))}${e.value.toStringAsFixed(2)}',
          )
          .join(' ');
      final haystack =
          '${record.note} $dateText $expenseText ${record.income}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(tr('searchRecords'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: tr('searchHint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _controller.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (_query.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  trf('searchResultCount', {'n': '${results.length}'}),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          Expanded(
            child: _query.trim().isEmpty
                ? Center(
                    child: Text(
                      tr('searchHint'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : results.isEmpty
                ? Center(
                    child: Text(
                      tr('noSearchResults'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = results[index];
                      final dateText =
                          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-'
                          '${record.date.day.toString().padLeft(2, '0')}';
                      return ListTile(
                        title: Text(
                          record.note.isEmpty ? tr('taxiIncome') : record.note,
                        ),
                        subtitle: Text(
                          '$dateText · ${trf('distanceExpenseLine', {
                                'd': record.distance.toStringAsFixed(1),
                                'c': money(record.totalCost),
                              })}',
                        ),
                        trailing: Text(
                          '+${record.income.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
