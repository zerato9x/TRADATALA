param(
    [string]$Godot = "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
    [switch]$Rendered,
    [switch]$ResumeOnly,
    [switch]$Full
)
# Compatibility entry point. Fresh-process pairs share one isolated profile per pair.
$checks = @('negotiation-write','negotiation-read','cat-write','cat-read')
if (-not $ResumeOnly) { $checks = @('negotiation','zodiac_scene','cat-scene') + $checks }
if ($Full) { $checks += @('core','runtime','tutorial_scene','campaign','event_table_overhaul','gieo_que_screen','misc_npc_scene','zodiac-full-roster') }
$renderedNames = @()
if ($Rendered) { $renderedNames = @('zodiac_scene','cat-scene','runtime','tutorial_scene','campaign','event_table_overhaul','gieo_que_screen','misc_npc_scene','zodiac-full-roster') }
& "$PSScriptRoot\validate_project.ps1" -Godot $Godot -Only $checks -RenderedChecks $renderedNames
