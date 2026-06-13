param(
    [Parameter(Mandatory = $true)]
    [string]$OutputCsv,
    [Parameter(Mandatory = $true)]
    [string]$RunName
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$newRunScript = Join-Path $ScriptDir 'new-run.ps1'
$runRoot = powershell -ExecutionPolicy Bypass -File $newRunScript -RunName $RunName
$runRoot = $runRoot.Trim()

$outputPath = (Resolve-Path -LiteralPath $OutputCsv).Path
$rawDir = Join-Path $runRoot 'raw'
$rawTarget = Join-Path $rawDir ([System.IO.Path]::GetFileName($outputPath))
Copy-Item -LiteralPath $outputPath -Destination $rawTarget -Force

$manifestPath = Join-Path $runRoot 'run-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath | ConvertFrom-Json
$manifest.status = 'raw_staged'
$manifest.raw_files = @([System.IO.Path]::GetFileName($rawTarget))
$stagedAt = (Get-Date).ToString('s')
if ($manifest.PSObject.Properties.Name -contains 'staged_at') {
    $manifest.staged_at = $stagedAt
}
else {
    Add-Member -InputObject $manifest -NotePropertyName 'staged_at' -NotePropertyValue $stagedAt
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath

[pscustomobject]@{
    run_root = $runRoot
    raw_csv = $rawTarget
} | Format-List
