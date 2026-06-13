param(
    [string]$State
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Join-Path $ScriptDir '..'
$statusDir = Join-Path $root 'agent_shared\status'
$runsRoot = Join-Path $root 'data\runs'
$masterCsv = Join-Path $root 'data\master_leads.csv'
$configPath = Join-Path $root 'config\source-lanes.json'
$currentStatusPath = Join-Path $statusDir 'CURRENT_STATUS.json'
$lastSuccessPath = Join-Path $statusDir 'LAST_SUCCESS.json'
$pendingQueuePath = Join-Path $statusDir 'PENDING_ENRICHMENT_QUEUE.json'
$outputPath = Join-Path $statusDir 'OPS_SNAPSHOT.json'
$workingDir = Join-Path $root 'agent_shared\working'
$staleClaimHours = 2

New-Item -ItemType Directory -Force -Path $statusDir | Out-Null

$masterCount = if (Test-Path -LiteralPath $masterCsv) { (Import-Csv -LiteralPath $masterCsv).Count } else { 0 }
$config = if (Test-Path -LiteralPath $configPath) { Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json } else { $null }
$targetState = if ($State) {
    $State.ToUpper()
} elseif ($config -and $config.targetState) {
    $config.targetState.ToString().ToUpper()
} elseif ($config -and $config.lanes -and $config.lanes[0].state) {
    $config.lanes[0].state.ToString().ToUpper()
} else {
    'FL'
}
$ownerBacklogPath = Join-Path $statusDir "OWNER_ENRICHMENT_BACKLOG_$targetState.json"
$contaminationAuditPath = Join-Path $statusDir "MASTER_CONTAMINATION_AUDIT_$targetState.json"
$currentStatus = if (Test-Path -LiteralPath $currentStatusPath) { Get-Content -LiteralPath $currentStatusPath -Raw | ConvertFrom-Json } else { $null }
$lastSuccess = if (Test-Path -LiteralPath $lastSuccessPath) { Get-Content -LiteralPath $lastSuccessPath -Raw | ConvertFrom-Json } else { $null }
$pendingQueue = if (Test-Path -LiteralPath $pendingQueuePath) { Get-Content -LiteralPath $pendingQueuePath -Raw | ConvertFrom-Json } else { $null }
$ownerBacklog = if (Test-Path -LiteralPath $ownerBacklogPath) { Get-Content -LiteralPath $ownerBacklogPath -Raw | ConvertFrom-Json } else { $null }
$contaminationAudit = if (Test-Path -LiteralPath $contaminationAuditPath) { Get-Content -LiteralPath $contaminationAuditPath -Raw | ConvertFrom-Json } else { $null }

$recentRuns = @(Get-ChildItem -Path $runsRoot -Recurse -File -Filter run-manifest.json | Sort-Object LastWriteTime -Descending | Select-Object -First 5)
function Normalize-StringArray($value) {
    if ($null -eq $value) { return @() }
    return @($value | Where-Object { $_ -and $_.ToString().Trim() })
}

function Normalize-ObjectArray($value) {
    if ($null -eq $value) { return @() }
    if ($value -is [System.Array]) { return @($value) }
    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string]) -and -not ($value -is [pscustomobject])) {
        return @($value)
    }
    return @($value)
}

function Get-CollectorGuardStatus {
    $claims = @()
    $staleClaimCutoff = (Get-Date).AddHours(-$staleClaimHours)

    if (Test-Path -LiteralPath $workingDir) {
        foreach ($file in @(Get-ChildItem -LiteralPath $workingDir -File -Filter *.json | Sort-Object LastWriteTime)) {
            $claim = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            if (-not $claim -or $claim.workflow -ne 'source-batch') {
                continue
            }

            $startedAt = $null
            try {
                $startedAt = [datetime]$claim.startedAt
            }
            catch {
                $startedAt = $null
            }

            $isStale = if ($startedAt) { $startedAt -lt $staleClaimCutoff } else { $false }
            $claims += [pscustomobject]@{
                file = $file.Name
                owner = $claim.owner
                batch_name = $claim.batchName
                status = $claim.status
                started_at = $claim.startedAt
                age_minutes = if ($startedAt) { [math]::Floor(((Get-Date) - $startedAt).TotalMinutes) } else { $null }
                is_stale = $isStale
            }
        }
    }

    $activeClaims = @($claims | Where-Object { -not $_.is_stale })
    $staleClaims = @($claims | Where-Object { $_.is_stale })
    $currentRunStartedAt = $null
    $currentRunIsFresh = $false

    if ($currentStatus -and $currentStatus.startedAt) {
        try {
            $currentRunStartedAt = [datetime]$currentStatus.startedAt
            $currentRunIsFresh = $currentRunStartedAt -ge $staleClaimCutoff
        }
        catch {
            $currentRunStartedAt = $null
            $currentRunIsFresh = $false
        }
    }

    $hasFreshRunningStatus = $currentStatus -and $currentStatus.state -eq 'running' -and $currentRunIsFresh
    $canStartCollector = ($activeClaims.Count -eq 0) -and (-not $hasFreshRunningStatus)
    $reasons = @()

    if ($activeClaims.Count -gt 0) {
        $reasons += "active_claim_present:$($activeClaims[0].file)"
    }
    if ($hasFreshRunningStatus) {
        $reasons += "current_status_running:$($currentStatus.claimFile)"
    }
    if ($staleClaims.Count -gt 0) {
        $reasons += "stale_claims_detected:$($staleClaims.Count)"
    }
    if ($reasons.Count -eq 0) {
        $reasons += 'collector_clear_to_start'
    }

    return [pscustomobject]@{
        stale_claim_hours = $staleClaimHours
        can_start_collector = $canStartCollector
        reasons = @($reasons)
        active_claim_count = $activeClaims.Count
        stale_claim_count = $staleClaims.Count
        active_claims = @($activeClaims)
        stale_claims = @($staleClaims)
        current_status_running_is_fresh = $hasFreshRunningStatus
    }
}

