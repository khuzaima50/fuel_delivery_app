import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import '../../services/locale_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocaleService().locale.languageCode;
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() => _selectedLanguage = languageCode);
    await LocaleService().setLocale(languageCode);
    if (mounted) Navigator.of(context).pop(languageCode);
  }

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
          l10n.languageTitle,
          style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: LocaleService.supportedLanguages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = LocaleService.supportedLanguages[index];
          final isSelected = _selectedLanguage == lang['code'];

          return InkWell(
            onTap: () => _selectLanguage(lang['code']!),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF4D00) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Flag emoji
                  Text(
                    lang['flag']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        Text(
                          lang['code']!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4D00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
