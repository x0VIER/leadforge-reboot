param(
    [ValidateSet('StartOfDay', 'EndOfDay', 'UsageLimitHandoff')]
    [string]$Mode = 'EndOfDay',
    [string]$Date = (Get-Date).ToString('yyyy-MM-dd'),
    [switch]$RefreshStatus
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..')
$statusDir = Join-Path $root 'agent_shared\status'
$reportsRoot = Join-Path $root 'agent_shared\reports'
$reportDir = Join-Path $reportsRoot $Date
$runsRoot = Join-Path $root 'data\runs'
$masterCsv = Join-Path $root 'data\master_leads.csv'
$activityLog = Join-Path $root 'agent_shared\shared_activity_log.md'

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

function Read-JsonFile($path) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try { return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-IntValue($value) {
    if ($null -eq $value -or $value -eq '') { return 0 }
    try { return [int]$value } catch { return 0 }
}

function New-ReportLink($path, $label) {
    if (-not $path) { return $label }
    $resolved = $path
    try { $resolved = (Resolve-Path -LiteralPath $path -ErrorAction Stop).Path } catch { }
    $relative = $resolved
    if ($resolved.StartsWith($root.Path)) {
        $relative = $resolved.Substring($root.Path.Length).TrimStart('\') -replace '\\', '/'
    }
    return "[$label](../../$relative)"
}

if ($RefreshStatus) {
    & (Join-Path $ScriptDir 'build-master-contamination-audit.ps1') -SkipDnsCheck | Out-Null
    & (Join-Path $ScriptDir 'build-owner-enrichment-backlog.ps1') | Out-Null
    & (Join-Path $ScriptDir 'build-pending-enrichment-report.ps1') | Out-Null
    & (Join-Path $ScriptDir 'build-lead-memory-index.ps1') | Out-Null
    & (Join-Path $ScriptDir 'build-factory-metrics.ps1') | Out-Null
    & (Join-Path $ScriptDir 'build-ops-snapshot.ps1') | Out-Null
    & (Join-Path $ScriptDir 'build-ops-health-report.ps1') | Out-Null
}

$snapshot = Read-JsonFile (Join-Path $statusDir 'OPS_SNAPSHOT.json')
$health = Read-JsonFile (Join-Path $statusDir 'OPS_HEALTH_REPORT.json')
$metrics = Read-JsonFile (Join-Path $statusDir 'FACTORY_METRICS.json')
$pendingQueue = Read-JsonFile (Join-Path $statusDir 'PENDING_ENRICHMENT_QUEUE.json')
$leadMemory = Read-JsonFile (Join-Path $statusDir 'LEAD_MEMORY_INDEX.json')
$guardText = (& (Join-Path $ScriptDir 'get-collector-guard-status.ps1') | Out-String)
$guard = $null
try { $guard = $guardText | ConvertFrom-Json } catch { }

$masterRows = if (Test-Path -LiteralPath $masterCsv) { @(Import-Csv -LiteralPath $masterCsv) } else { @() }
$pendingRows = if ($pendingQueue) { @($pendingQueue.items) } else { @() }

$manifests = @()
if (Test-Path -LiteralPath $runsRoot) {
    $manifests = @(Get-ChildItem -LiteralPath $runsRoot -Recurse -File -Filter run-manifest.json | ForEach-Object {
        $manifest = Read-JsonFile $_.FullName
        if (-not $manifest) { return }
        $created = $null
        try { $created = [datetime]$manifest.created_at } catch { }
        [pscustomobject]@{
            path = $_.FullName
            created_at = $manifest.created_at
            created_date = if ($created) { $created.ToString('yyyy-MM-dd') } else { '' }
            status = $manifest.status
            raw_rows = Get-IntValue $manifest.raw_rows
            reviewed_rows = Get-IntValue $manifest.reviewed_rows
            merged_rows = Get-IntValue $manifest.merged_rows
            pending_rows = Get-IntValue $manifest.pending_rows
            rejected_rows = Get-IntValue $manifest.rejected_rows
            notes = $manifest.notes
        }
    })
}

$dailyRuns = @($manifests | Where-Object { $_.created_date -eq $Date } | Sort-Object created_at)
$dailyRaw = Get-IntValue (($dailyRuns | Measure-Object raw_rows -Sum).Sum)
$dailyReviewed = Get-IntValue (($dailyRuns | Measure-Object reviewed_rows -Sum).Sum)
$dailyMerged = Get-IntValue (($dailyRuns | Measure-Object merged_rows -Sum).Sum)
$dailyPending = Get-IntValue (($dailyRuns | Measure-Object pending_rows -Sum).Sum)
$dailyRejected = Get-IntValue (($dailyRuns | Measure-Object rejected_rows -Sum).Sum)

$pendingByReason = @($pendingRows | Group-Object triage_reason | Sort-Object Count -Descending | Select-Object -First 12)
$noWebsitePending = @($pendingRows | Where-Object { [string]::IsNullOrWhiteSpace($_.website) } | Select-Object -First 12)
$recentActivity = @()
if (Test-Path -LiteralPath $activityLog) {
    $recentActivity = @(Get-Content -LiteralPath $activityLog | Where-Object { $_ -like "*$Date*" } | Select-Object -Last 20)
}

$gitStatus = (git -C $root.Path status --short) -join "`n"
$gitCommits = @(git -C $root.Path log --since="$Date 00:00" --pretty=format:"%h %s" --max-count=20)
if ($LASTEXITCODE -ne 0) { $gitCommits = @() }

$modeLabel = switch ($Mode) {
    'StartOfDay' { 'Start Of Day' }
    'UsageLimitHandoff' { 'Usage Limit Handoff' }
    default { 'End Of Day' }
}
$fileSlug = switch ($Mode) {
    'StartOfDay' { 'start-of-day' }
    'UsageLimitHandoff' { 'usage-limit-handoff' }
    default { 'end-of-day' }
}
$reportPath = Join-Path $reportDir "$fileSlug.md"

$lines = @(
    "# LeadForge $modeLabel Report - $Date",
    "",
    "Generated: $(Get-Date -Format s)",
    "",
    "## Snapshot",
    "",
    "- Master rows now: $($masterRows.Count)",
    "- Leads merged today: $dailyMerged",
    "- Raw candidates staged today: $dailyRaw",
    "- Reviewed rows today: $dailyReviewed",
    "- Pending rows created today: $dailyPending",
    "- Rejected rows today: $dailyRejected",
    "- Pending queue now: $($pendingRows.Count)",
    "- Unique lead-memory keys: $($leadMemory.unique_lead_keys)",
    "- Duplicate lead-memory keys: $($leadMemory.duplicate_key_count)",
    "- Active lanes: $(@($snapshot.active_lane_window) -join ', ')",
    "- Health: $($health.health)",
    "- Collector can start: $($guard.can_start_collector)",
    "",
    "## Tasks And Runs",
    ""
)

if ($dailyRuns.Count -eq 0) {
    $lines += "- No run manifests were created for this date."
}
else {
    foreach ($run in $dailyRuns) {
        $lines += "- $($run.created_at) - $($run.status): raw $($run.raw_rows), reviewed $($run.reviewed_rows), merged $($run.merged_rows), pending $($run.pending_rows), rejected $($run.rejected_rows). $(New-ReportLink $run.path 'manifest')"
    }
}

$lines += @("", "## Pending Callback Categories", "")
if ($pendingByReason.Count -eq 0) {
    $lines += "- No pending rows currently listed."
}
else {
    foreach ($group in $pendingByReason) {
        $reason = if ([string]::IsNullOrWhiteSpace($group.Name)) { 'uncategorized' } else { $group.Name }
        $lines += "- ${reason}: $($group.Count)"
    }
}

$lines += @("", "## No-Website Or Weak-Web Callback Queue", "")
if ($noWebsitePending.Count -eq 0) {
    $lines += "- No no-website pending rows found."
}
else {
    foreach ($item in $noWebsitePending) {
        $lines += "- $($item.business_name) - $($item.city), $($item.state) - $($item.niche) - action: $($item.recommended_action)"
    }
}

$lines += @("", "## Issues, Fixes, And Activity", "")
if ($recentActivity.Count -eq 0) {
    $lines += "- No dated activity-log entries found for this date."
}
else {
    $lines += $recentActivity
}

$lines += @(
    "",
    "## Important Files",
    "",
    "- $(New-ReportLink (Join-Path $statusDir 'OPS_SNAPSHOT.json') 'OPS snapshot')",
    "- $(New-ReportLink (Join-Path $statusDir 'OPS_HEALTH_REPORT.md') 'OPS health report')",
    "- $(New-ReportLink (Join-Path $statusDir 'FACTORY_METRICS.md') 'Factory metrics')",
    "- $(New-ReportLink (Join-Path $statusDir 'PENDING_ENRICHMENT_QUEUE.json') 'Pending queue')",
    "- $(New-ReportLink (Join-Path $statusDir 'LEAD_MEMORY_INDEX.csv') 'Lead memory index')",
    "- $(New-ReportLink $masterCsv 'Master leads CSV')",
    "",
    "## Git Save Point",
    ""
)

if ($gitCommits.Count -eq 0) {
    $lines += "- No commits found for this date."
}
else {
    foreach ($commit in $gitCommits) { $lines += "- $commit" }
}

$lines += @("", "## Working Tree", "")
if ([string]::IsNullOrWhiteSpace($gitStatus)) {
    $lines += "- Clean working tree."
}
if (-not ([string]::IsNullOrWhiteSpace($gitStatus))) {
    $lines += '```text'
    $lines += $gitStatus
    $lines += '```'
}

$lines += @(
    "",
    "## Next Start Instructions",
    "",
    "- Read this report, OPS snapshot, OPS health, source lanes, latest manifests, lead memory index, collector guard, and git status.",
    "- Finish any raw_staged or reviewed_to_merge run before opening a collector.",
    "- Search the lead memory index before re-researching or re-collecting a business.",
    "- If usage is close to a 5-hour or weekly limit, do not start a collector; run UsageLimitHandoff and commit.",
    ""
)

if ($Mode -eq 'UsageLimitHandoff') {
    $lines += @(
        "## Usage Limit Protocol",
        "",
        "- Stop opening new collectors.",
        "- Finish only the current atomic step.",
        "- Leave unresolved rows pending with public_research_note and recommended_action.",
        "- Prefer a clean local commit over starting another cycle.",
        ""
    )
}

$lines | Set-Content -LiteralPath $reportPath

$indexPath = Join-Path $reportsRoot 'INDEX.md'
$indexLine = "- $Date - $modeLabel - [$fileSlug]($Date/$fileSlug.md)"
if (Test-Path -LiteralPath $indexPath) {
    $existing = @(Get-Content -LiteralPath $indexPath)
    if ($existing -notcontains $indexLine) { $existing + $indexLine | Set-Content -LiteralPath $indexPath }
}
else {
    @("# LeadForge Reports", "", $indexLine) | Set-Content -LiteralPath $indexPath
}

[pscustomobject]@{
    report_path = $reportPath
    mode = $Mode
    date = $Date
    master_rows = $masterRows.Count
    daily_raw_rows = $dailyRaw
    daily_merged_rows = $dailyMerged
    pending_rows = $pendingRows.Count
} | Format-List
