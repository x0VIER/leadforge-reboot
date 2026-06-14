param(
    [string]$OutputJson,
    [string]$OutputMarkdown
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..')
$statusDir = Join-Path $root 'agent_shared\status'
$runsRoot = Join-Path $root 'data\runs'
$masterCsv = Join-Path $root 'data\master_leads.csv'
$activityLog = Join-Path $root 'agent_shared\shared_activity_log.md'
$quarantineDir = Join-Path $root 'data\quarantine'

if (-not $OutputJson) {
    $OutputJson = Join-Path $statusDir 'OPS_HEALTH_REPORT.json'
}
if (-not $OutputMarkdown) {
    $OutputMarkdown = Join-Path $statusDir 'OPS_HEALTH_REPORT.md'
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

function Normalize-Key($row) {
    @(
        ([string]$row.business_name).Trim().ToLower(),
        ([string]$row.city).Trim().ToLower(),
        ([string]$row.state).Trim().ToLower(),
        ([string]$row.website).Trim().ToLower()
    ) -join '|'
}

$guardJson = & (Join-Path $ScriptDir 'get-collector-guard-status.ps1')
$guard = $guardJson | ConvertFrom-Json
$opsSnapshot = Read-JsonFile (Join-Path $statusDir 'OPS_SNAPSHOT.json')
$currentStatus = Read-JsonFile (Join-Path $statusDir 'CURRENT_STATUS.json')
$sourceConfig = Read-JsonFile (Join-Path $root 'config\source-lanes.json')
$masterRows = if (Test-Path -LiteralPath $masterCsv) { @(Import-Csv -LiteralPath $masterCsv) } else { @() }
$targetState = if ($sourceConfig -and $sourceConfig.targetState) { $sourceConfig.targetState.ToString().ToUpper() } else { 'FL' }

$runManifests = @()
if (Test-Path -LiteralPath $runsRoot) {
    $runManifests = @(Get-ChildItem -LiteralPath $runsRoot -Recurse -File -Filter run-manifest.json | ForEach-Object {
        $manifest = Read-JsonFile $_.FullName
        if ($manifest) {
            [pscustomobject]@{
                path = $_.FullName
                status = $manifest.status
                created_at = $manifest.created_at
                has_raw_files = [bool]($manifest.raw_files -and @($manifest.raw_files).Count -gt 0)
                has_reviewed_files = [bool]($manifest.reviewed_files -and @($manifest.reviewed_files).Count -gt 0)
                has_final_files = [bool]($manifest.final_files -and @($manifest.final_files).Count -gt 0)
                raw_rows = $manifest.raw_rows
                reviewed_rows = $manifest.reviewed_rows
                merged_rows = $manifest.merged_rows
                pending_rows = $manifest.pending_rows
                rejected_rows = $manifest.rejected_rows
            }
        }
    })
}

$unfinishedRuns = @($runManifests | Where-Object {
    $_.status -in @('raw_staged','reviewed') -or
    ($_.status -eq 'created' -and ($_.has_raw_files -or $_.has_reviewed_files -or $_.has_final_files))
})
$duplicateKeys = @($masterRows | Group-Object { Normalize-Key $_ } | Where-Object { $_.Name -and $_.Count -gt 1 })
$recentActivity = if (Test-Path -LiteralPath $activityLog) {
    @(Get-Content -LiteralPath $activityLog -Tail 80)
} else {
    @()
}
$recentFailures = @($recentActivity | Where-Object { $_ -match 'failed|HTTP 400|timeout|stale|blocked' })
$latestQuarantine = $null
if (Test-Path -LiteralPath $quarantineDir) {
    $stateSlug = $targetState.ToLower()
    $latestQuarantineFile = Get-ChildItem -LiteralPath $quarantineDir -File -Filter "*-$stateSlug-suspicious-quarantine.json" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestQuarantineFile) {
        $latestQuarantine = Read-JsonFile $latestQuarantineFile.FullName
    }
}

$issues = @()
if (-not $guard.can_start_collector) {
    $issues += "collector_guard_blocked:$($guard.reasons -join ';')"
}
if ($unfinishedRuns.Count -gt 0) {
    $issues += "unfinished_runs:$($unfinishedRuns.Count)"
}
if ($duplicateKeys.Count -gt 0) {
    $issues += "duplicate_master_keys:$($duplicateKeys.Count)"
}
if ($recentFailures.Count -gt 5) {
    $issues += "recent_failure_noise:$($recentFailures.Count)"
}

$health = if ($issues.Count -eq 0) { 'green' } elseif ($issues.Count -le 2) { 'yellow' } else { 'red' }
$report = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    health = $health
    target_state = $targetState
    active_lanes = @($sourceConfig.lanes | ForEach-Object { "$($_.city), $($_.state)" })
    master_rows = $masterRows.Count
    pending_queue_rows = if ($opsSnapshot) { $opsSnapshot.pending_queue_rows } else { $null }
    latest_quarantine_rows = if ($latestQuarantine) { $latestQuarantine.quarantined_rows } else { 0 }
    collector_can_start = [bool]$guard.can_start_collector
    collector_reasons = @($guard.reasons)
    unfinished_runs = @($unfinishedRuns)
    duplicate_master_key_count = $duplicateKeys.Count
    recent_failure_count = $recentFailures.Count
    issues = @($issues)
    next_action = if ($unfinishedRuns.Count -gt 0) {
        'Finish unfinished staged/reviewed run before starting a collector.'
    } elseif (-not $guard.can_start_collector) {
        'Wait for collector guard to clear or resolve stale claim.'
    } elseif ($duplicateKeys.Count -gt 0) {
        'Review duplicate keys before merging more leads.'
    } else {
        'System can continue with pending enrichment or fresh collector sourcing.'
    }
}

$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputJson

$md = @(
    "# LeadForge Ops Health",
    "",
    "- Generated: $($report.generated_at)",
    "- Health: $($report.health)",
    "- Target state: $($report.target_state)",
    "- Master rows: $($report.master_rows)",
    "- Pending queue rows: $($report.pending_queue_rows)",
    "- Collector can start: $($report.collector_can_start)",
    "- Issues: $(if ($issues.Count) { $issues -join '; ' } else { 'none' })",
    "- Next action: $($report.next_action)"
)
$md | Set-Content -LiteralPath $OutputMarkdown

[pscustomobject]$report | Format-List
