import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_keys.dart';
import '../i18n.dart';
import '../password_store.dart';
import '../models/vehicle.dart';
import 'home_page.dart';

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
    final savedVehicle = preferences.getString(vehicleNumberKey);
    final savedAccount = preferences.getString(accountKey);
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
    var savedPassword = await PasswordStore.read();
    if (savedPassword == null || savedPassword.isEmpty) {
      final newPassword = await _showPasswordSetupDialog();
      if (newPassword == null) {
        return;
      }
      await PasswordStore.write(newPassword);
      savedPassword = newPassword;
      // On first use there is no existing password to verify. The password
      // just created in the setup dialog is the credential for this login.
      password = newPassword;
    }
    final savedAccount = preferences.getString(accountKey);
    final accountMatches = savedAccount == null || savedAccount == account;
    if (accountMatches && password == savedPassword) {
      await preferences.setString(accountKey, account);
      await preferences.setString(vehicleNumberKey, vehicleNumber);
      await preferences.setBool(loggedInKey, true);
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
                            tooltip: _hidePassword
                                ? tr('showPassword')
                                : tr('hidePassword'),
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
