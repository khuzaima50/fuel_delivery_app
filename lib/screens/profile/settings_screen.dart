import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'language_screen.dart';
import 'help_center_screen.dart';
import 'privacy_policy_screen.dart';
import '../../services/locale_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  
  String _driverName = "Loading...";
  String _driverId = "...";
  String? _profileImageUrl;
  bool _isUploading = false;
  String _currentLanguageCode = 'en';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _currentLanguageCode = prefs.getString('app_language') ?? 'en';
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('drivers')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && mounted) {
          setState(() {
            _driverName = profile['full_name'] ?? 'Driver';
            _driverId = user.id.substring(0, 8).toUpperCase();
            _profileImageUrl = profile['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching driver profile: $e");
    }
  }

  Future<void> _uploadProfilePicture() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final file = File(image.path);
      final fileExt = image.name.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload to Supabase Storage in the 'avatars' bucket
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, file);

      // Get public Url
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update Database
      await Supabase.instance.client
          .from('drivers')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      // Update State
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsProfileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.settingsProfileUploadFailed}$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                },
              ),
            ),
          ),
          title: Text(
            l10n.settingsTitle,
            style: const TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _uploadProfilePicture,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(
                              _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? _profileImageUrl!
                                  : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1974&auto=format&fit=crop',
                            ),
                            backgroundColor: const Color(0xFFEEEEEE),
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(color: Color(0xFFFF4D00)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4D00),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.settingsFuelDeliveryPartner,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'ID: #$_driverId',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Text(
                  l10n.settingsAppPreferences,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888888),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSettingItem(
                  icon: Icons.language,
                  title: l10n.settingsAppLanguage,
                  onTap: () async {
                    final newLang = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LanguageScreen(),
                      ),
                    );
                    if (newLang != null && newLang is String) {
                      setState(() {
                        _currentLanguageCode = newLang;
                      });
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocaleService.getLanguageName(_currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBDBDBD),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color(0xFFBDBDBD),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.settingsPushNotifications,
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _pushNotifications,
                      onChanged: (val) {
                        setState(() => _pushNotifications = val);
                        _updatePreference('push_notifications', val);
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFFFF4D00),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  l10n.settingsAccountSupport,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888888),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSettingItem(
                  icon: Icons.help_outline_rounded,
                  title: l10n.settingsHelpCenter,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                    );
                  },
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.shield_outlined,
                  title: l10n.settingsPrivacyPolicy,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                    );
                  },
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFFBDBDBD),
                  ),
                ),

                const SizedBox(height: 48),

                // Log Out Button
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0E0)),
                  ),
                  child: InkWell(
                    onTap: () async {
                      try {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settingsLogOutFailed)),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFFF4D4D),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.settingsLogOut,
                          style: const TextStyle(
                            color: Color(0xFFFF4D4D),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const FloatingBottomNavBar(currentIndex: 2),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8DD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF4D00), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
