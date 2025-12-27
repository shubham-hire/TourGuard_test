import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/contact_model.dart';
import '../presentation/providers/auth_provider.dart';
import '../services/family_tracking_service.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';
import '../services/backend_service.dart';
import '../widgets/setting_tile.dart';
import 'my_incidents_screen.dart';
import '../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationTracking = true;
  bool _emergencyAlerts = true;
  bool _geofenceAlerts = true;
  bool _familyTracking = false;
  bool _shareLocation = false;

  late String _selectedLanguage;
  List<Contact> _emergencyContacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Defines a modern gradient for the header
  final LinearGradient _headerGradient = const LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocalizationService.getCurrentLanguage();
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    try {
      // Primary source: SharedPreferences (same as AuthProvider uses for SOS)
      final prefs = await SharedPreferences.getInstance();
      final contactsData = prefs.getStringList('emergency_contacts');
      
      if (contactsData != null && contactsData.isNotEmpty) {
        setState(() {
          _emergencyContacts = contactsData.map((e) {
            final Map<String, dynamic> decoded = jsonDecode(e);
            return Contact(
              id: decoded['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: decoded['name'] ?? '',
              phone: decoded['phone'] ?? '',
            );
          }).toList();
        });
        return;
      }
      
      // Fallback: Check Hive (legacy storage)
      final box = await Hive.openBox('userBox');
      final saved = box.get('emergencyContacts', defaultValue: []) as List<dynamic>;
      if (saved.isNotEmpty) {
        setState(() {
          _emergencyContacts = saved.map((e) {
            if (e is Map) {
              return Contact(
                id: e['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: e['name'] ?? '',
                phone: e['phone'] ?? '',
              );
            }
            return Contact(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: e.toString(),
              phone: e.toString(),
            );
          }).toList();
        });
        // Migrate to SharedPreferences
        await _syncContactsToSharedPreferences();
      }
    } catch (e) {
      print('[Settings] Error loading contacts: $e');
    }
  }
  
  Future<void> _syncContactsToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = _emergencyContacts
        .map((c) => jsonEncode({'id': c.id, 'name': c.name, 'phone': c.phone}))
        .toList();
    await prefs.setStringList('emergency_contacts', encodedList);
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.navyBlue),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Add Emergency Contact',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _addEmergencyContact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addEmergencyContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isNotEmpty && phone.isNotEmpty) {
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _emergencyContacts.add(Contact(
          id: localId,
          name: name,
          phone: phone,
        ));
      });
      // persist locally to SharedPreferences (same as AuthProvider)
      await _syncContactsToSharedPreferences();
      
      // Also persist to Hive for backup
      final box = Hive.box('userBox');
      final list = _emergencyContacts.map((c) => {'id': c.id, 'name': c.name, 'phone': c.phone}).toList();
      box.put('emergencyContacts', list);

      // Sync to backend (fire and forget)
      try {
        final token = await BackendService.getToken();
        final url = '${BackendService.baseUrl}/emergency-contacts';
        print('[EmergencyContact] Saving to: $url');
        print('[EmergencyContact] Token: ${token != null ? "Present" : "Missing"}');
        
        if (token == null) {
          print('[EmergencyContact] ⚠️ No auth token - contact will only be saved locally');
          return;
        }
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'relationship': 'Emergency',
            'isPrimary': _emergencyContacts.length == 1,
          }),
        );
        
        print('[EmergencyContact] Response status: ${response.statusCode}');
        print('[EmergencyContact] Response body: ${response.body}');
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          print('[EmergencyContact] ✅ Saved to database successfully!');
        } else {
          print('[EmergencyContact] ❌ Failed to save: ${response.statusCode}');
        }
      } catch (e) {
        print('[EmergencyContact] Backend sync failed: $e');
      }
    }
  }

  void _removeEmergencyContact(String id) async {
    setState(() {
      _emergencyContacts.removeWhere((contact) => contact.id == id);
    });
    
    // Sync to SharedPreferences
    await _syncContactsToSharedPreferences();
    
    // Also update Hive
    final box = Hive.box('userBox');
    final list = _emergencyContacts.map((c) => {'id': c.id, 'name': c.name, 'phone': c.phone}).toList();
    box.put('emergencyContacts', list);
    
    // Delete from backend database
    try {
      final token = await BackendService.getToken();
      final url = '${BackendService.baseUrl}/emergency-contacts/$id';
      print('[EmergencyContact] Deleting from: $url');
      print('[EmergencyContact] Token present: ${token != null ? "YES (${token.substring(0, 20)}...)" : "NO"}');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      print('[EmergencyContact] Delete response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[EmergencyContact] ✅ Deleted from database!');
      } else {
        print('[EmergencyContact] ❌ Delete failed: ${response.body}');
      }
    } catch (e) {
      print('[EmergencyContact] Backend delete failed: $e');
    }
  }

  Future<void> _handleFamilyTrackingToggle(bool value) async {
    if (!value) {
      setState(() {
        _familyTracking = false;
        _shareLocation = false;
      });
      await FamilyTrackingService.stop();
      return;
    }

    setState(() => _familyTracking = true);

    if (_emergencyContacts.isEmpty) {
      _showAddContactDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an emergency contact to share updates with your family')),
      );
      return;
    }

    if (_shareLocation) {
      await FamilyTrackingService.start();
      await _sendCurrentLocationToFamily();
    }
  }

  Future<void> _sendCurrentLocationToFamily() async {
    final phoneNumbers = _emergencyContacts
        .map((c) => c.phone.trim())
        .where((phone) => phone.isNotEmpty)
        .join(',');

    if (phoneNumbers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone numbers found for your family contacts')),
      );
      return;
    }

    try {
      final position = await LocationService.getCurrentLocation();
      final lat = position.latitude;
      final lng = position.longitude;
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final message =
          'Family Tracking enabled.\nCurrent location: $mapsUrl\nCoordinates: $lat, $lng\nTime: ${DateTime.now().toLocal()}';
      final smsUri = Uri.parse('sms:$phoneNumbers?body=${Uri.encodeComponent(message)}');
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared your current location via SMS')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share location: $e')),
      );
    }
  }

  Future<bool> _ensureFamilyContactsAvailable() async {
    if (_emergencyContacts.isNotEmpty) {
      return true;
    }
    _showAddContactDialog();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add at least one emergency contact to share your location')),
    );
    return false;
  }

  Future<void> _changeLanguage(String languageCode) async {
    await LocalizationService.setLanguage(languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern Silver AppBar
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
            ),
            backgroundColor: AppColors.navyBlue,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(gradient: _headerGradient),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.settings, size: 120, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                _buildSectionTitle('Safety & Monitoring'),
                _buildSettingsCard(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.location_on,
                      color: Colors.green,
                      title: tr('location_tracking'),
                      value: _locationTracking,
                      onChanged: (v) => setState(() => _locationTracking = v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.notifications_active,
                      color: Colors.redAccent,
                      title: tr('notifications'),
                      value: _emergencyAlerts,
                      onChanged: (v) => setState(() => _emergencyAlerts = v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.security,
                      color: Colors.orange,
                      title: 'Geofence Alerts',
                      value: _geofenceAlerts,
                      onChanged: (v) => setState(() => _geofenceAlerts = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Incident Reporting'),
                _buildSettingsCard(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history, color: Colors.purple),
                      ),
                      title: Text(tr('my_incident_reports'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(tr('view_and_track_reports'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyIncidentsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Family Tracking'),
                _buildSettingsCard(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.family_restroom,
                      color: Colors.blue,
                      title: tr('family_tracking'),
                      subtitle: 'Share live location with contacts',
                      value: _familyTracking,
                      onChanged: _handleFamilyTrackingToggle,
                    ),
                    if (_familyTracking) ...[
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.share_location,
                        color: Colors.teal,
                        title: tr('share_location_family'),
                        value: _shareLocation,
                        onChanged: (value) async {
                          if (value) {
                             if (!_familyTracking) return;
                             final hasContacts = await _ensureFamilyContactsAvailable();
                             if (!hasContacts) return;
                             setState(() => _shareLocation = true);
                             await FamilyTrackingService.start();
                             await _sendCurrentLocationToFamily();
                          } else {
                             setState(() => _shareLocation = false);
                             await FamilyTrackingService.stop();
                          }
                        },
                      ),
                    ],
                    _buildDivider(),
         
                    // Always show emergency contacts section
                    ListTile(
                      title: Text(tr('emergency_contacts'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.navyBlue),
                        onPressed: _showAddContactDialog,
                      ),
                    ),
                    ..._emergencyContacts.map((c) => ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 14,
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(c.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => _removeEmergencyContact(c.id),
                      ),
                    )).toList(),
                    if (_emergencyContacts.isEmpty)
                       const Padding(
                         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         child: Text('No contacts added yet', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                       ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Preferences'),
                _buildSettingsCard(
                  children: [
                    ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language, color: Colors.indigo),
                      ),
                      title: Text(tr('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        LocalizationService.getLanguageName(_selectedLanguage),
                         style: TextStyle(color: Colors.grey[600]),
                      ),
                      children: LocalizationService.getAvailableLanguages().map((code) {
                        return RadioListTile<String>(
                          title: Text(LocalizationService.getLanguageName(code)),
                          value: code,
                          activeColor: AppColors.navyBlue,
                          groupValue: _selectedLanguage,
                          onChanged: (val) {
                            if (val != null) _changeLanguage(val);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Logout Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showLogoutConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50], // Light red background
                      foregroundColor: Colors.red, // Red text
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout),
                        const SizedBox(width: 8),
                        Text(
                          tr('logout'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey[200], indent: 60);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.navyBlue,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(tr('logout')),
          content: Text(tr('logout_confirm_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('logged_out_successfully')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(tr('logout'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

