param(
    [string]$Godot = $env:GODOT,
    [switch]$Full,
    [switch]$Strawy,
    [string[]]$Only = @(),
    [string[]]$RenderedChecks = @(),
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
$executedChecks = @{}
$knownChecks = @{}
$validationResults = @()
$validationFailures = @()

function Invoke-Check([string]$Name, [string]$Script, [string[]]$UserArgs = @(), [switch]$Parse) {
    $knownChecks[$Name] = $true
    if ($Only.Count -and $Name -notin $Only) { return }
    $identity = $Script + '|' + ($UserArgs -join '|') + '|' + [bool]$Parse
    if ($executedChecks.ContainsKey($identity)) { return }
    $executedChecks[$identity] = $true
    # A distinct profile prevents tests from touching saves/settings/unlocks.
    # Fresh-process write/read pairs intentionally share only their own profile.
    $profileName = $Name -replace '-(write|read)$', ''
    $env:APPDATA = Join-Path $profileRoot "$profileName-appdata"
    $env:LOCALAPPDATA = Join-Path $profileRoot "$profileName-localappdata"
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $stdout = Join-Path $logRoot "$Name.log"
    $stderr = Join-Path $logRoot "$Name.err.log"
    $arguments = @('--path', ('"' + $projectRoot + '"'), '--audio-driver', 'Dummy')
    if ($Name -in $RenderedChecks) { $arguments += @('--rendering-method', 'gl_compatibility') }
    else { $arguments += '--headless' }
    if ($Parse) { $arguments += '--check-only' }
    $arguments += @('--script', $Script)
    if ($UserArgs.Count) { $arguments += '--'; $arguments += $UserArgs }
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    # Keep the process handle before a fast parse exits (Windows PowerShell 5).
    $null = $process.Handle
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
    $script:validationResults += [pscustomobject]@{name=$Name; script=$Script; args=$UserArgs; pass=(-not [bool]$failure); failure=$failure; stdout=$stdout; stderr=$stderr}
    if ($failure) {
        $script:validationFailures += "$Name failed: $failure. Inspect $stdout and $stderr"
        Write-Output "FAIL $Name ($failure)"
        return
    }
    Write-Output "PASS $Name"
}

try {
    Invoke-Check 'parse' 'res://scripts/ui/match_ui.gd' -Parse
    Invoke-Check 'core' 'res://tests/run_headless.gd'
    Invoke-Check 'runtime' 'res://tests/runtime_scene_smoke.gd'
    Invoke-Check 'menu-deal' 'res://tests/menu_deal_smoke.gd'
    Invoke-Check 'boss-debug-navigation' 'res://tests/boss_debug_navigation_smoke.gd'
    Invoke-Check 'card-interaction' 'res://tests/card_interaction_smoke.gd'
    Invoke-Check 'jukebox' 'res://tests/jukebox_scene_smoke.gd'
    Invoke-Check 'money-fast-forward' 'res://tests/money_fast_forward_smoke.gd'
    Invoke-Check 'boss-money-presence' 'res://tests/boss_money_presence_smoke.gd'
    Invoke-Check 'drink-presentation' 'res://tests/drink_presentation_smoke.gd'
    Invoke-Check 'boss-dog-monkey' 'res://tests/dog_monkey_presentation_smoke.gd'
    Invoke-Check 'music-transport' 'res://tests/music_transport_smoke.gd'
    Invoke-Check 'music-write' 'res://tests/music_resume_scene_smoke.gd'
    Invoke-Check 'music-read' 'res://tests/music_resume_scene_smoke.gd' @('--resume-only')
    Invoke-Check 'campaign' 'res://tests/campaign_overhaul_scene_smoke.gd'
    Invoke-Check 'campaign-demo' 'res://tests/campaign_overhaul_scene_smoke.gd' @('--tradatala-demo')
    Invoke-Check 'progression-write' 'res://tests/progression_scene_smoke.gd'
    Invoke-Check 'progression-read' 'res://tests/progression_scene_smoke.gd' @('--resume-only')
    Invoke-Check 'meta-debug-write' 'res://tests/meta_debug_scene_smoke.gd'
    Invoke-Check 'meta-debug-read' 'res://tests/meta_debug_scene_smoke.gd' @('--resume-only')
    if ($Strawy -or $Full -or $Only.Count) {
        foreach ($name in @('front_end', 'tutorial_scene', 'event_table_overhaul', 'misc_npc_scene', 'gieo_que_screen', 'drink_shop', 'drink_quick', 'zodiac_scene', 'strawy_scene', 'strawy_commands', 'strawy_moves_drinks', 'strawy_speech')) {
            Invoke-Check $name "res://tests/${name}_smoke.gd"
        }
        Invoke-Check 'strawy-settings-write' 'res://tests/strawy_settings_smoke.gd'
        Invoke-Check 'strawy-settings-read' 'res://tests/strawy_settings_smoke.gd' @('--resume-only')
    }
    if ($Full -or $Only.Count) {
        Invoke-Check 'zodiac-full-roster' 'res://tests/zodiac_full_roster_smoke.gd'
        Invoke-Check 'boss-roster-presentation' 'res://tests/roster_presentation_smoke.gd'
        foreach ($name in @('menu_release', 'money_hud_103', 'release_103_qol', 'tutorial_scene', 'resolve_scene', 'gieo_que_screen', 'drink_shop', 'event_table_overhaul', 'misc_npc_scene', 'relic_scene', 'resolve_presentation')) {
            Invoke-Check $name "res://tests/${name}_smoke.gd"
        }
        Invoke-Check 'demo' 'res://tests/demo_smoke.gd' @('--tradatala-demo')
        Invoke-Check 'shoe-write' 'res://tests/shoe_shine_resume_smoke.gd'
        Invoke-Check 'shoe-read' 'res://tests/shoe_shine_resume_smoke.gd' @('--read')
        Invoke-Check 'shoe-en' 'res://tests/shoe_shine_scene_smoke.gd'
        Invoke-Check 'shoe-vi' 'res://tests/shoe_shine_scene_smoke.gd' @('--vietnamese')
        Invoke-Check 'shoe-large-en' 'res://tests/shoe_shine_scene_smoke.gd' @('--large')
        Invoke-Check 'shoe-large-vi' 'res://tests/shoe_shine_scene_smoke.gd' @('--large', '--vietnamese')
        Invoke-Check 'fortune-write' 'res://tests/fortune_resume_smoke.gd'
        Invoke-Check 'fortune-read' 'res://tests/fortune_resume_smoke.gd' @('--resume-only')
        Invoke-Check 'readability' 'res://tests/text_readability_smoke.gd'
        Invoke-Check 'text-reveal' 'res://tests/text_reveal_scene_smoke.gd'
        Invoke-Check 'hang-rong-write' 'res://tests/hang_rong_resume_smoke.gd'
        Invoke-Check 'hang-rong-read' 'res://tests/hang_rong_resume_smoke.gd' @('--read')
        Invoke-Check 'hang-rong-en' 'res://tests/hang_rong_presentation_smoke.gd'
        Invoke-Check 'hang-rong-vi' 'res://tests/hang_rong_presentation_smoke.gd' @('--vietnamese')
        Invoke-Check 'hang-rong-large-en' 'res://tests/hang_rong_presentation_smoke.gd' @('--large')
        Invoke-Check 'hang-rong-large-vi' 'res://tests/hang_rong_presentation_smoke.gd' @('--large', '--vietnamese')
        Invoke-Check 'boss-presentation' 'res://tests/boss_presentation_smoke.gd'
        Invoke-Check 'cat-scene' 'res://tests/cat_persuasion_scene_smoke.gd'
        Invoke-Check 'cat-expansion' 'res://tests/cat_expansion_scene_smoke.gd'
        Invoke-Check 'rooster-scene' 'res://tests/rooster_persuasion_scene_smoke.gd'
        Invoke-Check 'rooster-write' 'res://tests/rooster_persuasion_resume_smoke.gd' @('--write')
        Invoke-Check 'rooster-read' 'res://tests/rooster_persuasion_resume_smoke.gd' @('--read')
        Invoke-Check 'cat-write' 'res://tests/cat_persuasion_resume_smoke.gd' @('--write')
        Invoke-Check 'cat-read' 'res://tests/cat_persuasion_resume_smoke.gd' @('--read')
        Invoke-Check 'negotiation' 'res://tests/zodiac_negotiation_tests.gd'
        Invoke-Check 'negotiation-write' 'res://tests/zodiac_negotiation_resume_smoke.gd' @('--write')
        Invoke-Check 'negotiation-read' 'res://tests/zodiac_negotiation_resume_smoke.gd' @('--read')
        Invoke-Check 'history'  'res://tests/endless_history_smoke.gd'
        foreach ($name in @('gameplay_music', 'music_director', 'music_arrangement', 'ost_loop_catalog')) {
            Invoke-Check $name "res://tools/${name}_smoke.gd"
        }
    }
    foreach ($requested in $Only) {
        if (-not $knownChecks.ContainsKey($requested)) { throw "Unknown validation check: $requested" }
    }
    if ($validationFailures.Count) { throw ($validationFailures -join [Environment]::NewLine) }
    Write-Output "VALIDATION PASS. Logs and isolated test profiles: $logRoot"
} finally {
    ConvertTo-Json -InputObject @($validationResults) -Depth 5 | Set-Content -LiteralPath (Join-Path $logRoot 'results.json') -Encoding utf8
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
