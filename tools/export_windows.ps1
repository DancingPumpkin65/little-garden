param(
    [string]$GodotExe = (Join-Path $env:USERPROFILE '.local/share/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot 'dist'
$outputFile = Join-Path $outputDirectory 'A Little Interlude.exe'

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw 'Godot was not found. Pass its console executable with -GodotExe.'
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
Set-Content -LiteralPath (Join-Path $outputDirectory '.gdignore') -Value ''
& $GodotExe --headless --editor --path $projectRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Godot asset import failed.' }
& $GodotExe --headless --path $projectRoot --export-release 'Windows Desktop' $outputFile
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed. Check the matching Windows export templates are installed.' }

Get-Item -LiteralPath $outputFile | Select-Object FullName, Length
Get-FileHash -LiteralPath $outputFile -Algorithm SHA256
