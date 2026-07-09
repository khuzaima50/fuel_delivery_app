import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          l10n.helpCenterTitle,
          style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helpCenterHowCanWeHelp,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
            ),
            const SizedBox(height: 24),
            _buildFAQItem(l10n.helpCenterQ1, l10n.helpCenterA1),
            const SizedBox(height: 16),
            _buildFAQItem(l10n.helpCenterQ2, l10n.helpCenterA2),
            const SizedBox(height: 16),
            _buildFAQItem(l10n.helpCenterQ3, l10n.helpCenterA3),
            const SizedBox(height: 48),
            Text(
              l10n.helpCenterStillNeedHelp,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.helpCenterContacting)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: Text(
                  l10n.helpCenterContactSupport,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1F1F1F)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