$runSummaries = foreach ($manifestFile in $recentRuns) {
    $manifest = Get-Content -LiteralPath $manifestFile.FullName -Raw | ConvertFrom-Json
    [pscustomobject]@{
        run_name = $manifest.run_name
        status = $manifest.status
        created_at = $manifest.created_at
        pending_files = @(Normalize-StringArray $manifest.pending_files)
        rejected_files = @(Normalize-StringArray $manifest.rejected_files)
        reviewed_files = @(Normalize-StringArray $manifest.reviewed_files)
        final_files = @(Normalize-StringArray $manifest.final_files)
    }
}

$collectorGuard = Get-CollectorGuardStatus
$pendingItems = if ($pendingQueue) { @(Normalize-ObjectArray $pendingQueue.items) } else { @() }
$pendingNeedsImmediateResearch = @($pendingItems | Where-Object { $_.pending_state -ne 'researched_owner_unresolved' }).Count
$pendingBlockedButDocumented = @($pendingItems | Where-Object { $_.pending_state -eq 'researched_owner_unresolved' }).Count

$snapshot = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    target_state = $targetState
    master_lead_rows = $masterCount
    active_lane_window = if ($config) { @($config.lanes | ForEach-Object { "$($_.city), $($_.state)" }) } else { @() }
    pending_queue_rows = if ($pendingQueue) { [int]$pendingQueue.pending_rows } else { 0 }
    pending_queue_immediate_research_rows = $pendingNeedsImmediateResearch
    pending_queue_researched_unresolved_rows = $pendingBlockedButDocumented
    pending_queue_items = @($pendingItems)
    owner_enrichment_backlog = if ($ownerBacklog) {
        [ordered]@{
            state = $ownerBacklog.state
            missing_owner_rows = $ownerBacklog.missing_owner_rows
            eligible_missing_owner_rows = $ownerBacklog.eligible_missing_owner_rows
            suspicious_rows_excluded = $ownerBacklog.suspicious_rows_excluded
            coverage_percent = $ownerBacklog.coverage_percent
        }
    } else {
        $null
    }
    contamination_audit = if ($contaminationAudit) {
        [ordered]@{
            state = $contaminationAudit.state
            duplicate_website_groups = $contaminationAudit.duplicate_website_groups
            suspicious_row_count = $contaminationAudit.suspicious_row_count
        }
    } else {
        $null
    }
    collector_guard = $collectorGuard
    current_status = $currentStatus
    last_success = $lastSuccess
    recent_runs = @($runSummaries)
    next_action_hint = if ($pendingNeedsImmediateResearch -gt 0) {
        'Resolve pending enrichment rows before opening a new collector run.'
    } elseif ($contaminationAudit -and [int]$contaminationAudit.suspicious_row_count -gt 0) {
        'Contamination review queue is non-empty; prefer auditing suspicious cloned rows before spending more enrichment effort on them.'
    } elseif ($pendingBlockedButDocumented -gt 0 -and $collectorGuard.can_start_collector) {
        'Pending rows are documented but blocked on stronger public evidence; collector may proceed while leaving them in queue.'
    } elseif (-not $collectorGuard.can_start_collector) {
        'Collector is not clear to start yet; inspect active claims or fresh running status before opening a new run.'
    } elseif ($currentStatus -and $currentStatus.state -eq 'complete_no_rows') {
        'Current lane window is dry; rotate cities before the next collector run.'
    } else {
        'Collector may proceed if no active claim exists and no pending enrichment rows remain.'
    }
}

$snapshot | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outputPath
[pscustomobject]@{
    output_path = $outputPath
    master_lead_rows = $masterCount
    pending_queue_rows = if ($pendingQueue) { [int]$pendingQueue.pending_rows } else { 0 }
} | Format-List
