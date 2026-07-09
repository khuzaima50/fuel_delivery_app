import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup_screen.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  final List<bool> _uploadedDocs = [false, false, false, false, false];

  bool get _allUploaded => _uploadedDocs.every((status) => status);

  Future<void> _onUpload(int index, {bool isCamera = false}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final file = File(image.path);
          final fileExt = image.name.split('.').last;
          final fileName = '${user.id}_doc_${index}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final filePath = '${user.id}/$fileName';

          await Supabase.instance.client.storage
              .from('driver_documents')
              .upload(filePath, file);
        }

        if (mounted) {
          setState(() {
            _uploadedDocs[index] = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.docVerificationAttached(index + 1)),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.docVerificationFailed}$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Document list — localized
    final List<Map<String, String>> documents = [
      {'title': l10n.docVerificationDriversLicense, 'subtitle': l10n.docVerificationDriversLicenseDesc},
      {'title': l10n.docVerificationCommercialLicense, 'subtitle': l10n.docVerificationCommercialLicenseDesc},
      {'title': l10n.docVerificationVehicleReg, 'subtitle': l10n.docVerificationVehicleRegDesc},
      {'title': l10n.docVerificationInsurance, 'subtitle': l10n.docVerificationInsuranceDesc},
      {'title': l10n.docVerificationBackground, 'subtitle': l10n.docVerificationBackgroundDesc},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.docVerificationTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.docVerificationDesc,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (int i = 0; i < documents.length; i++)
                    _buildDocumentCard(
                      i,
                      documents[i]['title']!,
                      documents[i]['subtitle']!,
                      l10n,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_allUploaded) {
                      final navigator = Navigator.of(context);

                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null) {
                          await Supabase.instance.client
                              .from('drivers')
                              .update({
                                'documents_submitted': true,
                                'updated_at': DateTime.now().toUtc().toIso8601String(),
                              })
                              .eq('id', user.id);
                        }
                      } catch (e) {
                        debugPrint('[Docs] Could not update documents_submitted flag: $e');
                      }

                      if (mounted) {
                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const ProfileSetupScreen(),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.docVerificationUploadAll),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.docVerificationCompleteReg,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(int index, String title, String subtitle, AppLocalizations l10n) {
    final isUploaded = _uploadedDocs[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUploaded
            ? Border.all(color: const Color(0xFFFF4D00), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFFF4D00) : const Color(0xFFF3F3F3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isUploaded
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(
                      (index + 1).toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: isUploaded ? null : () => _onUpload(index, isCamera: false),
                          icon: Icon(
                            isUploaded ? Icons.cloud_done : Icons.file_upload_outlined,
                            size: 18,
                          ),
                          label: Text(
                            isUploaded ? l10n.docVerificationUploaded : l10n.docVerificationUploadFile,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUploaded ? Colors.grey[200] : const Color(0xFFFF4D00),
                            foregroundColor: isUploaded ? Colors.grey[600] : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: isUploaded ? null : () => _onUpload(index, isCamera: true),
                      child: Container(
                        width: 48,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
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
}
