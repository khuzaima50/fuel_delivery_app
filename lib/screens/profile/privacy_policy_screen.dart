import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          l10n.privacyPolicyTitle,
          style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.privacyPolicy1Title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.privacyPolicy1Body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.privacyPolicy2Title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.privacyPolicy2Body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.privacyPolicy3Title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.privacyPolicy3Body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.privacyPolicy4Title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.privacyPolicy4Body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.privacyPolicy5Title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.privacyPolicy5Body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
