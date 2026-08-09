import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taxi_accounting_app/main.dart';

void main() {
  test('旧版单车数据迁移到第一辆车', () async {
    final legacyRecords = jsonEncode([
      {
        'date': '2026-08-09T00:00:00.000',
        'income': 500.0,
        'distance': 120.0,
        'energyCost': 80.0,
        'vehicleRent': 50.0,
        'note': '旧数据',
      },
    ]);
    SharedPreferences.setMockInitialValues({
      'vehicle_number': '沪A12345',
      'taxi_records': legacyRecords,
    });

    final preferences = await SharedPreferences.getInstance();
    await VehicleStore.migrateLegacyData(preferences);

    expect(preferences.getString('active_vehicle_id'), 'vehicle_1');
    final vehicles =
        jsonDecode(preferences.getString('vehicles_v2')!) as List<dynamic>;
    expect(vehicles.single['number'], '沪A12345');
    expect(
      preferences.getString('taxi_records_vehicle_vehicle_1'),
      legacyRecords,
    );
  });

  test('车辆管理遵守数量、重复和切换规则', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = await VehicleStore.ensureActiveVehicle(
      preferences,
      preferredNumber: '沪A11111',
    );
    final second = await VehicleStore.addVehicle(preferences, '沪A22222');

    expect(first.number, '沪A11111');
    expect(second.number, '沪A22222');
    await expectLater(
      VehicleStore.addVehicle(preferences, '沪a22222'),
      throwsA(isA<ArgumentError>()),
    );

    await VehicleStore.setActiveVehicle(preferences, second.id);
    expect(preferences.getString('active_vehicle_id'), second.id);
    final fallback = await VehicleStore.deleteVehicle(preferences, second.id);
    expect(fallback.id, first.id);
    await expectLater(
      VehicleStore.deleteVehicle(preferences, first.id),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('添加流水后自动计算净收入', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TaxiAccountingApp());
    await tester.pumpAndSettle();

    expect(find.text('出租车 / 网约车司机专业记账'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);

    final loginFields = find.byType(TextField);
    await tester.enterText(loginFields.at(0), '13800138000');
    await tester.enterText(loginFields.at(1), '沪A12345');
    await tester.enterText(loginFields.at(2), '123456');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.text('设置密码'), findsOneWidget);
    final passwordFields = find.byType(TextFormField);
    await tester.enterText(passwordFields.at(0), '2468');
    await tester.enterText(passwordFields.at(1), '2468');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('添加流水'), findsOneWidget);
    expect(find.text('车号：沪A12345'), findsOneWidget);
    expect(find.text('¥ 0.00'), findsOneWidget);

    await tester.tap(find.byTooltip('添加流水'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '500');
    await tester.enterText(fields.at(1), '120');
    await tester.enterText(fields.at(2), '80');
    await tester.enterText(fields.at(3), '50');
    await tester.enterText(fields.at(4), '晚班');

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('¥ 370.00'), findsOneWidget);
    expect(find.text('+500.00'), findsNothing);
    expect(find.textContaining('净收入：¥370.00'), findsOneWidget);
    await tester.tap(find.text('收入：¥500.00'));
    await tester.pumpAndSettle();
    expect(find.text('+500.00'), findsOneWidget);
    expect(find.textContaining('里程 120.0 km'), findsOneWidget);
    expect(find.textContaining('月收入：¥ 500.00'), findsOneWidget);
    expect(find.textContaining('月支出：¥ 130.00'), findsOneWidget);
    expect(find.textContaining('晚班'), findsOneWidget);
    await tester.tap(find.text('收入：¥500.00'));
    await tester.pumpAndSettle();
    expect(find.text('+500.00'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('taxi_records'), contains('"income":500.0'));

    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();

    expect(find.text('支出排行榜'), findsOneWidget);
    expect(find.textContaining('总支出 ¥130.00'), findsOneWidget);
    expect(find.text('油费 / 电费'), findsOneWidget);
    expect(find.text('车辆租金'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('常用功能'), findsOneWidget);
    expect(find.text('快速记账'), findsOneWidget);
    expect(find.text('账本统计'), findsOneWidget);
    expect(find.text('密码锁定'), findsOneWidget);
    expect(find.text('数据备份'), findsOneWidget);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('基本设置'), findsOneWidget);
    expect(find.text('登录账号'), findsOneWidget);
    expect(find.text('13800138000'), findsOneWidget);
    expect(find.text('修改登录密码'), findsOneWidget);
    expect(find.text('立即锁定'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('清空全部流水'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('清空全部流水'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('语言'), findsOneWidget);

    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Basic settings'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
    expect(find.text('基本设置'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.textContaining('会员'), findsNothing);
  });
}
