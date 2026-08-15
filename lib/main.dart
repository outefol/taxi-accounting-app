import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_keys.dart';
import 'i18n.dart';
import 'password_store.dart';
import 'models/vehicle.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  appLanguage.value = preferences.getString(languageKey) ?? 'zh';
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

class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _StartupSnapshot {
  const _StartupSnapshot(this.preferences, this.hasPassword);

  final SharedPreferences preferences;
  final bool hasPassword;
}

class _AppStartPageState extends State<AppStartPage> {
  Future<_StartupSnapshot> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await VehicleStore.migrateLegacyData(preferences);
    final hasPassword = (await PasswordStore.read())?.isNotEmpty ?? false;
    return _StartupSnapshot(preferences, hasPassword);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupSnapshot>(
      future: _loadPreferences(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final preferences = snapshot.data!.preferences;
        final account = preferences.getString(accountKey);
        final vehicleNumber = preferences.getString(vehicleNumberKey);
        final loggedIn = preferences.getBool(loggedInKey) ?? false;
        final startupPassword =
            preferences.getBool(startupPasswordKey) ?? false;
        final hasPassword = snapshot.data!.hasPassword;
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
