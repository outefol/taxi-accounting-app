import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_keys.dart';
import '../i18n.dart';

class Vehicle {
  const Vehicle({required this.id, required this.number});

  final String id;
  final String number;

  Map<String, dynamic> toJson() => {'id': id, 'number': number};

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final number = (json['number'] as String?)?.trim() ?? '';
    if (id.isEmpty || number.isEmpty) {
      throw FormatException(tr('vehicleDataIncomplete'));
    }
    return Vehicle(id: id, number: number);
  }
}

class VehicleStore {
  static const maxVehicles = 100;

  static String recordsKey(String vehicleId) =>
      '$vehicleRecordsPrefix$vehicleId';

  /// Migrates the old single-vehicle keys without changing their values.
  /// Keeping the legacy keys makes rollback and existing backups safe.
  static Future<void> migrateLegacyData(SharedPreferences preferences) async {
    if (preferences.getString(vehiclesKey) != null) {
      return;
    }

    final legacyNumber = preferences.getString(vehicleNumberKey)?.trim();
    final legacyRecords = preferences.getString('taxi_records');
    if ((legacyNumber == null || legacyNumber.isEmpty) &&
        (legacyRecords == null || legacyRecords.isEmpty)) {
      return;
    }

    const firstVehicle = Vehicle(id: legacyVehicleId, number: '未设置车号');
    final vehicle = Vehicle(
      id: firstVehicle.id,
      number: legacyNumber?.isNotEmpty == true
          ? legacyNumber!
          : firstVehicle.number,
    );
    await preferences.setString(vehiclesKey, jsonEncode([vehicle.toJson()]));
    await preferences.setString(activeVehicleIdKey, vehicle.id);
    if (legacyRecords != null && legacyRecords.isNotEmpty) {
      await preferences.setString(recordsKey(vehicle.id), legacyRecords);
    }
  }

  static Future<Vehicle> ensureActiveVehicle(
    SharedPreferences preferences, {
    String? preferredNumber,
  }) async {
    await migrateLegacyData(preferences);
    final vehicles = _readVehicles(preferences);
    final requestedNumber = preferredNumber?.trim();
    if (vehicles.isEmpty) {
      final number = requestedNumber?.isNotEmpty == true
          ? requestedNumber!
          : '未设置车号';
      final vehicle = const Vehicle(id: legacyVehicleId, number: '未设置车号');
      final firstVehicle = Vehicle(id: vehicle.id, number: number);
      await _writeVehicles(preferences, [firstVehicle]);
      await preferences.setString(activeVehicleIdKey, firstVehicle.id);
      return firstVehicle;
    }

    final activeId = preferences.getString(activeVehicleIdKey);
    final activeIndex = vehicles.indexWhere(
      (vehicle) => vehicle.id == activeId,
    );
    final index = activeIndex >= 0 ? activeIndex : 0;
    var active = vehicles[index];
    if (requestedNumber != null &&
        requestedNumber.isNotEmpty &&
        requestedNumber != active.number) {
      final duplicate = vehicles.asMap().entries.any(
        (entry) =>
            entry.key != index &&
            entry.value.number.toUpperCase() == requestedNumber.toUpperCase(),
      );
      if (duplicate) {
        throw ArgumentError(tr('vehicleNumberExists'));
      }
      active = Vehicle(id: active.id, number: requestedNumber);
      vehicles[index] = active;
      await _writeVehicles(preferences, vehicles);
    }
    await preferences.setString(activeVehicleIdKey, active.id);
    await preferences.setString(vehicleNumberKey, active.number);
    return active;
  }

  static Vehicle? activeVehicle(SharedPreferences preferences) {
    final vehicles = _readVehicles(preferences);
    final activeId = preferences.getString(activeVehicleIdKey);
    for (final vehicle in vehicles) {
      if (vehicle.id == activeId) {
        return vehicle;
      }
    }
    return vehicles.isEmpty ? null : vehicles.first;
  }

  static Future<List<Vehicle>> loadVehicles(
    SharedPreferences preferences,
  ) async {
    await migrateLegacyData(preferences);
    final vehicles = _readVehicles(preferences);
    if (vehicles.isEmpty) {
      final first = await ensureActiveVehicle(preferences);
      return [first];
    }
    return vehicles;
  }

  static Future<Vehicle> addVehicle(
    SharedPreferences preferences,
    String number,
  ) async {
    final normalized = number.trim();
    if (normalized.isEmpty) {
      throw ArgumentError(tr('vehicleNumberEmpty'));
    }
    final vehicles = await loadVehicles(preferences);
    final duplicate = vehicles.any(
      (vehicle) => vehicle.number.toUpperCase() == normalized.toUpperCase(),
    );
    if (duplicate) {
      throw ArgumentError(tr('vehicleNumberExists'));
    }
    if (vehicles.length >= maxVehicles) {
      throw StateError(tr('vehicleLimit'));
    }
    final vehicle = Vehicle(
      id: 'vehicle_${DateTime.now().microsecondsSinceEpoch}',
      number: normalized,
    );
    await _writeVehicles(preferences, [...vehicles, vehicle]);
    return vehicle;
  }

  static Future<Vehicle> setActiveVehicle(
    SharedPreferences preferences,
    String vehicleId,
  ) async {
    final vehicles = await loadVehicles(preferences);
    final vehicle = vehicles.firstWhere(
      (item) => item.id == vehicleId,
      orElse: () => throw StateError(tr('vehicleNotFound')),
    );
    await preferences.setString(activeVehicleIdKey, vehicle.id);
    await preferences.setString(vehicleNumberKey, vehicle.number);
    return vehicle;
  }

  static Future<Vehicle> deleteVehicle(
    SharedPreferences preferences,
    String vehicleId,
  ) async {
    final vehicles = await loadVehicles(preferences);
    if (vehicles.length <= 1) {
      throw StateError(tr('keepAtLeastOneVehicle'));
    }
    final index = vehicles.indexWhere((item) => item.id == vehicleId);
    if (index < 0) {
      throw StateError(tr('vehicleNotFound'));
    }
    final wasActive = preferences.getString(activeVehicleIdKey) == vehicleId;
    final remaining = [...vehicles]..removeAt(index);
    await _writeVehicles(preferences, remaining);
    await preferences.remove(recordsKey(vehicleId));
    if (wasActive) {
      final next = remaining.first;
      await preferences.setString(activeVehicleIdKey, next.id);
      await preferences.setString(vehicleNumberKey, next.number);
      return next;
    }
    return activeVehicle(preferences) ?? remaining.first;
  }

  static List<Vehicle> _readVehicles(SharedPreferences preferences) {
    final raw = preferences.getString(vehiclesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final vehicles = <Vehicle>[];
      for (final item in decoded) {
        if (vehicles.length >= maxVehicles) {
          break;
        }
        try {
          vehicles.add(Vehicle.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Ignore malformed entries while preserving valid vehicles.
        }
      }
      return vehicles;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeVehicles(
    SharedPreferences preferences,
    List<Vehicle> vehicles,
  ) async {
    await preferences.setString(
      vehiclesKey,
      jsonEncode(
        vehicles.take(maxVehicles).map((vehicle) => vehicle.toJson()).toList(),
      ),
    );
  }
}
