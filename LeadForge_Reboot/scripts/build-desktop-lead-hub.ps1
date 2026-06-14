param(
    [string]$MasterCsv = "",
    [string]$ViewerXlsx = "",
    [string]$HubDir = ""
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $MasterCsv) {
    $MasterCsv = Join-Path $Root "data\master_leads.csv"
}
if (-not $ViewerXlsx) {
    $ViewerXlsx = Join-Path $Root "data\views\LeadForge_Master_Viewer.xlsx"
}
if (-not $HubDir) {
    $HubDir = Join-Path ([Environment]::GetFolderPath("Desktop")) "LeadForge Lead Files"
}

$MasterCsv = (Resolve-Path -LiteralPath $MasterCsv).Path
$ViewerXlsx = (Resolve-Path -LiteralPath $ViewerXlsx).Path

$folders = [ordered]@{
    Root = $HubDir
    AllLeads = (Join-Path $HubDir "01 All Leads")
    ByNiche = (Join-Path $HubDir "02 By Niche")
    LatestRuns = (Join-Path $HubDir "03 Latest Runs")
    Reports = (Join-Path $HubDir "04 Reports")
    PendingRejected = (Join-Path $HubDir "05 Pending And Rejected")
    System = (Join-Path $HubDir "06 System And Logs")
    Legacy = (Join-Path $HubDir "06 System And Logs\Legacy Shortcuts")
}

foreach ($path in $folders.Values) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

$desktopViewer = Join-Path $HubDir "OPEN ME - LeadForge Master Viewer.xlsx"
Copy-Item -LiteralPath $ViewerXlsx -Destination $desktopViewer -Force
Copy-Item -LiteralPath $MasterCsv -Destination (Join-Path $folders.AllLeads "Raw Master Leads Backup.csv") -Force

function New-HubShortcut {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Target,
        [string]$Arguments = "",
        [string]$WorkingDirectory = ""
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $Target
    if ($Arguments) { $shortcut.Arguments = $Arguments }
    if ($WorkingDirectory) { $shortcut.WorkingDirectory = $WorkingDirectory }
    $shortcut.Save()
}

function Get-SafeName([string]$value) {
    if (-not $value) { return "Unknown" }
    $safe = ($value -replace '_', ' ' -replace '-', ' ').Trim()
    $safe = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($safe.ToLower())
    $safe = $safe -replace '[\\/:*?"<>|]', ''
    if (-not $safe) { return "Unknown" }
    return $safe
}

$explorer = Join-Path $env:WINDIR "explorer.exe"
$libreOffice = Join-Path $env:ProgramFiles "LibreOffice\program\soffice.exe"
if (-not (Test-Path -LiteralPath $libreOffice)) {
    $libreOffice = $desktopViewer
}

New-HubShortcut -Path (Join-Path $HubDir "OPEN DASHBOARD - Polished Lead Viewer.lnk") -Target $desktopViewer
New-HubShortcut -Path (Join-Path $HubDir "Open All Leads Folder.lnk") -Target $explorer -Arguments "`"$($folders.AllLeads)`""
New-HubShortcut -Path (Join-Path $HubDir "Open By Niche Folder.lnk") -Target $explorer -Arguments "`"$($folders.ByNiche)`""
New-HubShortcut -Path (Join-Path $HubDir "Open Latest Runs Folder.lnk") -Target $explorer -Arguments "`"$($folders.LatestRuns)`""
New-HubShortcut -Path (Join-Path $HubDir "Open Reports Folder.lnk") -Target $explorer -Arguments "`"$($folders.Reports)`""

$oldTopLevelItems = @(
    "LeadForge Master Viewer.xlsx",
    "Open Daily Reports Folder.lnk",
    "Open LeadForge Data Folder.lnk",
    "Open LibreOffice Calc.lnk",
    "Open Master Leads in LibreOffice Calc.lnk",
    "Open Reviewed Run Folders.lnk",
    "Open Status Reports Folder.lnk",
    "Open Today New Lead CSV Outputs.lnk"
)
foreach ($item in $oldTopLevelItems) {
    $source = Join-Path $HubDir $item
    if (-not (Test-Path -LiteralPath $source)) { continue }
    $destination = Join-Path $folders.Legacy $item
    if (Test-Path -LiteralPath $destination) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $destination = Join-Path $folders.Legacy "$stamp - $item"
    }
    Move-Item -LiteralPath $source -Destination $destination
}

