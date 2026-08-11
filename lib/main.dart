import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _passwordKey = 'login_password';
const _vehicleNumberKey = 'vehicle_number';
const _accountKey = 'login_account';
const _loggedInKey = 'logged_in';
const _startupPasswordKey = 'startup_password';
const _languageKey = 'app_language';
const _vehiclesKey = 'vehicles_v2';
const _activeVehicleIdKey = 'active_vehicle_id';
const _legacyVehicleId = 'vehicle_1';
const _vehicleRecordsPrefix = 'taxi_records_vehicle_';
final appLanguage = ValueNotifier<String>('zh');
final appNavigatorKey = GlobalKey<NavigatorState>();

const _translations = <String, Map<String, String>>{
  'zh': {
    'appTitle': '出租车 / 网约车司机专业记账',
    'loginSubtitle': '登录后开始记账',
    'phoneEmail': '手机号码或邮箱',
    'vehicle': '车号',
    'vehicleHint': '例如：沪A12345',
    'password': '密码',
    'setPassword': '设置密码',
    'setPasswordHint': '首次使用请设置本地密码（至少4位）',
    'currentPassword': '当前密码',
    'newPassword': '新密码',
    'confirmPassword': '确认新密码',
    'passwordTooShort': '密码至少需要4位',
    'passwordMismatch': '两次密码不一致',
    'passwordSaved': '密码已保存',
    'login': '登录',
    'firstLogin': '首次登录会绑定本机账号　首次使用需设置本地密码',
    'invalidAccount': '请输入正确的手机号码或邮箱',
    'enterVehicle': '请输入车号',
    'invalidLogin': '手机号、邮箱或密码不正确',
    'details': '明细',
    'statistics': '统计',
    'savings': '存钱',
    'mine': '我的',
    'addRecord': '添加流水',
    'settings': '设置',
    'basicSettings': '基本设置',
    'accountVehicle': '账号与车辆',
    'vehicleManagement': '车辆管理',
    'currentVehicle': '当前车辆',
    'vehicleList': '车辆列表',
    'addVehicle': '添加车辆',
    'deleteVehicle': '删除车辆',
    'switchVehicle': '切换车辆',
    'vehicleLimit': '最多添加 100 辆车',
    'loginAccount': '登录账号',
    'changePassword': '修改登录密码',
    'security': '安全',
    'startupPassword': '启动时需要密码',
    'startupPasswordHint': '下次打开 App 时验证登录密码',
    'lockNow': '立即锁定',
    'backToLogin': '返回登录页面',
    'dataStorage': '数据与存储',
    'localRecords': '本地流水',
    'localOnly': '仅保存在本机，不上传服务器',
    'clearRecords': '清空全部流水',
    'application': '应用',
    'about': '关于应用',
    'language': '语言',
    'common': '常用功能',
    'quickRecord': '快速记账',
    'ledgerStats': '账本统计',
    'passwordLock': '密码锁定',
    'backup': '数据备份',
    'export': '导出数据',
    'import': '导入数据',
    'logout': '退出登录',
    'streak': '连续记账',
    'days': '记账天数',
    'entries': '记账笔数',
    'monthBalance': '本月结余',
    'monthIncome': '月收入',
    'monthExpense': '月支出',
    'noRecords': '这个月还没有流水',
    'tapAdd': '点击下方黄色“＋”开始记账',
    'income': '收入',
    'expense': '支出',
    'week': '周',
    'month': '月',
    'year': '年',
    'expenseRanking': '支出排行榜',
    'incomeSummary': '收入汇总',
    'energy': '油费 / 电费',
    'rent': '车辆租金',
    'distance': '里程',
    'date': '日期',
    'note': '备注',
    'save': '保存',
    'editRecord': '修改流水',
    'deleteRecord': '删除流水',
    'confirmDeleteRecord': '确定删除这条流水吗？',
    'recordDeleted': '流水已删除',
    'cancel': '取消',
  },
  'en': {
    'appTitle': 'Professional Taxi Driver Ledger',
    'loginSubtitle': 'Sign in to start recording',
    'phoneEmail': 'Phone number or email',
    'vehicle': 'Vehicle number',
    'vehicleHint': 'Example: TAXI-001',
    'password': 'Password',
    'setPassword': 'Set password',
    'setPasswordHint': 'Set a local password (at least 4 characters)',
    'currentPassword': 'Current password',
    'newPassword': 'New password',
    'confirmPassword': 'Confirm new password',
    'passwordTooShort': 'Password must be at least 4 characters',
    'passwordMismatch': 'Passwords do not match',
    'passwordSaved': 'Password saved',
    'login': 'Sign in',
    'firstLogin': 'First sign-in binds this device · Set a local password',
    'invalidAccount': 'Enter a valid phone number or email',
    'enterVehicle': 'Enter the vehicle number',
    'invalidLogin': 'Incorrect phone, email, or password',
    'details': 'Details',
    'statistics': 'Statistics',
    'savings': 'Savings',
    'mine': 'Me',
    'addRecord': 'Add record',
    'settings': 'Settings',
    'basicSettings': 'Basic settings',
    'accountVehicle': 'Account & vehicle',
    'vehicleManagement': 'Vehicle management',
    'currentVehicle': 'Current vehicle',
    'vehicleList': 'Vehicle list',
    'addVehicle': 'Add vehicle',
    'deleteVehicle': 'Delete vehicle',
    'switchVehicle': 'Switch vehicle',
    'vehicleLimit': 'Up to 100 vehicles',
    'loginAccount': 'Login account',
    'changePassword': 'Change password',
    'security': 'Security',
    'startupPassword': 'Require password at startup',
    'startupPasswordHint': 'Verify your password next time the app opens',
    'lockNow': 'Lock now',
    'backToLogin': 'Return to sign-in',
    'dataStorage': 'Data & storage',
    'localRecords': 'Local records',
    'localOnly': 'Stored only on this device; never uploaded',
    'clearRecords': 'Clear all records',
    'application': 'Application',
    'about': 'About',
    'language': 'Language',
    'common': 'Common tools',
    'quickRecord': 'Quick record',
    'ledgerStats': 'Statistics',
    'passwordLock': 'Password lock',
    'backup': 'Back up data',
    'export': 'Export data',
    'import': 'Import data',
    'logout': 'Sign out',
    'streak': 'Day streak',
    'days': 'Days recorded',
    'entries': 'Entries',
    'monthBalance': 'Monthly balance',
    'monthIncome': 'Income',
    'monthExpense': 'Expenses',
    'noRecords': 'No records this month',
    'tapAdd': 'Tap the yellow “+” below to add one',
    'income': 'Income',
    'expense': 'Expense',
    'week': 'Week',
    'month': 'Month',
    'year': 'Year',
    'expenseRanking': 'Expense ranking',
    'incomeSummary': 'Income summary',
    'energy': 'Fuel / electricity',
    'rent': 'Vehicle rent',
    'distance': 'Distance',
    'date': 'Date',
    'note': 'Note',
    'save': 'Save',
    'editRecord': 'Edit record',
    'deleteRecord': 'Delete record',
    'confirmDeleteRecord': 'Delete this record?',
    'recordDeleted': 'Record deleted',
    'cancel': 'Cancel',
  },
  'ja': {
    'appTitle': 'タクシー・配車ドライバー記帳',
    'loginSubtitle': 'ログインして記帳を開始',
    'phoneEmail': '電話番号またはメール',
    'vehicle': '車両番号',
    'vehicleHint': '例：TAXI-001',
    'password': 'パスワード',
    'setPassword': 'パスワードを設定',
    'setPasswordHint': '初回使用時にローカルパスワードを設定（4文字以上）',
    'currentPassword': '現在のパスワード',
    'newPassword': '新しいパスワード',
    'confirmPassword': '新しいパスワードを確認',
    'passwordTooShort': 'パスワードは4文字以上必要です',
    'passwordMismatch': 'パスワードが一致しません',
    'passwordSaved': 'パスワードを保存しました',
    'login': 'ログイン',
    'firstLogin': '初回ログインで端末に登録・ローカルパスワードを設定',
    'invalidAccount': '正しい電話番号またはメールを入力してください',
    'enterVehicle': '車両番号を入力してください',
    'invalidLogin': '電話番号、メールまたはパスワードが違います',
    'details': '明細',
    'statistics': '統計',
    'savings': '貯蓄',
    'mine': 'マイページ',
    'addRecord': '記録を追加',
    'settings': '設定',
    'basicSettings': '基本設定',
    'accountVehicle': 'アカウントと車両',
    'vehicleManagement': '車両管理',
    'currentVehicle': '現在の車両',
    'vehicleList': '車両一覧',
    'addVehicle': '車両を追加',
    'deleteVehicle': '車両を削除',
    'switchVehicle': '車両を切り替え',
    'vehicleLimit': '最大100台',
    'loginAccount': 'ログインアカウント',
    'changePassword': 'パスワード変更',
    'security': 'セキュリティ',
    'startupPassword': '起動時にパスワードを要求',
    'startupPasswordHint': '次回起動時にパスワードを確認',
    'lockNow': '今すぐロック',
    'backToLogin': 'ログイン画面に戻る',
    'dataStorage': 'データと保存',
    'localRecords': '端末内の記録',
    'localOnly': 'この端末のみに保存されます',
    'clearRecords': 'すべての記録を削除',
    'application': 'アプリ',
    'about': 'アプリについて',
    'language': '言語',
    'common': 'よく使う機能',
    'quickRecord': 'クイック記帳',
    'ledgerStats': '帳簿統計',
    'passwordLock': 'パスワードロック',
    'backup': 'バックアップ',
    'export': 'データ出力',
    'import': 'データ取込',
    'logout': 'ログアウト',
    'streak': '連続記帳',
    'days': '記帳日数',
    'entries': '記帳件数',
    'monthBalance': '今月の残高',
    'monthIncome': '月収入',
    'monthExpense': '月支出',
    'noRecords': '今月の記録はありません',
    'tapAdd': '下の黄色い「＋」で記帳します',
    'income': '収入',
    'expense': '支出',
    'week': '週',
    'month': '月',
    'year': '年',
    'expenseRanking': '支出ランキング',
    'incomeSummary': '収入合計',
    'energy': '燃料・電気代',
    'rent': '車両賃料',
    'distance': '走行距離',
    'date': '日付',
    'note': 'メモ',
    'save': '保存',
    'editRecord': '記録を編集',
    'deleteRecord': '記録を削除',
    'confirmDeleteRecord': 'この記録を削除しますか？',
    'recordDeleted': '記録を削除しました',
    'cancel': 'キャンセル',
  },
  'es': {
    'appTitle': 'Contabilidad profesional para conductores',
    'loginSubtitle': 'Inicia sesión para registrar',
    'phoneEmail': 'Teléfono o correo',
    'vehicle': 'Número del vehículo',
    'vehicleHint': 'Ejemplo: TAXI-001',
    'password': 'Contraseña',
    'setPassword': 'Establecer contraseña',
    'setPasswordHint': 'Define una contraseña local (mínimo 4 caracteres)',
    'currentPassword': 'Contraseña actual',
    'newPassword': 'Nueva contraseña',
    'confirmPassword': 'Confirmar contraseña',
    'passwordTooShort': 'La contraseña debe tener al menos 4 caracteres',
    'passwordMismatch': 'Las contraseñas no coinciden',
    'passwordSaved': 'Contraseña guardada',
    'login': 'Iniciar sesión',
    'firstLogin':
        'El primer acceso vincula el dispositivo · Define una clave local',
    'invalidAccount': 'Introduce un teléfono o correo válido',
    'enterVehicle': 'Introduce el número del vehículo',
    'invalidLogin': 'Teléfono, correo o contraseña incorrectos',
    'details': 'Detalles',
    'statistics': 'Estadísticas',
    'savings': 'Ahorro',
    'mine': 'Mi cuenta',
    'addRecord': 'Añadir registro',
    'settings': 'Ajustes',
    'basicSettings': 'Ajustes básicos',
    'accountVehicle': 'Cuenta y vehículo',
    'vehicleManagement': 'Gestión de vehículos',
    'currentVehicle': 'Vehículo actual',
    'vehicleList': 'Lista de vehículos',
    'addVehicle': 'Añadir vehículo',
    'deleteVehicle': 'Eliminar vehículo',
    'switchVehicle': 'Cambiar vehículo',
    'vehicleLimit': 'Hasta 100 vehículos',
    'loginAccount': 'Cuenta de acceso',
    'changePassword': 'Cambiar contraseña',
    'security': 'Seguridad',
    'startupPassword': 'Pedir contraseña al iniciar',
    'startupPasswordHint': 'Verificar la contraseña la próxima vez',
    'lockNow': 'Bloquear ahora',
    'backToLogin': 'Volver al acceso',
    'dataStorage': 'Datos y almacenamiento',
    'localRecords': 'Registros locales',
    'localOnly': 'Solo se guardan en este dispositivo',
    'clearRecords': 'Borrar todos los registros',
    'application': 'Aplicación',
    'about': 'Acerca de',
    'language': 'Idioma',
    'common': 'Funciones comunes',
    'quickRecord': 'Registro rápido',
    'ledgerStats': 'Estadísticas',
    'passwordLock': 'Bloqueo',
    'backup': 'Copia de seguridad',
    'export': 'Exportar datos',
    'import': 'Importar datos',
    'logout': 'Cerrar sesión',
    'streak': 'Días seguidos',
    'days': 'Días registrados',
    'entries': 'Registros',
    'monthBalance': 'Saldo mensual',
    'monthIncome': 'Ingresos',
    'monthExpense': 'Gastos',
    'noRecords': 'No hay registros este mes',
    'tapAdd': 'Pulsa el “+” amarillo para añadir uno',
    'income': 'Ingresos',
    'expense': 'Gastos',
    'week': 'Semana',
    'month': 'Mes',
    'year': 'Año',
    'expenseRanking': 'Ranking de gastos',
    'incomeSummary': 'Resumen de ingresos',
    'energy': 'Combustible / electricidad',
    'rent': 'Alquiler del vehículo',
    'distance': 'Distancia',
    'date': 'Fecha',
    'note': 'Nota',
    'save': 'Guardar',
    'editRecord': 'Editar registro',
    'deleteRecord': 'Eliminar registro',
    'confirmDeleteRecord': '¿Eliminar este registro?',
    'recordDeleted': 'Registro eliminado',
    'cancel': 'Cancelar',
  },
};

