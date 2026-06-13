param(
    [Parameter(Mandatory = $true)]
    [string]$RunName
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$slug = ($RunName.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
$dateStamp = Get-Date -Format 'yyyy-MM-dd'
$runRoot = Join-Path $ScriptDir "..\data\runs\$dateStamp-$slug"

New-Item -ItemType Directory -Force -Path `
    $runRoot, `
    (Join-Path $runRoot 'raw'), `
    (Join-Path $runRoot 'reviewed'), `
    (Join-Path $runRoot 'final'), `
    (Join-Path $runRoot 'tmp') | Out-Null

$manifest = [ordered]@{
    run_name = $RunName
    slug = $slug
    created_at = (Get-Date).ToString('s')
    status = 'created'
    owner = 'Hermes'
    notes = 'Fill raw/candidates, review evidence, then merge approved rows.'
}

$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runRoot 'run-manifest.json')
Write-Output (Resolve-Path -LiteralPath $runRoot).Path
