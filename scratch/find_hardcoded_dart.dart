// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found.');
    return;
  }

  // Regexes to search for:
  // 1. Text('...') or Text("...")
  // 2. SnackBar(content: Text('...')) or SnackBar(content: Text("..."))
  // 3. hintText: '...' or hintText: "..."
  // 4. labelText: '...' or labelText: "..."
  // 5. title: Text('...') or title: Text("...")
  
  final regexes = [
    RegExp(r"Text\(\s*'([^']+)'"),
    RegExp(r'Text\(\s*"([^"]+)"'),
    RegExp(r"hintText:\s*'([^']+)'"),
    RegExp(r'hintText:\s*"([^"]+)"'),
    RegExp(r"labelText:\s*'([^']+)'"),
    RegExp(r'labelText:\s*"([^"]+)"'),
    RegExp(r"helperText:\s*'([^']+)'"),
    RegExp(r'helperText:\s*"([^"]+)"'),
    RegExp(r"errorText:\s*'([^']+)'"),
    RegExp(r'errorText:\s*"([^"]+)"'),
    RegExp(r"SnackBar\(\s*content:\s*Text\(\s*'([^']+)'"),
    RegExp(r'SnackBar\(\s*content:\s*Text\(\s*"([^"]+)"'),
  ];

  int totalMatches = 0;

  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Ignore generated files or localization files
      if (entity.path.contains('app_localizations') || entity.path.contains('.g.dart')) {
        return;
      }

      final content = entity.readAsStringSync();
      final lines = content.split('\n');
      bool printedHeader = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Skip imports and comments
        if (line.trim().startsWith('import') || line.trim().startsWith('//') || line.trim().startsWith('///')) {
          continue;
        }

        for (final regex in regexes) {
          final matches = regex.allMatches(line);
          for (final match in matches) {
            final str = match.group(1);
            if (str == null || str.isEmpty) continue;
            
            // Skip asset paths, keys, etc.
            if (str.startsWith('assets/') || str.endsWith('.png') || str.endsWith('.jpg') || str.endsWith('.jpeg') || str.endsWith('.svg')) {
              continue;
            }
            if (str.length < 2) continue; // Skip very short strings
            // Check if contains at least one letter
            if (!RegExp(r'[a-zA-Z]').hasMatch(str)) continue;

            if (!printedHeader) {
              print('\n--- File: ${entity.path} ---');
              printedHeader = true;
            }
            print('Line ${i + 1}: ${line.trim()}  ==>  Found: "$str"');
            totalMatches++;
          }
        }
      }
    }
  });

  print('\nTotal hardcoded strings found: $totalMatches');
}
