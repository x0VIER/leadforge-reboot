param(
    [string]$ArchiveCsv,
    [string]$OutputCsv,
    [string]$ExcludeLeadIdsCsv
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ArchiveCsv) {
    $ArchiveCsv = Join-Path $ScriptDir '..\data\archive\Recovered_Leads_Database_2026-06-12_snapshot.csv'
}
if (-not $OutputCsv) {
    $OutputCsv = Join-Path $ScriptDir '..\data\master_leads.csv'
}

$archivePath = (Resolve-Path -LiteralPath $ArchiveCsv).Path
$outputPath = $OutputCsv
$reviewedRoot = Join-Path $ScriptDir '..\data\runs'
$tempRoot = Join-Path $ScriptDir '..\data\tmp'
$runLogRoot = Join-Path $ScriptDir '..\data\run-logs'
$quarantineRoot = Join-Path $ScriptDir '..\data\quarantine'
$reviewedFiles = @(Get-ChildItem -Path $reviewedRoot -Recurse -File -Filter *.csv | Where-Object { $_.FullName -match '\\reviewed\\' } | Sort-Object FullName)
New-Item -ItemType Directory -Force -Path $tempRoot, $runLogRoot | Out-Null

$stamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$tempOutputPath = Join-Path $tempRoot "master-rebuild-$stamp.csv.partial"
$rebuildLogPath = Join-Path $runLogRoot "$stamp-master-rebuild.json"

Copy-Item -LiteralPath $archivePath -Destination $tempOutputPath -Force

$mergeScript = Join-Path $ScriptDir 'merge-new-leads.ps1'
$mergeSummaries = @()
foreach ($file in $reviewedFiles) {
    $summary = powershell -ExecutionPolicy Bypass -File $mergeScript -MasterCsv $tempOutputPath -OutputCsv $tempOutputPath -NewCsv $file.FullName | Out-String
    $mergeSummaries += [pscustomobject]@{
        file = $file.FullName
        summary = $summary.Trim()
    }
}

$excludedLeadIds = @()
$excludeSourcePaths = @()
if ($ExcludeLeadIdsCsv -and (Test-Path -LiteralPath $ExcludeLeadIdsCsv)) {
    $excludeSourcePaths = @((Resolve-Path -LiteralPath $ExcludeLeadIdsCsv).Path)
} elseif (Test-Path -LiteralPath $quarantineRoot) {
    $excludeSourcePaths = @(
        Get-ChildItem -LiteralPath $quarantineRoot -File -Filter '*-suspicious-lead-ids.csv' |
            Sort-Object FullName |
            ForEach-Object { $_.FullName }
    )
}

if ($excludeSourcePaths.Count -gt 0) {
    $allExcludedLeadIds = foreach ($path in $excludeSourcePaths) {
        Import-Csv -LiteralPath $path |
            ForEach-Object { [string]$_.lead_id } |
            Where-Object { $_ }
    }
    $excludedLeadIds = @($allExcludedLeadIds | Sort-Object -Unique)
    if ($excludedLeadIds.Count -gt 0) {
        $excludeSet = New-Object System.Collections.Generic.HashSet[string]
        foreach ($leadId in $excludedLeadIds) {
            [void]$excludeSet.Add($leadId)
        }

        $filteredRows = @(
            Import-Csv -LiteralPath $tempOutputPath |
                Where-Object { -not $excludeSet.Contains([string]$_.lead_id) }
        )
        $filteredRows | Export-Csv -LiteralPath $tempOutputPath -NoTypeInformation
    }
}

Move-Item -LiteralPath $tempOutputPath -Destination $outputPath -Force

$finalRows = (Import-Csv -LiteralPath $outputPath).Count
[pscustomobject]@{
    rebuilt_at = (Get-Date).ToString('s')
    archive_csv = $archivePath
    reviewed_files = $reviewedFiles.FullName
    excluded_lead_ids_csv = if ($ExcludeLeadIdsCsv -and (Test-Path -LiteralPath $ExcludeLeadIdsCsv)) { (Resolve-Path -LiteralPath $ExcludeLeadIdsCsv).Path } else { '' }
    excluded_lead_id_sources = @($excludeSourcePaths)
    excluded_lead_ids_count = $excludedLeadIds.Count
    output_csv = (Resolve-Path -LiteralPath $outputPath).Path
    final_rows = $finalRows
    merge_details = $mergeSummaries
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $rebuildLogPath

[pscustomobject]@{
    archive_csv = $archivePath
    reviewed_files = $reviewedFiles.Count
    excluded_lead_ids_count = $excludedLeadIds.Count
    excluded_lead_id_sources = $excludeSourcePaths.Count
    output_csv = (Resolve-Path -LiteralPath $outputPath).Path
    final_rows = $finalRows
    rebuild_log = (Resolve-Path -LiteralPath $rebuildLogPath).Path
} | Format-List

if ($mergeSummaries.Count -gt 0) {
    "`nReviewed merge details:"
    foreach ($item in $mergeSummaries) {
        "FILE: $($item.file)"
        $item.summary
        ""
    }
}
