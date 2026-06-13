param()

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Join-Path $ScriptDir '..'
$workingDir = Join-Path $root 'agent_shared\working'
$statusPath = Join-Path $root 'agent_shared\status\CURRENT_STATUS.json'
$staleClaimHours = 2
$staleClaimCutoff = (Get-Date).AddHours(-$staleClaimHours)

function Read-JsonFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

$claims = @()
if (Test-Path -LiteralPath $workingDir) {
    foreach ($file in @(Get-ChildItem -LiteralPath $workingDir -File -Filter *.json | Sort-Object LastWriteTime)) {
        $claim = Read-JsonFile $file.FullName
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
$currentStatus = Read-JsonFile $statusPath
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

[ordered]@{
    generated_at = (Get-Date).ToString('s')
    stale_claim_hours = $staleClaimHours
    can_start_collector = $canStartCollector
    reasons = @($reasons)
    active_claim_count = $activeClaims.Count
    stale_claim_count = $staleClaims.Count
    active_claims = @($activeClaims)
    stale_claims = @($staleClaims)
    current_status = if ($currentStatus) {
        [ordered]@{
            state = $currentStatus.state
            owner = $currentStatus.owner
            batchName = $currentStatus.batchName
            claimFile = $currentStatus.claimFile
            startedAt = $currentStatus.startedAt
            rowsWritten = $currentStatus.rowsWritten
            activeLane = $currentStatus.activeLane
            is_fresh_running_state = $hasFreshRunningStatus
        }
    } else {
        $null
    }
} | ConvertTo-Json -Depth 6
