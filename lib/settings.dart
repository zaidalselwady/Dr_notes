import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool hidePercentage = true;
  String savedFormat = ""; // Default format

  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.init(); // ensure SharedPreferences is ready
    setState(() {
      hidePercentage = _settings.getBool(AppSettingsKeys.hidePercentage);
      savedFormat = _settings.getString(AppSettingsKeys.dateFormat);
    });
  }

  void _updateSetting(String key, value) {
    if (value is bool) {
      _settings.setBool(key, value);
    } else if (value is String) {
      _settings.setString(key, value);
    }
    setState(() {
      switch (key) {
        case AppSettingsKeys.hidePercentage:
          hidePercentage = value;
          break;

        case AppSettingsKeys.dateFormat:
          savedFormat = value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SettingTile(
            title: 'Hide Percentage ',
            value: hidePercentage,
            onChanged: (val) =>
                _updateSetting(AppSettingsKeys.hidePercentage, val),
          ),
          // DateFormatSetting(
          //   currentFormat: savedFormat,
          //   onChanged: (val) async {
          //     _updateSetting(AppSettingsKeys.dateFormat, val);
          //   },
          // ),
        ],
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class DateFormatSetting extends StatelessWidget {
  final String currentFormat;
  final Function(String) onChanged;

  const DateFormatSetting({
    super.key,
    required this.currentFormat,
    required this.onChanged,
  });

  final List<String> formats = const [
    "dd-MM-yyyy", // 01/12/2025
    "yyyy-MM-dd", // 2025-12-01
    "MM/dd/yyyy", // 12/01/2025
    "d MMM yyyy", // 1 Dec 2025
    "EEE, d MMM", // Mon, 1 Dec
  ];

  @override
  Widget build(BuildContext context) {
    // نحدد القيمة المختارة
    final String? selected =
        (currentFormat.isNotEmpty && formats.contains(currentFormat))
            ? currentFormat
            : null; // إذا مش موجودة بيطلع الـ dropdown فاضي

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        labelText: "Date Format",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: formats.map((format) {
        return DropdownMenuItem(
          value: format,
          child: Text(format),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class AppSettingsKeys {
  static const hidePercentage = 'hide_percentage';
  static const dateFormat = 'date_format';
}

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
}
