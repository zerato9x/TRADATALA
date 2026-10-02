param(
    [string]$Godot = "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
    [switch]$Rendered,
    [switch]$ResumeOnly,
    [switch]$Full
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$logRoot = Join-Path $projectRoot '.godot/negotiation-validation'
$profileRoot = Join-Path $logRoot ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $scripts = @('zodiac_negotiation_tests', 'zodiac_scene_smoke', 'cat_persuasion_scene_smoke')
    $resumeScripts = @('zodiac_negotiation_resume_smoke-write', 'zodiac_negotiation_resume_smoke-read', 'cat_persuasion_resume_smoke-write', 'cat_persuasion_resume_smoke-read')
    if ($ResumeOnly) { $scripts = $resumeScripts } else { $scripts += $resumeScripts }
    if ($Full) { $scripts += @('run_headless', 'runtime_scene_smoke', 'tutorial_scene_smoke', 'campaign_overhaul_scene_smoke', 'event_table_overhaul_smoke', 'gieo_que_screen_smoke', 'misc_npc_scene_smoke', 'zodiac_full_roster_smoke') }
    foreach ($script in $scripts) {
        $baseScript = $script -replace '-(write|read)$', ''
        $env:APPDATA = Join-Path $profileRoot "$baseScript-appdata"
        $env:LOCALAPPDATA = Join-Path $profileRoot "$baseScript-local"
        New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
        $stdout = Join-Path $logRoot "$script.log"
        $stderr = Join-Path $logRoot "$script.err.log"
        $arguments = @('--path', ('"' + $projectRoot + '"'), '--audio-driver', 'Dummy', '--rendering-method', 'gl_compatibility', '--script', "res://tests/$baseScript.gd")
        if (-not $Rendered -or $baseScript -in @('run_headless','zodiac_negotiation_tests','zodiac_negotiation_resume_smoke','cat_persuasion_resume_smoke')) { $arguments = @('--headless') + $arguments }
        if ($script -match '-(write|read)$') { $arguments += @('--', ('--' + $Matches[1])) }
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $deadline = [DateTime]::UtcNow.AddSeconds(120)
        while (-not $process.WaitForExit(250)) {
            if ([DateTime]::UtcNow -ge $deadline) { $process.Kill(); $process.WaitForExit(); throw "$script timed out" }
        }
        $code = $process.ExitCode
        $process.Dispose()
        $logs = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
        if ($code -ne 0 -or $logs -match '(?m)^(SCRIPT ERROR:|ERROR:|Parse Error:)') { throw "$script failed. Inspect $stdout and $stderr" }
        if ($logs -notmatch '(?m)^[A-Z][A-Z_0-9]*(?:\s|:).*(?:\bPASS\b|\bpassed\b|\b0 failures\b|\bfailures=0\b|\bfailed=0\b)') { throw "$script has no successful completion marker" }
        Write-Output "PASS $script"
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