String tr(String key) =>
    _translations[appLanguage.value]?[key] ?? _translations['zh']![key] ?? key;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  appLanguage.value = preferences.getString(_languageKey) ?? 'zh';
  runApp(const TaxiAccountingApp());
}

class TaxiAccountingApp extends StatelessWidget {
  const TaxiAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, _) => MaterialApp(
        title: tr('appTitle'),
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        locale: Locale(language),
        supportedLocales: const [
          Locale('zh'),
          Locale('en'),
          Locale('ja'),
          Locale('es'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppStartPage(),
      ),
    );
  }
}

class Vehicle {
  const Vehicle({required this.id, required this.number});

  final String id;
  final String number;

  Map<String, dynamic> toJson() => {'id': id, 'number': number};

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final number = (json['number'] as String?)?.trim() ?? '';
    if (id.isEmpty || number.isEmpty) {
      throw const FormatException('车辆数据不完整');
    }
    return Vehicle(id: id, number: number);
  }
}

class VehicleStore {
  static const maxVehicles = 100;

  static String recordsKey(String vehicleId) =>
      '$_vehicleRecordsPrefix$vehicleId';

  /// Migrates the old single-vehicle keys without changing their values.
  /// Keeping the legacy keys makes rollback and existing backups safe.
  static Future<void> migrateLegacyData(SharedPreferences preferences) async {
    if (preferences.getString(_vehiclesKey) != null) {
      return;
    }

    final legacyNumber = preferences.getString(_vehicleNumberKey)?.trim();
    final legacyRecords = preferences.getString('taxi_records');
    if ((legacyNumber == null || legacyNumber.isEmpty) &&
        (legacyRecords == null || legacyRecords.isEmpty)) {
      return;
    }

    const firstVehicle = Vehicle(id: _legacyVehicleId, number: '未设置车号');
    final vehicle = Vehicle(
      id: firstVehicle.id,
      number: legacyNumber?.isNotEmpty == true
          ? legacyNumber!
          : firstVehicle.number,
    );
    await preferences.setString(_vehiclesKey, jsonEncode([vehicle.toJson()]));
    await preferences.setString(_activeVehicleIdKey, vehicle.id);
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
      final vehicle = const Vehicle(id: _legacyVehicleId, number: '未设置车号');
      final firstVehicle = Vehicle(id: vehicle.id, number: number);
      await _writeVehicles(preferences, [firstVehicle]);
      await preferences.setString(_activeVehicleIdKey, firstVehicle.id);
      return firstVehicle;
    }

