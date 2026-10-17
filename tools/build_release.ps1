param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $godotCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($godotCommand) { $GodotPath = $godotCommand.Source }
    else { $GodotPath = Get-Process '*godot*' -ErrorAction SilentlyContinue | Where-Object Path | Select-Object -First 1 -ExpandProperty Path }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    throw 'Informe -GodotPath com o executável do Godot 4.6.3.'
}
$buildRoot = Join-Path $projectRoot ('builds/release-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $buildRoot | Out-Null
[IO.File]::WriteAllText((Join-Path $projectRoot 'builds/.gdignore'), '')

function Invoke-ReleaseGodot([string[]]$Arguments, [string]$Log, [string]$Root = $projectRoot) {
    $quotedArgs = @('--headless', '--path', ('"' + $Root + '"'), '--log-file', ('"' + $Log + '"')) + $Arguments
    $process = Start-Process -FilePath $GodotPath -WorkingDirectory $Root -ArgumentList $quotedArgs -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $Log -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) {
        Get-Content -LiteralPath $Log -Tail 45
        throw "Falha na build; veja $Log"
    }
}

Invoke-ReleaseGodot -Arguments @('--editor', '--import') -Log (Join-Path $buildRoot 'import.log')
foreach ($target in @('Web', 'Windows')) {
    $targetDir = Join-Path $buildRoot $target.ToLowerInvariant()
    New-Item -ItemType Directory -Path $targetDir | Out-Null
    $entry = if ($target -eq 'Web') { 'index.html' } else { 'Folchess.exe' }
    $outputPath = Join-Path $targetDir $entry
    Invoke-ReleaseGodot -Arguments @('--export-release', $target, ('"' + $outputPath + '"')) -Log (Join-Path $buildRoot ($target.ToLowerInvariant() + '-export.log'))
    if (-not (Test-Path -LiteralPath $outputPath)) { throw "Exportação não gerou $entry" }
    $packPath = Join-Path $targetDir $(if ($target -eq 'Web') { 'index.pck' } else { 'Folchess.pck' })
    $smokeScript = Join-Path $projectRoot 'tests/release_smoke.gd'
    Invoke-ReleaseGodot -Root $targetDir -Arguments @('--main-pack', ('"' + $packPath + '"'), '--script', ('"' + $smokeScript + '"')) -Log (Join-Path $buildRoot ($target.ToLowerInvariant() + '-test.log'))
    if ($target -eq 'Windows') {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'release-readme.txt') -Destination (Join-Path $targetDir 'LEIA-ME.txt')
    }
    $zipPath = Join-Path $buildRoot ('folchess-' + $target.ToLowerInvariant() + '.zip')
    Compress-Archive -Path (Join-Path $targetDir '*') -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Output "Pronto: $zipPath"
}
Get-ChildItem -LiteralPath $buildRoot -Filter '*.zip' | Get-FileHash -Algorithm SHA256 |
    ForEach-Object { '{0}  {1}' -f $_.Hash, (Split-Path $_.Path -Leaf) } |
    Set-Content -LiteralPath (Join-Path $buildRoot 'SHA256SUMS.txt')
Write-Output "Pacotes de publicação: $buildRoot"
