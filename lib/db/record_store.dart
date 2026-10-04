import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../app_keys.dart';
import '../models/taxi_record.dart';
import '../models/vehicle.dart';

/// 账本数据的 SQLite 存储。
///
/// v2 一次性把 SharedPreferences 里的 JSON 迁移进来；迁移只复制不删除，
/// 旧 key 保留作为回滚备份。
class RecordStore {
  static Database? _db;
  static const _migratedFlag = 'records_migrated_to_sqlite_v2';

  static Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'taxi_accounting.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_id TEXT NOT NULL,
            date TEXT NOT NULL,
            income REAL NOT NULL DEFAULT 0,
            distance REAL NOT NULL DEFAULT 0,
            expenses TEXT NOT NULL DEFAULT '{}',
            note TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_records_vehicle_date '
          'ON records(vehicle_id, date)',
        );
      },
    );
    return _db!;
  }

  /// 确保迁移已执行。返回本次是否执行了迁移。
  static Future<bool> ensureMigrated(SharedPreferences preferences) async {
    if (preferences.getBool(_migratedFlag) ?? false) {
      return false;
    }
    try {
      final db = await _database();
      var moved = 0;

      Future<void> migrateKey(String? stored, String vehicleId) async {
        if (stored == null || stored.isEmpty) return;
        try {
          final decoded = jsonDecode(stored) as List<dynamic>;
          final batch = db.batch();
          for (final item in decoded) {
            try {
              final record = TaxiRecord.fromJson(item as Map<String, dynamic>);
              batch.insert('records', record.toDbRow(vehicleId));
              moved++;
            } catch (_) {
              // 单条坏数据跳过，不影响其他。
            }
          }
          await batch.commit(noResult: true);
        } catch (e) {
          debugPrint('RecordStore migrateKey failed: $e');
        }
      }

      // 先迁多车辆 key，再迁旧版单车辆 key（去重）。
      final vehiclesRaw = preferences.getString(vehiclesKey);
      final seenVehicleIds = <String>{};
      if (vehiclesRaw != null && vehiclesRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(vehiclesRaw) as List<dynamic>;
          for (final item in decoded) {
            try {
              final vehicle = Vehicle.fromJson(item as Map<String, dynamic>);
              seenVehicleIds.add(vehicle.id);
              await migrateKey(
                preferences.getString(VehicleStore.recordsKey(vehicle.id)),
                vehicle.id,
              );
            } catch (_) {}
          }
        } catch (_) {}
      }
      if (!seenVehicleIds.contains(legacyVehicleId)) {
        await migrateKey(
          preferences.getString('taxi_records'),
          legacyVehicleId,
        );
      }

      await preferences.setBool(_migratedFlag, true);
      debugPrint('RecordStore migrated $moved records to SQLite');
      return true;
    } catch (e) {
      debugPrint('RecordStore migration failed: $e');
      return false;
    }
  }

  static Future<List<TaxiRecord>> loadRecords(String vehicleId) async {
    final db = await _database();
    final rows = await db.query(
      'records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TaxiRecord.fromDbRow).toList();
  }

  static Future<List<TaxiRecord>> insertRecords(
    String vehicleId,
    List<TaxiRecord> records,
  ) async {
    if (records.isEmpty) return const [];
    final db = await _database();
    final batch = db.batch();
    for (final record in records) {
      batch.insert('records', record.toDbRow(vehicleId));
    }
    final ids = await batch.commit();
    final saved = <TaxiRecord>[];
    for (var i = 0; i < records.length; i++) {
      saved.add(records[i].copyWith(id: ids[i] as int?));
    }
    await _autoBackup(vehicleId);
    return saved;
  }

  static Future<TaxiRecord> insertRecord(
    String vehicleId,
    TaxiRecord record,
  ) async {
    final db = await _database();
    final id = await db.insert('records', record.toDbRow(vehicleId));
    final saved = record.copyWith(id: id);
    await _autoBackup(vehicleId);
    return saved;
  }

  static Future<void> updateRecord(String vehicleId, TaxiRecord record) async {
    final db = await _database();
    if (record.id == null) {
      await insertRecord(vehicleId, record);
      return;
    }
    await db.update(
      'records',
      record.toDbRow(vehicleId),
      where: 'id = ? AND vehicle_id = ?',
      whereArgs: [record.id, vehicleId],
    );
    await _autoBackup(vehicleId);
  }

  static Future<void> deleteRecord(String vehicleId, int id) async {
    final db = await _database();
    await db.delete(
      'records',
      where: 'id = ? AND vehicle_id = ?',
      whereArgs: [id, vehicleId],
    );
    await _autoBackup(vehicleId);
  }

  static Future<void> clearVehicleRecords(String vehicleId) async {
    final db = await _database();
    await db.delete(
      'records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
    );
    await _autoBackup(vehicleId);
  }

  static Future<int> countRecords(String vehicleId) async {
    final db = await _database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM records WHERE vehicle_id = ?',
      [vehicleId],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// 每次写操作后自动落一份 JSON 备份到应用文档目录，保留最近 7 天。
  /// 这是防 SQLite 损坏的第二道防线；卸载 App 仍会丢失，重要数据请用手动备份。
  static Future<void> _autoBackup(String vehicleId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(dir.path, 'auto_backup'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final records = await loadRecords(vehicleId);
      final now = DateTime.now();
      final name =
          'auto_${vehicleId}_${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.json';
      final file = File(p.join(backupDir.path, name));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 2,
          'vehicleId': vehicleId,
          'exportedAt': now.toIso8601String(),
          'records': records.map((r) => r.toJson()).toList(),
        }),
      );
      // 只保留最近 7 个备份文件。
      final files = await backupDir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      for (final old in files.skip(7)) {
        try {
          await old.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('RecordStore autoBackup failed: $e');
    }
  }
}