    final activeId = preferences.getString(_activeVehicleIdKey);
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
        throw ArgumentError('车号已存在');
      }
      active = Vehicle(id: active.id, number: requestedNumber);
      vehicles[index] = active;
      await _writeVehicles(preferences, vehicles);
    }
    await preferences.setString(_activeVehicleIdKey, active.id);
    await preferences.setString(_vehicleNumberKey, active.number);
    return active;
  }

  static Vehicle? activeVehicle(SharedPreferences preferences) {
    final vehicles = _readVehicles(preferences);
    final activeId = preferences.getString(_activeVehicleIdKey);
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
      throw ArgumentError('车号不能为空');
    }
    final vehicles = await loadVehicles(preferences);
    final duplicate = vehicles.any(
      (vehicle) => vehicle.number.toUpperCase() == normalized.toUpperCase(),
    );
    if (duplicate) {
      throw ArgumentError('车号已存在');
    }
    if (vehicles.length >= maxVehicles) {
      throw StateError('最多添加 100 辆车');
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
      orElse: () => throw StateError('车辆不存在'),
    );
    await preferences.setString(_activeVehicleIdKey, vehicle.id);
    await preferences.setString(_vehicleNumberKey, vehicle.number);
    return vehicle;
  }

  static Future<Vehicle> deleteVehicle(
    SharedPreferences preferences,
    String vehicleId,
  ) async {
    final vehicles = await loadVehicles(preferences);
    if (vehicles.length <= 1) {
      throw StateError('至少保留一辆车');
    }
    final index = vehicles.indexWhere((item) => item.id == vehicleId);
    if (index < 0) {
      throw StateError('车辆不存在');
    }
    final wasActive = preferences.getString(_activeVehicleIdKey) == vehicleId;
    final remaining = [...vehicles]..removeAt(index);
    await _writeVehicles(preferences, remaining);
    await preferences.remove(recordsKey(vehicleId));
    if (wasActive) {
      final next = remaining.first;
      await preferences.setString(_activeVehicleIdKey, next.id);
      await preferences.setString(_vehicleNumberKey, next.number);
      return next;
    }
    return activeVehicle(preferences) ?? remaining.first;
  }

  static List<Vehicle> _readVehicles(SharedPreferences preferences) {
    final raw = preferences.getString(_vehiclesKey);
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
      _vehiclesKey,
      jsonEncode(
        vehicles.take(maxVehicles).map((vehicle) => vehicle.toJson()).toList(),
      ),
    );
  }
}

