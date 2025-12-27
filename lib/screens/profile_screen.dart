import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import '../services/localization_service.dart';
import '../presentation/providers/auth_provider.dart';
import '../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return _buildProfile();
      },
    );
  }

  Future<String?> _getBlockchainHashId() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null && user.blockchainHashId != null && user.blockchainHashId!.isNotEmpty) {
        return user.blockchainHashId;
      }
      
      if (Hive.isBoxOpen('userBox')) {
        final box = Hive.box('userBox');
        final userData = box.get('currentUser');
        if (userData != null && userData['blockchainHashId'] != null) {
          return userData['blockchainHashId'];
        }
      }
      
      if (Hive.isBoxOpen('blockchainBox')) {
        final blockchainBox = Hive.box('blockchainBox');
        final hashes = blockchainBox.get('localHashes') as List?;
        if (hashes != null && hashes.isNotEmpty) {
          final lastHash = hashes.last as Map?;
          if (lastHash != null) {
            return lastHash['hashId'] ?? lastHash['hash_id'];
          }
        }
      }
      
      return 'Not registered on blockchain yet';
    } catch (e) {
      return 'Error loading hash: $e';
    }
  }

  Widget _buildProfile() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceWhite,
        body: Center(
          child: Text('No user data found. Please login.',
              style: TextStyle(color: Colors.grey[700], fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft grey background for contrast
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Navy Curved Header
            _buildHeader(user),

            // Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   const SizedBox(height: 20),
                   
                   // Blockchain Identity Card (Premium Look)
                   _buildBlockchainCard(),

                   const SizedBox(height: 20),

                   // Personal Info Card
                   _buildPersonalInfoCard(user),

                   const SizedBox(height: 20),

                   // Emergency Contacts
                   _buildEmergencyContactsCard(authProvider),

                   const SizedBox(height: 120), // Bottom padding increased for navbar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... imports remain the same

  // Helper for Tiranga Gradient
  LinearGradient get _tirangaGradient => const LinearGradient(
    colors: [
      Color(0xFFFF9933), // Saffron
      Colors.white,
      Color(0xFF138808), // India Green
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            child: Column(
              children: [
                // Top Row: Title & Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('profile'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                        onPressed: () => context.push('/settings'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // User Profile Info
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Tiranga border for avatar
                        gradient: const LinearGradient(
                           colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: AppColors.navyBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.verified, color: AppColors.saffron, size: 16),
                         const SizedBox(width: 4),
                         Text(
                          'Verified Traveler',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                         ),
                       ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom Tiranga Strip
          // ClipRRect(
          //   borderRadius: const BorderRadius.only(
          //      bottomLeft: Radius.circular(32),
          //      bottomRight: Radius.circular(32),
          //   ),
          //   child: Container(
          //     height: 6,
          //     width: double.infinity,
          //     decoration: BoxDecoration(
          //       gradient: _tirangaGradient,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildBlockchainCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, const Color(0xFF4B0082)], // Deep purple/indigo
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.security,
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.link_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Blockchain Identity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: FutureBuilder<String?>(
                    future: _getBlockchainHashId(),
                    builder: (context, snapshot) {
                      final hashId = snapshot.data;
                      
                      if (hashId == null || hashId == 'Not registered on blockchain yet' || hashId.startsWith('Error')) {
                        return InkWell(
                          onTap: () => _syncIdentity(),
                          child: Row(
                            children: [
                              const Text(
                                'Tap to Sync Identity',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13, 
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.refresh, color: AppColors.saffron, size: 18),
                            ],
                          ),
                        );
                      }
                      
                      return Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(
                              'HASH ID',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hashId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                         ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     Text(
                       'Secured by Ethereum',
                       style: TextStyle(
                         color: Colors.white.withOpacity(0.6),
                         fontSize: 11,
                       ),
                     ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(user) {
    return Container(
      decoration: BoxDecoration(
        gradient: _tirangaGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3), // Width of the tricolor border
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, color: AppColors.navyBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Personal Details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(tr('email'), user.email, Icons.email_outlined),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            _buildDetailRow(tr('phone'), user.phone, Icons.phone_outlined),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            _buildDetailRow(tr('country'), user.nationality ?? 'India', Icons.public),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
             _buildDetailRow('User ID', user.id, Icons.badge_outlined, isMonospace: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.navyBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: _tirangaGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sos_rounded, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr('emergency_contacts'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showAddContactDialog(context),
                  icon: const Icon(Icons.add_circle, color: AppColors.saffron, size: 28),
                  tooltip: 'Add Contact',
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (authProvider.emergencyContacts.isEmpty)
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 alignment: Alignment.center,
                 child: Column(
                   children: [
                     Icon(Icons.contact_phone_outlined, size: 40, color: Colors.grey[300]),
                     const SizedBox(height: 8),
                     Text(
                       'No contacts added yet',
                       style: TextStyle(color: Colors.grey[500], fontSize: 13),
                     ),
                   ],
                 ),
               )
            else
              ...authProvider.emergencyContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            Text(
                              contact['phone'] ?? '',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                          ],
                        ),
                        const Icon(Icons.phone_in_talk, color: Colors.green, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncIdentity() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing with blockchain...')),
    );
    
    final success = await authProvider.syncBlockchainIdentity();
    
    if (context.mounted) {
      if (success) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity verified on blockchain!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Safe Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                 labelText: 'Name (e.g. Mom)',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                 labelText: 'Phone Number',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
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
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                Provider.of<AuthProvider>(context, listen: false)
                    .addEmergencyContact(nameController.text, phoneController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }
}
