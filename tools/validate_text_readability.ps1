param(
    [string]$Godot = "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
    [switch]$Rendered,
    [string[]]$RenderChecks = @('readability'),
    [string[]]$Only = @(),
    [int]$TimeoutSeconds = 120
)
# Compatibility entry point: one runner owns isolation, deadlines and failure checks.
$names = [ordered]@{core='core'; readability='readability'; runtime='runtime'; tutorial='tutorial_scene'; front='front_end'; event='event_table_overhaul'; drinks='drink_shop'; quick_drinks='drink_quick'; relics='relic_scene'; gieo='gieo_que_screen'; zodiac='zodiac_scene'; cat='cat-scene'; resolve='resolve_presentation'; text_reveal='text-reveal'; strawy='strawy_moves_drinks'; boss='boss-presentation'; dog_monkey='boss-dog-monkey'; roster='boss-roster-presentation'}
$selected = @($names.Keys | Where-Object { -not $Only.Count -or $_ -in $Only } | ForEach-Object { $names[$_] })
foreach ($name in $Only) { if (-not $names.Contains($name)) { throw "Unknown text check: $name" } }
$renderedNames = @()
if ($Rendered) { $renderedNames = @($RenderChecks | ForEach-Object { $names[$_] }) }
& "$PSScriptRoot\validate_project.ps1" -Godot $Godot -Only $selected -RenderedChecks $renderedNames -TimeoutSeconds $TimeoutSeconds
