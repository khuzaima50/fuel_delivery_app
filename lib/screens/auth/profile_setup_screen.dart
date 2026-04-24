import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vehicle_info_screen.dart';

/// Step 2 of registration: Driver reviews their name & phone (pre-filled from
/// sign-up) and optionally adds a profile photo.
/// Saves avatar + marks is_profile_completed = true, then goes to VehicleInfoScreen.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _profileImageFile;
  String? _existingAvatarUrl;
  bool _isLoading = false;
  bool _isFetchingProfile = true;

  @override
  void initState() {
    super.initState();
    _prefillFromDB();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Pre-fill name & phone from drivers table ──────────────────────────────

  Future<void> _prefillFromDB() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('full_name, phone, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (driver != null && mounted) {
        _nameController.text = driver['full_name'] ?? '';
        _phoneController.text = driver['phone'] ?? '';
        setState(() {
          _existingAvatarUrl = driver['avatar_url']?.toString();
        });
      }
    } catch (e) {
      debugPrint('[Profile] Prefill error (non-fatal): $e');
    } finally {
      if (mounted) setState(() => _isFetchingProfile = false);
    }
  }

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Photo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFEDE6),
                child: Icon(Icons.camera_alt_outlined, color: Color(0xFFFF4D00)),
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFEDE6),
                child: Icon(Icons.photo_library_outlined, color: Color(0xFFFF4D00)),
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null && mounted) {
        setState(() => _profileImageFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated. Please log in again.');

      String? avatarUrl = _existingAvatarUrl;

      // 1. Upload profile photo if a new one was selected
      if (_profileImageFile != null) {
        final ext = _profileImageFile!.path.split('.').last.toLowerCase();
        final filePath = 'avatars/${user.id}/profile.$ext';

        await Supabase.instance.client.storage
            .from('driver_documents')
            .upload(
              filePath,
              _profileImageFile!,
              fileOptions: const FileOptions(upsert: true),
            );

        avatarUrl = Supabase.instance.client.storage
            .from('driver_documents')
            .getPublicUrl(filePath);

        debugPrint('[Profile] Avatar uploaded → $avatarUrl');
      }

      // 2. Upsert drivers table (handles the case where the signup trigger
      //    failed to create the row — upsert creates it if missing).
      final upsertData = <String, dynamic>{
        'id':                   user.id,
        'email':                user.email ?? '',
        'full_name':            _nameController.text.trim(),
        'phone':                _phoneController.text.trim(),
        'is_profile_completed': true,
        'status':               'offline',
        'updated_at':           DateTime.now().toUtc().toIso8601String(),
      };
      if (avatarUrl != null) upsertData['avatar_url'] = avatarUrl;

      try {
        await Supabase.instance.client
            .from('drivers')
            .upsert(upsertData, onConflict: 'id');
        debugPrint('[Profile] Driver profile upserted ✓');
      } catch (upsertErr) {
        // Surface the exact Supabase error for debugging
        debugPrint('[Profile] Upsert failed: $upsertErr');
        rethrow;
      }

      // 3. Navigate to Vehicle Info screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VehicleInfoScreen()),
        );
      }
    } catch (e) {
      debugPrint('[Profile] Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: _isFetchingProfile
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Header
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Review your details and add a profile photo so customers can identify you.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Profile Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickProfileImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 56,
                                backgroundColor: const Color(0xFFFFEDE6),
                                backgroundImage: _profileImageFile != null
                                    ? FileImage(_profileImageFile!) as ImageProvider
                                    : (_existingAvatarUrl != null
                                        ? NetworkImage(_existingAvatarUrl!)
                                        : null),
                                child: (_profileImageFile == null &&
                                        _existingAvatarUrl == null)
                                    ? const Icon(
                                        Icons.person_outline_rounded,
                                        size: 52,
                                        color: Color(0xFFFF4D00),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4D00),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Tap to add / change profile photo',
                          style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Full Name (pre-filled from signup)
                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          hint: 'e.g. Ahmed Khan',
                          icon: Icons.person_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (v.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Phone (pre-filled from signup)
                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hint: '+92 300 0000000',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (v.trim().length < 7) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 48),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4D00),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFFF4D00).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Save & Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F1F1F),
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFFF4D00), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4D00), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      );
}
