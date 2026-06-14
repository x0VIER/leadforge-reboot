param(
    [string]$OutputJson,
    [string]$OutputMarkdown
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..')
$statusDir = Join-Path $root 'agent_shared\status'
$runsRoot = Join-Path $root 'data\runs'
$masterCsv = Join-Path $root 'data\master_leads.csv'
$pendingQueuePath = Join-Path $statusDir 'PENDING_ENRICHMENT_QUEUE.json'

if (-not $OutputJson) {
    $OutputJson = Join-Path $statusDir 'FACTORY_METRICS.json'
}
if (-not $OutputMarkdown) {
    $OutputMarkdown = Join-Path $statusDir 'FACTORY_METRICS.md'
}

function Read-JsonFile($path) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

$masterRows = if (Test-Path -LiteralPath $masterCsv) { @(Import-Csv -LiteralPath $masterCsv) } else { @() }
$pendingQueue = Read-JsonFile $pendingQueuePath
$pendingRows = if ($pendingQueue) { @($pendingQueue.items) } else { @() }
$manifestRows = @()

function Get-IntValue($value) {
    if ($null -eq $value -or $value -eq '') { return 0 }
    try {
        return [int]$value
    }
    catch {
        return 0
    }
}

if (Test-Path -LiteralPath $runsRoot) {
    $manifestRows = @(Get-ChildItem -LiteralPath $runsRoot -Recurse -File -Filter run-manifest.json | ForEach-Object {
        $manifest = Read-JsonFile $_.FullName
        if ($manifest) {
            [pscustomobject]@{
                run_name = $manifest.run_name
                status = $manifest.status
                created_at = $manifest.created_at
                raw_rows = Get-IntValue $manifest.raw_rows
                reviewed_rows = Get-IntValue $manifest.reviewed_rows
                merged_rows = Get-IntValue $manifest.merged_rows
                pending_rows = Get-IntValue $manifest.pending_rows
                rejected_rows = Get-IntValue $manifest.rejected_rows
            }
        }
    })
}

$byState = @(
    $masterRows |
        Group-Object state |
        Sort-Object Count -Descending |
        ForEach-Object {
            [pscustomobject]@{
                state = $_.Name
                rows = $_.Count
            }
        }
)

$byNiche = @(
    $masterRows |
        Group-Object niche |
        Sort-Object Count -Descending |
        ForEach-Object {
            [pscustomobject]@{
                niche = $_.Name
                rows = $_.Count
            }
        }
)

$pendingByReason = @(
    $pendingRows |
        Group-Object triage_reason |
        Sort-Object Count -Descending |
        Select-Object -First 20 |
        ForEach-Object {
            [pscustomobject]@{
                reason = $_.Name
                rows = $_.Count
            }
        }
)

$recentRuns = @(
    $manifestRows |
        Sort-Object created_at -Descending |
        Select-Object -First 12
)

$payload = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    master_rows = $masterRows.Count
    states_covered = @($masterRows.state | Where-Object { $_ } | Sort-Object -Unique).Count
    niches_covered = @($masterRows.niche | Where-Object { $_ } | Sort-Object -Unique).Count
    pending_rows = $pendingRows.Count
    run_count = $manifestRows.Count
    total_raw_rows = ($manifestRows | Measure-Object raw_rows -Sum).Sum
    total_reviewed_rows = ($manifestRows | Measure-Object reviewed_rows -Sum).Sum
    total_merged_rows = ($manifestRows | Measure-Object merged_rows -Sum).Sum
    total_rejected_rows = ($manifestRows | Measure-Object rejected_rows -Sum).Sum
    total_pending_rows_from_manifests = ($manifestRows | Measure-Object pending_rows -Sum).Sum
    by_state = @($byState)
    by_niche = @($byNiche)
    pending_by_reason = @($pendingByReason)
    recent_runs = @($recentRuns)
}

New-Item -ItemType Directory -Force -Path $statusDir | Out-Null
$payload | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $OutputJson

$md = @(
    "# LeadForge Factory Metrics",
    "",
    "- Generated: $($payload.generated_at)",
    "- Master rows: $($payload.master_rows)",
    "- States covered: $($payload.states_covered)",
    "- Niches covered: $($payload.niches_covered)",
    "- Pending rows: $($payload.pending_rows)",
    "- Runs tracked: $($payload.run_count)",
    "- Raw rows staged: $($payload.total_raw_rows)",
    "- Reviewed rows: $($payload.total_reviewed_rows)",
    "- Merged rows: $($payload.total_merged_rows)",
    "- Rejected rows: $($payload.total_rejected_rows)"
)
$md | Set-Content -LiteralPath $OutputMarkdown

[pscustomobject]$payload | Format-List
