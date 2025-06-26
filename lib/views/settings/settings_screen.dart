import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_item.dart';
import 'data_migration_screen.dart';
import '../../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 5; // Settings tab selected
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _useMockData = false;
  String _currency = 'USD';
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _currency = prefs.getString('currency') ?? 'USD';
      _language = prefs.getString('language') ?? 'English';
      _useMockData = prefs.getBool('use_mock_data') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setBool('use_mock_data', _useMockData);
    await prefs.setString('currency', _currency);
    await prefs.setString('language', _language);
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'General',
            children: [
              SettingsItem(
                icon: Icons.language,
                title: 'Language',
                subtitle: _language,
                onTap: () {
                  _showLanguageDialog();
                },
              ),
              SettingsItem(
                icon: Icons.attach_money,
                title: 'Currency',
                subtitle: _currency,
                onTap: () {
                  _showCurrencyDialog();
                },
              ),
              SettingsItem(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    _saveSettings();
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () {
                  setState(() {
                    _darkModeEnabled = !_darkModeEnabled;
                  });
                  _saveSettings();
                },
              ),
              SettingsItem(
                icon: Icons.notifications,
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () {
                  setState(() {
                    _notificationsEnabled = !_notificationsEnabled;
                  });
                  _saveSettings();
                },
              ),
              SettingsItem(
                icon: Icons.developer_mode,
                title: 'Use Mock Data',
                subtitle: 'Enable for demo/testing',
                trailing: Switch(
                  value: _useMockData,
                  onChanged: (value) {
                    setState(() {
                      _useMockData = value;
                    });
                    _saveSettings();
                    DatabaseService.instance.useMockData = value;
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () {
                  setState(() {
                    _useMockData = !_useMockData;
                  });
                  _saveSettings();
                  DatabaseService.instance.useMockData = _useMockData;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Data & Privacy',
            children: [
              SettingsItem(
                icon: Icons.cloud_upload,
                title: 'Migrate to Cloud',
                subtitle: 'Transfer data to Firebase',
                onTap: () {
                  // Check if user is authenticated with Firebase
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataMigrationScreen(),
                      ),
                    );
                  } else {
                    // Show dialog to sign in first
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign In Required'),
                        content: const Text(
                          'You need to sign in with Firebase to migrate your data to the cloud.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              SettingsItem(
                icon: Icons.backup,
                title: 'Backup Data',
                subtitle: 'Last backup: Never',
                onTap: () {
                  // Backup data
                },
              ),
              SettingsItem(
                icon: Icons.restore,
                title: 'Restore Data',
                subtitle: 'Restore from backup',
                onTap: () {
                  // Restore data
                },
              ),
              SettingsItem(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Delete all your data',
                onTap: () {
                  _showClearDataDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'About',
            children: [
              SettingsItem(
                icon: Icons.info,
                title: 'App Version',
                subtitle: AppConstants.appVersion,
                onTap: () {},
              ),
              SettingsItem(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () {
                  // Navigate to terms of service
                },
              ),
              SettingsItem(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {
                  // Navigate to privacy policy
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {
                // Handle logout
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withAlpha((0.1 * 255).toInt()),
              child: const Icon(
                Icons.person,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'john.doe@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to profile edit screen
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.map((language) {
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: _language,
                  onChanged: (value) {
                    setState(() {
                      _language = value!;
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyDialog() {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: currencies.map((currency) {
                return RadioListTile<String>(
                  title: Text(currency),
                  value: currency,
                  groupValue: _currency,
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all data? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Clear all data
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }
}
