param()

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

New-Item -ItemType Directory -Force -Path $statusDir | Out-Null

$masterCount = if (Test-Path -LiteralPath $masterCsv) { (Import-Csv -LiteralPath $masterCsv).Count } else { 0 }
$config = if (Test-Path -LiteralPath $configPath) { Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json } else { $null }
$currentStatus = if (Test-Path -LiteralPath $currentStatusPath) { Get-Content -LiteralPath $currentStatusPath -Raw | ConvertFrom-Json } else { $null }
$lastSuccess = if (Test-Path -LiteralPath $lastSuccessPath) { Get-Content -LiteralPath $lastSuccessPath -Raw | ConvertFrom-Json } else { $null }
$pendingQueue = if (Test-Path -LiteralPath $pendingQueuePath) { Get-Content -LiteralPath $pendingQueuePath -Raw | ConvertFrom-Json } else { $null }

$recentRuns = @(Get-ChildItem -Path $runsRoot -Recurse -File -Filter run-manifest.json | Sort-Object LastWriteTime -Descending | Select-Object -First 5)
function Normalize-StringArray($value) {
    if ($null -eq $value) { return @() }
    return @($value | Where-Object { $_ -and $_.ToString().Trim() })
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

$snapshot = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    master_lead_rows = $masterCount
    active_lane_window = if ($config) { @($config.lanes | ForEach-Object { "$($_.city), $($_.state)" }) } else { @() }
    pending_queue_rows = if ($pendingQueue) { [int]$pendingQueue.pending_rows } else { 0 }
    pending_queue_items = if ($pendingQueue) { [object[]]@($pendingQueue.items) } else { @() }
    current_status = $currentStatus
    last_success = $lastSuccess
    recent_runs = @($runSummaries)
    next_action_hint = if ($pendingQueue -and [int]$pendingQueue.pending_rows -gt 0) {
        'Resolve pending enrichment rows before opening a new collector run.'
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
