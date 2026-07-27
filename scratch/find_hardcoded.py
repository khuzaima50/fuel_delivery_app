import os
import re

lib_dir = r"c:\Users\Khuzaima\Downloads\driver_fuel-main\driver_fuel-main\lib"

# We want to find hardcoded strings. Specifically:
# 1. Text('...') or Text("...")
# 2. SnackBar(content: Text('...')) or SnackBar(content: Text("..."))
# 3. showSnackBar(SnackBar(content: Text('...')))
# 4. title: Text('...') etc.
# 5. Strings in buttons, labels, hints, etc.
# Let's search for any single/double quoted strings inside .dart files that might be user-facing.
# To be precise, we can search for patterns of string literals: '...' or "..." that contain alphabetical characters and are not:
# - package imports
# - asset paths (e.g. 'assets/...')
# - database keys (e.g. 'id', 'status', 'created_at', 'orders', etc.)
# - keys in Maps (e.g. ['status'] etc.)
# - debug prints or logs (e.g. debugPrint('...'))
# Let's write a regex that matches common flutter UI patterns:
# Text\((['"])(.*?)\1
# SnackBar\((?:content:\s*)?Text\((['"])(.*?)\2
# hintText:\s*(['"])(.*?)\4
# labelText:\s*(['"])(.*?)\5
# title:\s*(['"])(.*?)\6
# etc.

patterns = [
    r"Text\(\s*['\"](.*?)['\"]",
    r"title:\s*['\"](.*?)['\"]",
    r"hintText:\s*['\"](.*?)['\"]",
    r"labelText:\s*['\"](.*?)['\"]",
    r"helperText:\s*['\"](.*?)['\"]",
    r"errorText:\s*['\"](.*?)['\"]",
    r"SnackBar\(\s*content:\s*Text\(\s*['\"](.*?)['\"]",
    r"content:\s*Text\(\s*['\"](.*?)['\"]",
    r"TextButton\(\s*child:\s*Text\(\s*['\"](.*?)['\"]",
    r"ElevatedButton\(\s*child:\s*Text\(\s*['\"](.*?)['\"]",
    r"label:\s*const\s+Text\(\s*['\"](.*?)['\"]",
    r"label:\s*Text\(\s*['\"](.*?)['\"]",
]

compiled = [re.compile(p) for p in patterns]

found_count = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            
            printed_file = False
            for idx, line in enumerate(lines):
                # skip imports or generated files
                if line.strip().startswith('import ') or 'app_localizations' in filepath:
                    continue
                # check each pattern
                matches = []
                for p in compiled:
                    m = p.search(line)
                    if m:
                        matches.append(m.group(0))
                if matches:
                    if not printed_file:
                        print(f"\n--- FILE: {filepath} ---")
                        printed_file = True
                    print(f"Line {idx+1}: {line.strip()}  (Matches: {matches})")
                    found_count += 1

print(f"\nTotal matches: {found_count}")