New-HubShortcut -Path (Join-Path $folders.AllLeads "Open Polished Master Viewer.lnk") -Target $desktopViewer
New-HubShortcut -Path (Join-Path $folders.AllLeads "Open Raw Master CSV.lnk") -Target $MasterCsv
New-HubShortcut -Path (Join-Path $folders.LatestRuns "Open Run Folders.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'data\runs')`""
New-HubShortcut -Path (Join-Path $folders.Reports "Open Status Reports.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'agent_shared\status')`""
New-HubShortcut -Path (Join-Path $folders.Reports "Open Daily Reports.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'reports\daily')`""
New-HubShortcut -Path (Join-Path $folders.System "Open LeadForge Project Folder.lnk") -Target $explorer -Arguments "`"$Root`""
New-HubShortcut -Path (Join-Path $folders.System "Open Automation Logs.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'agent_shared\logs')`""

$rows = @(Import-Csv -LiteralPath $MasterCsv)
$nicheGroups = $rows | Group-Object -Property niche | Sort-Object Count -Descending
foreach ($group in $nicheGroups) {
    $nicheName = Get-SafeName $group.Name
    $nicheDir = Join-Path $folders.ByNiche $nicheName
    New-Item -ItemType Directory -Force -Path $nicheDir | Out-Null

    $nicheCsv = Join-Path $nicheDir "$nicheName Leads - Raw Export.csv"
    $group.Group | Export-Csv -LiteralPath $nicheCsv -NoTypeInformation
    New-HubShortcut -Path (Join-Path $nicheDir "Open $nicheName In Polished Viewer.lnk") -Target $desktopViewer
    New-HubShortcut -Path (Join-Path $nicheDir "Open Raw $nicheName CSV.lnk") -Target $nicheCsv
}

$pendingFiles = Get-ChildItem -Path (Join-Path $Root "data\runs") -Recurse -File -Filter "*.pending-enrichment.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rejectedFiles = Get-ChildItem -Path (Join-Path $Root "data\runs") -Recurse -File -Filter "*.rejected.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if ($pendingFiles) {
    New-HubShortcut -Path (Join-Path $folders.PendingRejected "Open Latest Pending Enrichment CSV.lnk") -Target $pendingFiles[0].FullName
}
if ($rejectedFiles) {
    New-HubShortcut -Path (Join-Path $folders.PendingRejected "Open Latest Rejected CSV.lnk") -Target $rejectedFiles[0].FullName
}

$readme = @"
# LeadForge Lead Files

Open this first:

`OPEN ME - LeadForge Master Viewer.xlsx`

That workbook is the polished LibreOffice view. It has a dashboard, full lead data, lead board, owner evidence, callback queue, data quality, field guide, and lead tabs by niche. The raw CSV files are still available for backup and audit, but the workbook is the clean business view.

Folder map:

- `01 All Leads` has the master viewer shortcut and a raw master backup.
- `02 By Niche` has service-category folders like HVAC, Plumbing, Roofing, Locksmith, and more.
- `03 Latest Runs` points to collector run folders.
- `04 Reports` points to status and daily reports.
- `05 Pending And Rejected` points to rows that need more evidence or were rejected.
- `06 System And Logs` points to the project and automation logs.

Rule: do not edit the raw master CSV by hand. Use the polished workbook for viewing and the LeadForge scripts for production updates.
"@

Set-Content -LiteralPath (Join-Path $HubDir "START HERE - LeadForge Lead Files.md") -Value $readme -Encoding UTF8
Set-Content -LiteralPath (Join-Path $HubDir "README - LeadForge Files.txt") -Value ($readme -replace '# ', '' -replace '`', '') -Encoding UTF8

[pscustomobject]@{
    hub_dir = $HubDir
    desktop_viewer = $desktopViewer
    niche_folders = $nicheGroups.Count
    total_rows = $rows.Count
}
