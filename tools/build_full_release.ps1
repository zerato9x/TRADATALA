param(
    [string]$GodotExe = "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
    [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Test-Path -LiteralPath $GodotExe)) { throw 'Pass -GodotExe with the Godot 4.7.1 console executable.' }
if (-not (Test-Path -LiteralPath (Join-Path $root 'build/demo-tools/web_nothreads_release.zip'))) {
    throw 'Install the official Godot 4.7.1 no-threads web release template at build/demo-tools/web_nothreads_release.zip.'
}
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root ("build/full-release-" + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'Use a new output directory to preserve existing release artifacts.' }
$versionLine = Get-Content -LiteralPath (Join-Path $root 'project.godot') | Where-Object { $_ -match '^config/version=' }
$version = ($versionLine -split '"')[1]
$sourceCommit = (& git -C $root rev-parse HEAD).Trim()
$sourceDirty = [bool](& git -C $root status --porcelain)
$previousAppdata = $env:APPDATA
$previousLocal = $env:LOCALAPPDATA
$templateSource = Join-Path $previousAppdata 'Godot/export_templates/4.7.1.stable'
try {
    $env:APPDATA = Join-Path $root '.godot/full-release/appdata'
    $env:LOCALAPPDATA = Join-Path $root '.godot/full-release/local'
    $templateTarget = Join-Path $env:APPDATA 'Godot/export_templates/4.7.1.stable'
    New-Item -ItemType Directory -Force -Path $templateTarget,$env:LOCALAPPDATA,(Join-Path $output 'logs'),(Join-Path $output 'web'),(Join-Path $output 'windows') | Out-Null
    foreach ($name in @('windows_release_x86_64.exe','version.txt')) {
        Copy-Item -LiteralPath (Join-Path $templateSource $name) -Destination (Join-Path $templateTarget $name) -Force
    }
    $jobs = @(
        @{name='import';args=@('--headless','--path',$root,'--editor','--import','--quit')},
        @{name='web-export';args=@('--headless','--path',$root,'--export-release','Web Full Release',(Join-Path $output 'web/index.html'))},
        @{name='windows-export';args=@('--headless','--path',$root,'--export-release','Windows Desktop',(Join-Path $output "windows/TRADATALA-v$version.exe"))}
    )
    foreach ($job in $jobs) {
        $log = Join-Path $output ("logs/" + $job.name + '.log')
        & $GodotExe @($job.args) *> $log
        if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:')) { throw "Godot $($job.name) failed; inspect $log." }
        Write-Output "$($job.name): PASS"
    }
    $artifacts = @()
    foreach ($platform in @('web','windows')) {
        $files = @(Get-ChildItem -LiteralPath (Join-Path $output $platform) -File | Where-Object { $_.Extension -notin @('.log','.import') -and $_.Name -notlike '*.console.exe' })
        if ($platform -eq 'web') {
            if (-not ($files.Name -ccontains 'index.html')) { throw 'Web entry point missing.' }
            if ($files.Count -gt 1000 -or ($files | Measure-Object Length -Sum).Sum -gt 500000000) { throw 'Web archive exceeds itch.io limits.' }
            foreach ($file in $files) { if ($file.Length -gt 200000000 -or $file.Name.Length -gt 240) { throw "Web file exceeds itch.io limits: $($file.Name)." } }
        } elseif (-not ($files.Name -contains "TRADATALA-v$version.exe") -or -not ($files.Name -contains "TRADATALA-v$version.pck")) { throw 'Windows executable or pack missing.' }
        $zip = Join-Path $output "TRADATALA-v$version-$platform-itch.zip"
        $archive = [IO.Compression.ZipFile]::Open($zip,[IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($file in $files) { [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,$file.Name,[IO.Compression.CompressionLevel]::Optimal) | Out-Null }
        } finally { $archive.Dispose() }
        $check = [IO.Compression.ZipFile]::OpenRead($zip)
        try { if ($check.Entries.Count -ne $files.Count) { throw 'ZIP entry count mismatch.' } } finally { $check.Dispose() }
        $artifacts += [pscustomobject]@{platform=$platform;file=[IO.Path]::GetFileName($zip);sha256=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash;bytes=(Get-Item -LiteralPath $zip).Length;extractedBytes=($files | Measure-Object Length -Sum).Sum;entries=@($files.Name)}
        Write-Output "PACKAGE: PASS $zip"
    }
    [pscustomobject]@{version=$version;sourceCommit=$sourceCommit;sourceDirty=$sourceDirty;builtAt=(Get-Date -Format o);artifacts=$artifacts} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'manifest.json') -Encoding utf8
} finally {
    $env:APPDATA = $previousAppdata
    $env:LOCALAPPDATA = $previousLocal
}
