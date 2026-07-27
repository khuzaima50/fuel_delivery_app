$libPath = "c:\Users\Khuzaima\Downloads\driver_fuel-main\driver_fuel-main\lib"

# Exclude generated files
$files = Get-ChildItem -Path $libPath -Filter "*.dart" -Recurse | Where-Object { $_.FullName -notmatch "app_localizations" }

foreach ($file in $files) {
    $lines = Get-Content $file.FullName
    $printedFile = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Skip import, comment, debugPrint
        if ($line.Trim().StartsWith("import") -or $line.Trim().StartsWith("//") -or $line.Contains("debugPrint")) {
            continue
        }
        
        # Look for Text( followed by single/double quote
        # title: '...', hintText: '...', labelText: '...'
        $hasText = $line.Contains("Text('") -or $line.Contains("Text(`"") -or 
                   $line.Contains("title: '") -or $line.Contains("title: `"") -or
                   $line.Contains("hintText: '") -or $line.Contains("hintText: `"") -or
                   $line.Contains("labelText: '") -or $line.Contains("labelText: `"") -or
                   $line.Contains("SnackBar(content: Text('") -or $line.Contains("SnackBar(content: Text(`"") -or
                   $line.Contains("label: const Text('") -or $line.Contains("label: Text('")
                   
        if ($hasText) {
            # Filter out lines that already use localization keys
            if (-not $line.Contains("AppLocalizations") -and -not $line.Contains("l10n.")) {
                if (-not $printedFile) {
                    Write-Host "`n--- FILE: $($file.FullName) ---" -ForegroundColor Yellow
                    $printedFile = $true
                }
                Write-Host "Line $($i + 1): $($line.Trim())"
            }
        }
    }
}
