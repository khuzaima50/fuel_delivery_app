$libPath = "c:\Users\Khuzaima\Downloads\driver_fuel-main\driver_fuel-main\lib"
$oldImport = "package:flutter_gen/gen_l10n/app_localizations.dart"
$newImport = "package:fueldirect_app/l10n/app_localizations.dart"

Get-ChildItem -Path $libPath -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match [regex]::Escape($oldImport)) {
        $newContent = $content -replace [regex]::Escape($oldImport), $newImport
        Set-Content -Path $_.FullName -Value $newContent -NoNewline
        Write-Host "Updated: $($_.FullName)"
    }
}

Write-Host "Done."
