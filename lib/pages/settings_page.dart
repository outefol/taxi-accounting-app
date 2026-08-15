import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_keys.dart';
import '../i18n.dart';
import '../password_store.dart';
import '../models/vehicle.dart';

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
      _message(error.message?.toString() ?? tr('invalidVehicleNumber'));
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
      _message(tr('keepAtLeastOneVehicle'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('deleteVehicle')),
        content: Text(trf('deleteVehicleConfirm', {'number': vehicle.number})),
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
        _startupPassword = preferences.getBool(startupPasswordKey) ?? false;
      });
    }
  }

  Future<void> _setStartupPassword(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(startupPasswordKey, value);
    if (mounted) {
      setState(() => _startupPassword = value);
      _message(value ? tr('startupPasswordOn') : tr('startupPasswordOff'));
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
    await preferences.setString(languageKey, selected);
    appLanguage.value = selected;
  }

  Future<void> _editAccount() async {
    final controller = TextEditingController(text: _account);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('editAccount')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: tr('phoneEmail'),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim().toLowerCase() ?? '';
              final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(text);
              final isEmail = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(text);
              return isPhone || isEmail ? null : tr('invalidAccount');
            },
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
                Navigator.pop(context, controller.text.trim().toLowerCase());
              }
            },
            child: Text(tr('save')),
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
      _message(tr('accountUpdated'));
    }
  }

  Future<void> _editVehicleNumber() async {
    final controller = TextEditingController(text: _vehicleNumber);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('editVehicle')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: tr('vehicle'),
              hintText: tr('vehicleHint'),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr('enterVehicle');
              }
              return null;
            },
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
    if (value == null || !mounted) {
      return;
    }
    try {
      await widget.onVehicleNumberChanged(value);
    } on ArgumentError catch (error) {
      if (mounted) {
        _message(error.message?.toString() ?? tr('invalidVehicleNumber'));
      }
      return;
    }
    if (mounted) {
      setState(() => _vehicleNumber = value);
      await _loadVehicles();
      _message(tr('vehicleUpdated'));
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
    if (!mounted) {
      return;
    }
    final currentPassword = await PasswordStore.read();
    if (!mounted) {
      return;
    }
    if (currentPassword == null || currentPassword.isEmpty) {
      final password = await _promptNewPassword();
      if (password != null && mounted) {
        await PasswordStore.write(password);
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
        title: Text(tr('changePassword')),
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
                    value == currentPassword ? null : tr('wrongCurrentPassword'),
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
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    if (changed == true) {
      await PasswordStore.write(newController.text);
      if (mounted) {
        _message(tr('passwordChanged'));
      }
    }
    // The dialog route owns these fields until its exit animation completes.
  }

  Future<void> _clearRecords() async {
    final savedPassword = await PasswordStore.read();
    if (!mounted) {
      return;
    }
    if (savedPassword == null || savedPassword.isEmpty) {
      _message(tr('setPasswordHint'));
      return;
    }
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final passwordVerified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('verifyPasswordToClear')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tr('loginPassword'),
              hintText: tr('enterLoginPassword'),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != savedPassword) {
                return tr('wrongPasswordCannotClear');
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(tr('nextStep')),
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
        title: Text(tr('clearAllRecordsTitle')),
        content: Text(tr('clearAllRecordsWarning')),
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
            child: Text(tr('confirmClear')),
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
      _message(tr('recordsCleared'));
    }
  }

  void _showAbout() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    showAboutDialog(
      context: context,
      applicationName: tr('appTitle'),
      applicationVersion:
          '${packageInfo.version} (Build ${packageInfo.buildNumber})',
      applicationIcon: const Icon(
        Icons.local_taxi,
        size: 48,
        color: Color(0xFFFFBE4F),
      ),
      children: [Text(tr('aboutDescription'))],
    );
  }

  Future<void> _lockApp() async {
    final savedPassword = await PasswordStore.read();
    if (savedPassword == null || savedPassword.isEmpty) {
      _message(tr('setPasswordHint'));
      return;
    }
    if (!mounted) {
      return;
    }
    // 返回主页面，然后弹出全屏锁屏页；输入正确密码后才能回到主页面。
    Navigator.of(context).pop();
    appNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const LockScreenPage()),
    );
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
                  trailing: Text(
                    trf('recordCountLine', {'count': '$_recordCount'}),
                  ),
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

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _checking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = tr('invalidLogin'));
      return;
    }
    setState(() {
      _checking = true;
      _errorMessage = null;
    });
    final savedPassword = await PasswordStore.read();
    final unlocked = savedPassword != null &&
        savedPassword.isNotEmpty &&
        password == savedPassword;
    if (!mounted) {
      return;
    }
    if (unlocked) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _checking = false;
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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Color(0xFFFFBE4F),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('appTitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(tr('password')),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        autofocus: true,
                        obscureText: _hidePassword,
                        enabled: !_checking,
                        decoration: InputDecoration(
                          labelText: tr('password'),
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
                        onSubmitted: (_) => _unlock(),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _checking ? null : _unlock,
                          child: Text(tr('login')),
                        ),
                      ),
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