class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _AppStartPageState extends State<AppStartPage> {
  Future<SharedPreferences> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await VehicleStore.migrateLegacyData(preferences);
    return preferences;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _loadPreferences(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final preferences = snapshot.data!;
        final account = preferences.getString(_accountKey);
        final vehicleNumber = preferences.getString(_vehicleNumberKey);
        final loggedIn = preferences.getBool(_loggedInKey) ?? false;
        final startupPassword =
            preferences.getBool(_startupPasswordKey) ?? false;
        final hasPassword =
            preferences.getString(_passwordKey)?.isNotEmpty ?? false;
        if (loggedIn &&
            account != null &&
            vehicleNumber != null &&
            hasPassword &&
            !startupPassword) {
          final activeVehicle = VehicleStore.activeVehicle(preferences);
          return HomePage(
            account: account,
            vehicleNumber: activeVehicle?.number ?? vehicleNumber,
            activeVehicleId: activeVehicle?.id,
          );
        }
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInformation();
  }

  Future<void> _loadSavedLoginInformation() async {
    final preferences = await SharedPreferences.getInstance();
    await VehicleStore.migrateLegacyData(preferences);
    final savedVehicle = preferences.getString(_vehicleNumberKey);
    final savedAccount = preferences.getString(_accountKey);
    if (mounted) {
      if (savedVehicle != null) {
        _vehicleNumberController.text = savedVehicle;
      }
      if (savedAccount != null) {
        _usernameController.text = savedAccount;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _vehicleNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _showPasswordSetupDialog() async {
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(tr('setPassword')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('setPasswordHint'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newController,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('newPassword'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return tr('passwordTooShort');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('confirmPassword'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == newController.text ? null : tr('passwordMismatch'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, newController.text);
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    // The dialog route owns the fields until its exit animation completes.
    // Do not dispose these controllers synchronously here; doing so can make
    // the closing route rebuild with a disposed controller.
    return password;
  }

  Future<void> _login() async {
    final account = _usernameController.text.trim().toLowerCase();
    final vehicleNumber = _vehicleNumberController.text.trim();
    var password = _passwordController.text;

    final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(account);
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(account);
    if (!isPhone && !isEmail) {
      setState(() {
        _errorMessage = tr('invalidAccount');
      });
      return;
    }

    if (vehicleNumber.isEmpty) {
      setState(() {
        _errorMessage = tr('enterVehicle');
      });
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    var savedPassword = preferences.getString(_passwordKey);
    if (savedPassword == null || savedPassword.isEmpty) {
      final newPassword = await _showPasswordSetupDialog();
      if (newPassword == null) {
        return;
      }
      await preferences.setString(_passwordKey, newPassword);
      savedPassword = newPassword;
      // On first use there is no existing password to verify. The password
      // just created in the setup dialog is the credential for this login.
      password = newPassword;
    }
    final savedAccount = preferences.getString(_accountKey);
    final accountMatches = savedAccount == null || savedAccount == account;
    if (accountMatches && password == savedPassword) {
      await preferences.setString(_accountKey, account);
      await preferences.setString(_vehicleNumberKey, vehicleNumber);
      await preferences.setBool(_loggedInKey, true);
      late final Vehicle activeVehicle;
      try {
        activeVehicle = await VehicleStore.ensureActiveVehicle(
          preferences,
          preferredNumber: vehicleNumber,
        );
      } on ArgumentError catch (error) {
        setState(() => _errorMessage = error.message?.toString());
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            account: account,
            vehicleNumber: activeVehicle.number,
            activeVehicleId: activeVehicle.id,
          ),
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = tr('invalidLogin');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_taxi,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('appTitle'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(tr('loginSubtitle')),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: tr('phoneEmail'),
                          prefixIcon: const Icon(Icons.alternate_email),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _vehicleNumberController,
                        decoration: InputDecoration(
                          labelText: tr('vehicle'),
                          hintText: tr('vehicleHint'),
                          prefixIcon: const Icon(Icons.directions_car),
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: tr('password'),
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? '显示密码' : '隐藏密码',
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _login,
                          child: Text(tr('login')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(tr('firstLogin')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.account,
    required this.vehicleNumber,
    required this.recordCount,
    required this.onAccountChanged,
    required this.onVehicleNumberChanged,
    required this.onClearRecords,
    required this.activeVehicleId,
    required this.onVehicleChanged,
  });

  final String account;
  final String vehicleNumber;
  final int recordCount;
  final Future<void> Function(String value) onAccountChanged;
  final Future<void> Function(String value) onVehicleNumberChanged;
  final Future<void> Function() onClearRecords;
  final String activeVehicleId;
  final Future<void> Function(Vehicle vehicle) onVehicleChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _account;
  late String _vehicleNumber;
  late int _recordCount;
  late String _activeVehicleId;
  List<Vehicle> _vehicles = [];
  bool _startupPassword = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _vehicleNumber = widget.vehicleNumber;
    _recordCount = widget.recordCount;
    _activeVehicleId = widget.activeVehicleId;
    _loadSecuritySettings();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final preferences = await SharedPreferences.getInstance();
    final vehicles = await VehicleStore.loadVehicles(preferences);
    if (!mounted) {
      return;
    }
    setState(() {
      _vehicles = vehicles;
      if (!_vehicles.any((vehicle) => vehicle.id == _activeVehicleId)) {
        _activeVehicleId = vehicles.first.id;
      }
    });
  }

  Future<void> _addVehicle() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final number = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('addVehicle')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: tr('vehicle'),
              hintText: tr('vehicleHint'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? tr('enterVehicle')
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (number == null || !mounted) {
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await VehicleStore.addVehicle(preferences, number);
      await _loadVehicles();
      _message('${tr('addVehicle')}：$number');
    } on ArgumentError catch (error) {
      _message(error.message?.toString() ?? '车号无效');
    } on StateError catch (error) {
      _message(error.message);
    }
  }

  Future<void> _switchVehicle(Vehicle vehicle) async {
    if (vehicle.id == _activeVehicleId) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final active = await VehicleStore.setActiveVehicle(preferences, vehicle.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _activeVehicleId = active.id;
      _vehicleNumber = active.number;
    });
    await widget.onVehicleChanged(active);
    if (mounted) {
      _message('${tr('currentVehicle')}：${active.number}');
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    if (_vehicles.length <= 1) {
      _message('至少保留一辆车');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('deleteVehicle')),
        content: Text('确定删除车号 ${vehicle.number} 吗？该车辆的流水也会删除。'),
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
            child: Text(tr('deleteVehicle')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final active = await VehicleStore.deleteVehicle(preferences, vehicle.id);
      await _loadVehicles();
      if (mounted) {
        setState(() {
          _activeVehicleId = active.id;
          _vehicleNumber = active.number;
        });
      }
      await widget.onVehicleChanged(active);
      if (mounted) {
        _message('${tr('deleteVehicle')}：${vehicle.number}');
      }
    } on StateError catch (error) {
      _message(error.message);
    }
  }

  Future<void> _loadSecuritySettings() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _startupPassword = preferences.getBool(_startupPasswordKey) ?? false;
      });
    }
  }

  Future<void> _setStartupPassword(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_startupPasswordKey, value);
    if (mounted) {
      setState(() => _startupPassword = value);
      _message(value ? '已开启启动密码' : '已关闭启动密码');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _languageName(String code) {
    const names = {'zh': '中文', 'en': 'English', 'ja': '日本語', 'es': 'Español'};
    return names[code] ?? '中文';
  }

  Future<void> _selectLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('language')),
        children: [
          for (final entry in const {
            'zh': '中文',
            'en': 'English',
            'ja': '日本語',
            'es': 'Español',
          }.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Row(
                children: [
                  Expanded(child: Text(entry.value)),
                  if (entry.key == appLanguage.value)
                    const Icon(Icons.check, color: Color(0xFFFFBE4F)),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, selected);
    appLanguage.value = selected;
  }

  Future<void> _editAccount() async {
    final controller = TextEditingController(text: _account);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改登录账号'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '手机号码或邮箱',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim().toLowerCase() ?? '';
              final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(text);
              final isEmail = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(text);
              return isPhone || isEmail ? null : '请输入正确的手机号码或邮箱';
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim().toLowerCase());
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) {
      return;
    }
    await widget.onAccountChanged(value);
    if (mounted) {
      setState(() => _account = value);
      _message('登录账号已更新');
    }
  }

  Future<void> _editVehicleNumber() async {
    final controller = TextEditingController(text: _vehicleNumber);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改车号'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '车号',
              hintText: '例如：沪A12345',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入车号';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) {
      return;
    }
    try {
      await widget.onVehicleNumberChanged(value);
    } on ArgumentError catch (error) {
      if (mounted) {
        _message(error.message?.toString() ?? '车号无效');
      }
      return;
    }
    if (mounted) {
      setState(() => _vehicleNumber = value);
      await _loadVehicles();
      _message('车号已更新');
    }
  }

  Future<String?> _promptNewPassword() async {
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('setPassword')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('setPasswordHint'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newController,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('newPassword'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.length < 4
                    ? tr('passwordTooShort')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('confirmPassword'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == newController.text ? null : tr('passwordMismatch'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, newController.text);
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    // The dialog route owns the fields until its exit animation completes.
    // Do not dispose these controllers synchronously here; doing so can make
    // the closing route rebuild with a disposed controller.
    return password;
  }

  Future<void> _changePassword() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final currentPassword = preferences.getString(_passwordKey);
    if (currentPassword == null || currentPassword.isEmpty) {
      final password = await _promptNewPassword();
      if (password != null) {
        await preferences.setString(_passwordKey, password);
        if (mounted) {
          _message(tr('passwordSaved'));
        }
      }
      return;
    }
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改登录密码'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldController,
                obscureText: true,
                decoration: InputDecoration(labelText: tr('currentPassword')),
                validator: (value) =>
                    value == currentPassword ? null : '当前密码不正确',
              ),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(labelText: tr('newPassword')),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return tr('passwordTooShort');
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(labelText: tr('confirmPassword')),
                validator: (value) =>
                    value == newController.text ? null : tr('passwordMismatch'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (changed == true) {
      await preferences.setString(_passwordKey, newController.text);
      if (mounted) {
        _message('登录密码已修改');
      }
    }
    // The dialog route owns these fields until its exit animation completes.
  }

  Future<void> _clearRecords() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final savedPassword = preferences.getString(_passwordKey);
    if (savedPassword == null || savedPassword.isEmpty) {
      _message(tr('setPasswordHint'));
      return;
    }
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final passwordVerified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('验证密码后清空'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '登录密码',
              hintText: '请输入登录密码',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != savedPassword) {
                return '密码不正确，无法清空流水';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('下一步'),
          ),
        ],
      ),
    );
    // Keep the controller alive until the password dialog route has finished
    // its exit animation; disposing synchronously can trigger a rebuild with
    // a disposed controller.
    if (passwordVerified != true || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部流水？'),
        content: const Text('此操作无法撤销。建议先在“我的”页面进行数据备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF05C4D),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.onClearRecords();
    if (mounted) {
      setState(() => _recordCount = 0);
      _message('全部流水已清空');
    }
  }

  void _showAbout() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    showAboutDialog(
      context: context,
      applicationName: '出租车 / 网约车司机专业记账',
      applicationVersion:
          '${packageInfo.version} (Build ${packageInfo.buildNumber})',
      applicationIcon: const Icon(
        Icons.local_taxi,
        size: 48,
        color: Color(0xFFFFBE4F),
      ),
      children: const [Text('出租车与网约车司机的本地流水、里程和费用管理工具。')],
    );
  }

  Future<void> _lockApp() async {
    // 修改退出逻辑：仅关闭当前设置页面返回上一级，不清除登录状态，也不跳转到登录页
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFBE4F);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(title: Text(tr('basicSettings')), backgroundColor: yellow),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: [
          _SettingsSectionTitle(tr('accountVehicle')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: Text(tr('loginAccount')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(_account), const Icon(Icons.chevron_right)],
                  ),
                  onTap: _editAccount,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.local_taxi_outlined),
                  title: Text(tr('vehicle')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_vehicleNumber),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: _editVehicleNumber,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: Text(tr('changePassword')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSectionTitle(tr('vehicleManagement')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_taxi),
                  title: Text(tr('currentVehicle')),
                  trailing: Text(
                    _vehicleNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                if (_vehicles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  for (final vehicle in _vehicles)
                    ListTile(
                      leading: Icon(
                        vehicle.id == _activeVehicleId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: vehicle.id == _activeVehicleId
                            ? yellow
                            : Colors.grey,
                      ),
                      title: Text(vehicle.number),
                      subtitle: vehicle.id == _activeVehicleId
                          ? Text(tr('currentVehicle'))
                          : TextButton(
                              onPressed: () => _switchVehicle(vehicle),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(tr('switchVehicle')),
                            ),
                      trailing: IconButton(
                        tooltip: tr('deleteVehicle'),
                        onPressed: () => _deleteVehicle(vehicle),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFF05C4D),
                        ),
                      ),
                      onTap: () => _switchVehicle(vehicle),
                    ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(tr('addVehicle')),
                  subtitle: Text(
                    '${_vehicles.length}/100 · ${tr('vehicleLimit')}',
                  ),
                  onTap: _vehicles.length >= VehicleStore.maxVehicles
                      ? null
                      : _addVehicle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSectionTitle(tr('security')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.password),
                  title: Text(tr('startupPassword')),
                  subtitle: Text(tr('startupPasswordHint')),
                  value: _startupPassword,
                  onChanged: _setStartupPassword,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(tr('lockNow')),
                  subtitle: Text(tr('backToLogin')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _lockApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSectionTitle(tr('dataStorage')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(tr('localRecords')),
                  trailing: Text('$_recordCount 条'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(tr('dataStorage')),
                  subtitle: Text(tr('localOnly')),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFF05C4D),
                  ),
                  title: Text(
                    tr('clearRecords'),
                    style: const TextStyle(color: Color(0xFFF05C4D)),
                  ),
                  onTap: _clearRecords,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSectionTitle(tr('application')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(tr('language')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_languageName(appLanguage.value)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: _selectLanguage,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(tr('about')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAbout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
    _activeVehicleId = widget.activeVehicleId ?? _legacyVehicleId;
    _loadRecords();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCashSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/cash.mp3'));
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
      _showMessage('读取本地数据失败');
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
    if (_activeVehicleId == _legacyVehicleId) {
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
    await preferences.setString(_vehicleNumberKey, value);
    if (mounted) {
      setState(() => _vehicleNumber = value);
    }
  }

  Future<void> _updateAccount(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accountKey, value);
    if (mounted) {
      setState(() => _account = value);
    }
  }

  Future<void> _clearAllRecords() async {
    setState(_records.clear);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(VehicleStore.recordsKey(_activeVehicleId));
    if (_activeVehicleId == _legacyVehicleId) {
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
        _showMessage('备份保存成功');
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
        _showMessage('CSV 导出成功');
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
          title: const Text('导入备份'),
          content: Text(
            '找到 ${imported.length} 条流水，其中 ${newRecords.length} 条是新数据。\n'
            '导入会与现有数据合并，不会删除原有流水。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('导入'),
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
      _showMessage('成功导入 ${newRecords.length} 条新流水');
    } on FormatException {
      _showMessage('导入失败：文件格式不正确');
    } on PlatformException catch (error) {
      _showMessage('导入失败：${error.message ?? '无法读取文件'}');
    } catch (_) {
      _showMessage('导入失败：备份文件内容不完整');
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
      throw const FormatException('CSV 文件为空');
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
      throw const FormatException('CSV 中没有流水数据');
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
      throw FormatException('无法在 CSV 中找到日期或金额列：${headers.join(', ')}');
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
      throw const FormatException('未识别到有效的流水记录');
    }
    return records;
  }

  Future<void> _chooseMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '选择要查看的月份',
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
    ).showSnackBar(SnackBar(content: Text('$name功能将在下一步添加')));
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String _weekday(DateTime date) {
    const names = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
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
          ? '本周'
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
                ? '今天'
                : '${date.month}/${date.day}',
          )
          .toList();
    } else if (_statisticsRange == 1) {
      final month = DateTime(today.year, today.month + _statisticsOffset);
      rangeStart = month;
      rangeEnd = DateTime(month.year, month.month + 1);
      periodTitle = '${month.year}年${month.month}月';
      final days = rangeEnd.difference(rangeStart).inDays;
      bucketStarts = <DateTime>[];
      bucketEnds = <DateTime>[];
      labels = <String>[];
      for (var day = 1; day <= days; day += 7) {
        final start = DateTime(month.year, month.month, day);
        final endDay = (day + 7).clamp(1, days + 1);
        bucketStarts.add(start);
        bucketEnds.add(DateTime(month.year, month.month, endDay));
        labels.add('$day日');
      }
    } else {
      final year = today.year + _statisticsOffset;
      rangeStart = DateTime(year);
      rangeEnd = DateTime(year + 1);
      periodTitle = '$year年';
      bucketStarts = List.generate(12, (index) => DateTime(year, index + 1));
      bucketEnds = List.generate(12, (index) => DateTime(year, index + 2));
      labels = List.generate(12, (index) => '${index + 1}月');
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
                          '车号：$_vehicleNumber',
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
                      '总${_statisticsShowExpense ? '支出' : '收入'} '
                      '¥${total.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (periodRecords.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.black12,
                          ),
                          SizedBox(height: 12),
                          Text(
                            '这个时间段还没有数据',
                            style: TextStyle(color: Colors.grey),
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
                    label: '出租车收入',
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
      await preferences.setBool(_loggedInKey, false);
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
        applicationName: '出租车 / 网约车司机专业记账',
        applicationVersion:
            '${packageInfo.version} (Build ${packageInfo.buildNumber})',
        applicationIcon: const Icon(Icons.local_taxi, size: 48, color: yellow),
        children: const [
          Text('本地单机出租车与网约车收入、支出和里程管理工具。'),
          SizedBox(height: 8),
          Text('数据只保存在设备本地，不使用 Token 或服务器。'),
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
                                    '车号：$_vehicleNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '设置',
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
                                              tooltip: '搜索',
                                              onPressed: () =>
                                                  _showComingSoon('搜索'),
                                              icon: const Icon(Icons.search),
                                            ),
                                            IconButton(
                                              tooltip: '选择月份',
                                              onPressed: _chooseMonth,
                                              icon: const Icon(
                                                Icons.calendar_month,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: '退出登录',
                                              onPressed: () async {
                                                final preferences =
                                                    await SharedPreferences.getInstance();
                                                await preferences.setBool(
                                                  _loggedInKey,
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
                                                  '${_selectedMonth.year}年${_selectedMonth.month}月',
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
                                          '车号：$_vehicleNumber',
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
                                        '${date.month.toString().padLeft(2, '0')}月'
                                        '${date.day.toString().padLeft(2, '0')}日 '
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
                                          '收入：¥${dailyIncome.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '支出：¥${dailyExpense.toStringAsFixed(2)}  '
                                          '净收入：¥${dailyNet.toStringAsFixed(2)}',
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
                                                ? '出租车收入'
                                                : record.note,
                                            style: const TextStyle(
                                              fontSize: 19,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '里程 ${record.distance.toStringAsFixed(1)} km　'
                                            '支出 ¥${record.totalCost.toStringAsFixed(2)}',
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
          tooltip: '添加流水',
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
            return '请输入收入';
          }
          if (text.isNotEmpty && double.tryParse(text) == null) {
            return '请输入正确的数字';
          }
          return null;
        },
      ),
    );
  }
}

class TaxiRecord {
  const TaxiRecord({
    required this.date,
    required this.income,
    required this.distance,
    required this.energyCost,
    required this.vehicleRent,
    required this.note,
  });

  final DateTime date;
  final double income;
  final double distance;
  final double energyCost;
  final double vehicleRent;
  final String note;

  double get totalCost => energyCost + vehicleRent;

  String get uniqueKey =>
      '${date.toIso8601String()}|$income|$distance|$energyCost|'
      '$vehicleRent|$note';

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'income': income,
    'distance': distance,
    'energyCost': energyCost,
    'vehicleRent': vehicleRent,
    'note': note,
  };

  factory TaxiRecord.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return TaxiRecord(
      date: DateTime.parse(json['date'] as String),
      income: number('income'),
      distance: number('distance'),
      energyCost: number('energyCost'),
      vehicleRent: number('vehicleRent'),
      note: json['note'] as String? ?? '',
    );
  }
}
