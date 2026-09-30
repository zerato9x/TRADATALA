param(
    [string]$Godot = $env:GODOT,
    [switch]$Full,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($Godot)) {
    $godotCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($godotCommand) { $Godot = $godotCommand.Source }
}
if (-not $Godot -or -not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    throw 'Pass -Godot with the path to a Godot 4.7.1 console executable, or set GODOT.'
}
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$logRoot = Join-Path $projectRoot '.godot/validation'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$profileRoot = Join-Path $logRoot ('profiles/' + [guid]::NewGuid().ToString('N'))
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA

function Invoke-Check([string]$Name, [string]$Script, [string[]]$UserArgs = @(), [switch]$Parse) {
    # A distinct profile prevents tests from touching saves/settings/unlocks.
    # The two fresh-process pairs intentionally share only their own profile.
    $profileName = $Name -replace '-(write|read)$', ''
    $env:APPDATA = Join-Path $profileRoot "$profileName-appdata"
    $env:LOCALAPPDATA = Join-Path $profileRoot "$profileName-localappdata"
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $stdout = Join-Path $logRoot "$Name.log"
    $stderr = Join-Path $logRoot "$Name.err.log"
    $arguments = @('--headless', '--path', ('"' + $projectRoot + '"'))
    if ($Parse) { $arguments += '--check-only' }
    $arguments += @('--script', $Script)
    if ($UserArgs.Count) { $arguments += '--'; $arguments += $UserArgs }
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $failure = ''
    while (-not $process.WaitForExit(250)) {
        $errors = if (Test-Path -LiteralPath $stderr) { Get-Content -LiteralPath $stderr -Raw } else { '' }
        if ($errors -match '(?m)^(SCRIPT ERROR:|ERROR:|Parse Error:)') {
            $failure = 'Godot logged an error before completing'
            break
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            $failure = "Timed out after $TimeoutSeconds seconds"
            break
        }
    }
    if ($failure) {
        if (-not $process.HasExited) { $process.Kill() }
        $process.WaitForExit()
    } else {
        $process.WaitForExit()
        $allOutput = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
        if ($process.ExitCode -ne 0) { $failure = "Exit code $($process.ExitCode)" }
        elseif ($allOutput -match '(?m)^(SCRIPT ERROR:|ERROR:|Parse Error:)') { $failure = 'Godot logged an error despite exit 0' }
        elseif (-not $Parse -and $allOutput -notmatch '(?m)^[A-Z][A-Z_0-9]*(?:\s|:).*(?:\bPASS\b|\bpassed\b|\b0 failures\b|\bfailures=0\b|\bfailed=0\b)') { $failure = 'No successful test completion marker' }
    }
    $process.Dispose()
    if ($failure) { throw "$Name failed: $failure. Inspect $stdout and $stderr" }
    Write-Output "PASS $Name"
}

try {
    Invoke-Check 'parse' 'res://scripts/ui/match_ui.gd' -Parse
    Invoke-Check 'core' 'res://tests/run_headless.gd'
    Invoke-Check 'runtime' 'res://tests/runtime_scene_smoke.gd'
    Invoke-Check 'jukebox' 'res://tests/jukebox_scene_smoke.gd'
    Invoke-Check 'money-fast-forward' 'res://tests/money_fast_forward_smoke.gd'
    Invoke-Check 'music-transport' 'res://tests/music_transport_smoke.gd'
    Invoke-Check 'music-write' 'res://tests/music_resume_scene_smoke.gd'
    Invoke-Check 'music-read' 'res://tests/music_resume_scene_smoke.gd' @('--resume-only')
    Invoke-Check 'campaign' 'res://tests/campaign_overhaul_scene_smoke.gd'
    Invoke-Check 'campaign-demo' 'res://tests/campaign_overhaul_scene_smoke.gd' @('--tradatala-demo')
    Invoke-Check 'progression-write' 'res://tests/progression_scene_smoke.gd'
    Invoke-Check 'progression-read' 'res://tests/progression_scene_smoke.gd' @('--resume-only')
    if ($Full) {
        foreach ($name in @('menu_release', 'money_hud_103', 'release_103_qol', 'tutorial_scene', 'resolve_scene', 'gieo_que_screen', 'drink_shop', 'event_table_overhaul', 'misc_npc_scene', 'relic_scene', 'resolve_presentation')) {
            Invoke-Check $name "res://tests/${name}_smoke.gd"
        }
        Invoke-Check 'history' 'res://tests/endless_history_smoke.gd'
        foreach ($name in @('gameplay_music', 'music_director', 'music_arrangement', 'ost_loop_catalog')) {
            Invoke-Check $name "res://tools/${name}_smoke.gd"
        }
    }
    Write-Output "VALIDATION PASS. Logs and isolated test profiles: $logRoot"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
