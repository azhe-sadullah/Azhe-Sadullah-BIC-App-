$files = Get-ChildItem "C:\Users\DELL\Desktop\BIC\BIC-App\bic\lib" -Recurse -Filter "*.dart"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ($content -match 'GoogleFonts\.cairo\(') {
        $newContent = $content -replace 'GoogleFonts\.cairo\(', 'GoogleFonts.readexPro('
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Updated: $($file.Name)"
    }
}
Write-Host "Done!"
