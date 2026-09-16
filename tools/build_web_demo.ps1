param(
    [string]$GodotExe = "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Test-Path -LiteralPath $GodotExe)) { throw 'Pass -GodotExe with the Godot 4.7.1 console executable.' }
$template = Join-Path $root 'build/demo-tools/web_nothreads_release.zip'
if (-not (Test-Path -LiteralPath $template)) {
    throw 'Place the official Godot 4.7.1 web_nothreads_release.zip in build/demo-tools. See docs/WEB_DEMO.md.'
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$output = Join-Path $root "build/web-demo-$stamp"
New-Item -ItemType Directory -Path $output | Out-Null
$previousAppdata = $env:APPDATA
$previousLocal = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $root '.godot/demo-appdata'
    $env:LOCALAPPDATA = Join-Path $root '.godot/demo-local'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    & $GodotExe --headless --path $root --editor --import --quit *> (Join-Path $output 'import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed; inspect import.log.' }
    & $GodotExe --headless --path $root --export-release 'Web Demo' (Join-Path $output 'index.html') *> (Join-Path $output 'export.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot export failed; inspect export.log.' }
    $errors = Select-String -LiteralPath (Join-Path $output 'import.log'),(Join-Path $output 'export.log') -Pattern 'SCRIPT ERROR:|ERROR:'
    if ($errors) { throw "Godot reported errors: $errors" }
    $files = @(Get-ChildItem -LiteralPath $output -File | Where-Object Extension -ne '.log')
    if (-not ($files.Name -ccontains 'index.html')) { throw 'Missing index.html.' }
    if ($files.Count -gt 1000) { throw 'itch.io file count limit exceeded.' }
    if (($files | Measure-Object Length -Sum).Sum -gt 500000000) { throw 'itch.io extracted size limit exceeded.' }
    foreach ($file in $files) {
        if ($file.Length -gt 200000000 -or $file.Name.Length -gt 240) { throw "itch.io file limit exceeded: $($file.Name)" }
    }
    $zipPath = Join-Path $root "build/TRADATALA-demo-itch-$stamp.zip"
    $archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $files) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $file.Name, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally { $archive.Dispose() }
    $check = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        if ($check.Entries.Count -ne $files.Count -or -not ($check.Entries.FullName -ccontains 'index.html')) { throw 'ZIP verification failed.' }
    } finally { $check.Dispose() }
    Get-FileHash -LiteralPath $zipPath -Algorithm SHA256 | Format-List
    Write-Output "ITCH_DEMO_PACKAGE: PASS $zipPath"
} finally {
    $env:APPDATA = $previousAppdata
    $env:LOCALAPPDATA = $previousLocal
}
