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
    Niche = (Join-Path $HubDir "01 Leads By Niche")
    Review = (Join-Path $HubDir "02 Pending Review")
    Reports = (Join-Path $HubDir "03 Reports")
    Audit = (Join-Path $HubDir "99 Audit Backups")
    RawCsv = (Join-Path $HubDir "99 Audit Backups\Raw CSV Exports")
    Legacy = (Join-Path $HubDir "99 Audit Backups\Legacy Hub Layout")
    System = (Join-Path $HubDir "99 Audit Backups\System Links")
}

foreach ($path in $folders.Values) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function Move-GeneratedItemToLegacy {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    if ([System.IO.Path]::GetExtension($Path) -eq ".xlsx" -and -not (Test-WorkbookWritable -Path $Path)) {
        Write-Warning "Kept open workbook in place instead of moving it to legacy: $Path"
        return
    }
    $name = Split-Path -Leaf $Path
    $destination = Join-Path $folders.Legacy $name
    if (Test-Path -LiteralPath $destination) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $destination = Join-Path $folders.Legacy "$stamp - $name"
    }
    Move-Item -LiteralPath $Path -Destination $destination
}

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
    $safe = $safe -replace '\bHvac\b', 'HVAC'
    $safe = $safe -replace '\bSeo\b', 'SEO'
    $safe = $safe -replace '[\\/:*?"<>|]', ''
    if (-not $safe) { return "Unknown" }
    return $safe
}

function Test-WorkbookWritable {
    param([Parameter(Mandatory = $true)][string]$Path)

    $folder = Split-Path -Parent $Path
    $name = Split-Path -Leaf $Path
    $lockFile = Join-Path $folder ".~lock.$name#"
    if (Test-Path -LiteralPath $lockFile) {
        return $false
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        return $true
    }

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

# The desktop hub is generated output, so stale generated clutter is moved into
# audit storage instead of being deleted. Source project data is never moved.
$legacyTopLevelNames = @(
    "01 All Leads",
    "02 By Niche",
    "03 Latest Runs",
    "04 Reports",
    "05 Pending And Rejected",
    "06 System And Logs",
    "Open All Leads Folder.lnk",
    "Open By Niche Folder.lnk",
    "OPEN DASHBOARD - Polished Lead Viewer.lnk",
    "Open Latest Runs Folder.lnk",
    "Open Reports Folder.lnk",
    "LeadForge Master Viewer.xlsx",
    "Open Daily Reports Folder.lnk",
    "Open LeadForge Data Folder.lnk",
    "Open LibreOffice Calc.lnk",
    "Open Master Leads in LibreOffice Calc.lnk",
    "Open Reviewed Run Folders.lnk",
    "Open Status Reports Folder.lnk",
    "Open Today New Lead CSV Outputs.lnk"
)
foreach ($item in $legacyTopLevelNames) {
    Move-GeneratedItemToLegacy -Path (Join-Path $HubDir $item)
}

$desktopViewer = Join-Path $HubDir "OPEN ME - LeadForge Master Viewer.xlsx"
if (Test-WorkbookWritable -Path $desktopViewer) {
    Copy-Item -LiteralPath $ViewerXlsx -Destination $desktopViewer -Force
} else {
    Write-Warning "Desktop master viewer is open or locked by LibreOffice; skipped overwriting it this cycle."
}
Copy-Item -LiteralPath $MasterCsv -Destination (Join-Path $folders.RawCsv "master_leads_raw_backup.csv") -Force

$python = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if (-not (Test-Path -LiteralPath $python)) {
    $python = "python"
}

$nicheJson = Join-Path $env:TEMP "leadforge_niche_views.json"
$rows = @(Import-Csv -LiteralPath $MasterCsv)
$nicheBuckets = [ordered]@{}
foreach ($row in $rows) {
    $displayName = Get-SafeName $row.niche
    if (-not $nicheBuckets.Contains($displayName)) {
        $nicheBuckets[$displayName] = [pscustomobject]@{
            name = $displayName
            rawValues = [System.Collections.Generic.HashSet[string]]::new()
            rows = [System.Collections.ArrayList]::new()
        }
    }
    [void]$nicheBuckets[$displayName].rawValues.Add([string]$row.niche)
    [void]$nicheBuckets[$displayName].rows.Add($row)
}
$nicheGroups = @($nicheBuckets.Values | Sort-Object { $_.rows.Count } -Descending)
$nichePayload = @()
$skippedNicheViews = @()
foreach ($group in $nicheGroups) {
    $nicheName = $group.name
    $nicheXlsx = Join-Path $folders.Niche "$nicheName Leads.xlsx"
    if (-not (Test-WorkbookWritable -Path $nicheXlsx)) {
        Write-Warning "Skipped rebuilding open or locked niche workbook: $nicheXlsx"
        $skippedNicheViews += $nicheXlsx
        continue
    }
    $nichePayload += [pscustomobject]@{
        name = $nicheName
        rawValues = @($group.rawValues)
        xlsx = $nicheXlsx
        csv = (Join-Path $folders.RawCsv "$nicheName Leads - Raw Export.csv")
    }
    $group.rows | Export-Csv -LiteralPath (Join-Path $folders.RawCsv "$nicheName Leads - Raw Export.csv") -NoTypeInformation
}
$nicheJsonText = $nichePayload | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($nicheJson, $nicheJsonText, [System.Text.UTF8Encoding]::new($false))

$builder = Join-Path $env:TEMP "leadforge_niche_view_builder.py"
@'
import csv
import json
import os
import sys
from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

master_csv, payload_json = sys.argv[1:3]

def clean(value):
    if value is None:
        return ""
    return str(value).replace("\r", " ").replace("\n", " ").strip()

def pretty_header(value):
    labels = {
        "lead_id": "Lead ID",
        "business_name": "Business Name",
        "niche": "Niche",
        "city": "City",
        "state": "State",
        "website": "Website",
        "public_phone": "Public Phone",
        "public_email": "Public Email",
        "contact_url": "Contact URL",
        "owner_name": "Owner Name",
        "owner_title": "Owner Title",
        "owner_source": "Owner Source",
        "source_evidence": "Source Evidence",
        "visible_gap": "Visible Gap",
        "offer_angle": "Offer Angle",
        "risk_score_1_5": "Risk Score",
        "validation_status": "Validation Status",
        "priority_tier": "Priority Tier",
        "last_checked": "Last Checked",
    }
    return labels.get(value, clean(value).replace("_", " ").replace("-", " ").title())

def human_value(header, value):
    text = clean(value)
    if header in {"niche", "validation_status", "priority_tier"}:
        return text.replace("_", " ").replace("-", " ").title().replace("Hvac", "HVAC").replace("Seo", "SEO")
    return text

with open(master_csv, "r", encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))
headers = list(rows[0].keys()) if rows else []
payload = json.load(open(payload_json, "r", encoding="utf-8-sig"))

view_cols = [
    "lead_id", "business_name", "city", "state", "website", "public_phone",
    "owner_name", "owner_title", "visible_gap", "offer_angle",
    "validation_status", "priority_tier", "last_checked"
]
view_cols = [h for h in view_cols if h in headers]
all_cols = headers

palette = {
    "navy": "102033",
    "teal": "0E7C7B",
    "gold": "C18C2A",
    "paper": "FFF8EA",
    "soft": "EFE5D1",
    "line": "CABFAF",
    "white": "FFFFFF",
}
thin = Side(style="thin", color=palette["line"])
border = Border(left=thin, right=thin, top=thin, bottom=thin)

def set_widths(ws, cols):
    widths = {
        "lead_id": 12,
        "business_name": 34,
        "city": 16,
        "state": 10,
        "website": 44,
        "public_phone": 18,
        "owner_name": 24,
        "owner_title": 22,
        "visible_gap": 58,
        "offer_angle": 58,
        "validation_status": 22,
        "priority_tier": 18,
        "last_checked": 16,
        "owner_source": 55,
        "source_evidence": 70,
    }
    for i, col in enumerate(cols, start=1):
        ws.column_dimensions[get_column_letter(i)].width = widths.get(col, 18)

def write_sheet(ws, title, subtitle, cols, data_rows, compact=False):
    ws.sheet_view.showGridLines = False
    ws.sheet_view.zoomScale = 90
    ws.sheet_view.topLeftCell = "A1"
    if ws.sheet_view.selection:
        ws.sheet_view.selection[0].activeCell = "A1"
        ws.sheet_view.selection[0].sqref = "A1"
    ws["A1"] = title
    ws["A2"] = subtitle
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=max(len(cols), 6))
    ws.merge_cells(start_row=2, start_column=1, end_row=2, end_column=max(len(cols), 6))
    ws["A1"].font = Font(name="Segoe UI Semibold", size=20, bold=True, color=palette["white"])
    ws["A2"].font = Font(name="Segoe UI", size=11, color="E5EEF7")
    ws["A1"].fill = PatternFill("solid", fgColor=palette["navy"])
    ws["A2"].fill = PatternFill("solid", fgColor=palette["navy"])
    for c, header in enumerate(cols, start=1):
        cell = ws.cell(4, c, pretty_header(header))
        cell.font = Font(name="Segoe UI Semibold", size=10, bold=True, color=palette["white"])
        cell.fill = PatternFill("solid", fgColor=palette["teal"])
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = border
    for r, row in enumerate(data_rows, start=5):
        fill = PatternFill("solid", fgColor=palette["paper"] if r % 2 else palette["soft"])
        for c, header in enumerate(cols, start=1):
            value = human_value(header, row.get(header, ""))
            cell = ws.cell(r, c, value)
            cell.fill = fill
            cell.border = border
            cell.font = Font(name="Segoe UI", size=10, color="111827")
            cell.alignment = Alignment(vertical="top", wrap_text=not compact)
            if header in {"website", "contact_url", "owner_source"} and value.lower().startswith(("http://", "https://")):
                cell.hyperlink = value
                cell.font = Font(name="Segoe UI", size=10, color="0F766E", underline="single")
        ws.row_dimensions[r].height = 24 if compact else 42
    last_row = max(5, 4 + len(data_rows))
    ws.freeze_panes = "A5"
    ws.auto_filter.ref = f"A4:{get_column_letter(max(len(cols), 1))}{last_row}"
    ws.row_dimensions[1].height = 30
    ws.row_dimensions[2].height = 22
    ws.row_dimensions[4].height = 32
    set_widths(ws, cols)

for item in payload:
    raw_values = set(item.get("rawValues") or [])
    data_rows = [r for r in rows if clean(r.get("niche", "")) in raw_values]
    wb = Workbook()
    ws = wb.active
    ws.title = "Lead View"
    ws.sheet_properties.tabColor = "0E7C7B"
    write_sheet(ws, f'{item["name"]} Leads', "Polished lead view. Open this instead of CSV so there is no import popup.", view_cols, data_rows)
    ws2 = wb.create_sheet("Full Source Data")
    ws2.sheet_properties.tabColor = "102033"
    write_sheet(ws2, f'{item["name"]} Full Source Data', "Every source column for this niche, kept readable for audit and AI review.", all_cols, data_rows, compact=True)
    ws3 = wb.create_sheet("How To Use")
    ws3.sheet_properties.tabColor = "C18C2A"
    write_sheet(
        ws3,
        "How To Use This File",
        "Simple rule: use Lead View first; Full Source Data is for deeper review.",
        ["section", "note"],
        [
            {"section": "Best view", "note": "Lead View has the clean business fields for human reading."},
            {"section": "Deep view", "note": "Full Source Data keeps every field without forcing CSV import settings."},
            {"section": "Raw CSV", "note": "Raw CSV backups are stored in 99 Audit Backups and are not meant for normal opening."},
        ],
    )
    wb.active = 0
    os.makedirs(os.path.dirname(item["xlsx"]), exist_ok=True)
    wb.save(item["xlsx"])
    print(item["xlsx"])
'@ | Set-Content -LiteralPath $builder -Encoding UTF8

& $python $builder $MasterCsv $nicheJson
if ($LASTEXITCODE -ne 0) {
    throw "Niche XLSX builder failed with exit code $LASTEXITCODE"
}

$explorer = Join-Path $env:WINDIR "explorer.exe"
New-HubShortcut -Path (Join-Path $HubDir "Open LeadForge Lead Folder.lnk") -Target $explorer -Arguments "`"$HubDir`""
New-HubShortcut -Path (Join-Path $folders.Niche "Open Master Viewer.lnk") -Target $desktopViewer
New-HubShortcut -Path (Join-Path $folders.Review "Open Pending Review Source Folder.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'data\runs')`""
New-HubShortcut -Path (Join-Path $folders.Reports "Open Status Reports.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'agent_shared\status')`""
New-HubShortcut -Path (Join-Path $folders.Reports "Open Daily Reports.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'reports\daily')`""
New-HubShortcut -Path (Join-Path $folders.System "Open LeadForge Project Folder.lnk") -Target $explorer -Arguments "`"$Root`""
New-HubShortcut -Path (Join-Path $folders.System "Open Automation Logs.lnk") -Target $explorer -Arguments "`"$(Join-Path $Root 'agent_shared\logs')`""

$reportFiles = @(
    (Join-Path $Root "agent_shared\status\OPS_SNAPSHOT.json"),
    (Join-Path $Root "OPS_HEALTH_REPORT.md"),
    (Join-Path $Root "agent_shared\status\OWNER_ENRICHMENT_BACKLOG.csv"),
    (Join-Path $Root "agent_shared\status\PENDING_ENRICHMENT_REPORT.csv"),
    (Join-Path $Root "agent_shared\status\LEAD_MEMORY_INDEX.csv"),
    (Join-Path $Root "agent_shared\status\FACTORY_METRICS.json"),
    (Join-Path $Root "agent_shared\status\OFFER_READINESS_REPORT.csv"),
    (Join-Path $Root "agent_shared\status\OFFER_READINESS_REPORT.json"),
    (Join-Path $Root "agent_shared\status\OFFER_READINESS_REPORT.md")
)
foreach ($reportFile in $reportFiles) {
    if (Test-Path -LiteralPath $reportFile) {
        Copy-Item -LiteralPath $reportFile -Destination (Join-Path $folders.Reports (Split-Path -Leaf $reportFile)) -Force
    }
}

$pendingFiles = @(Get-ChildItem -Path (Join-Path $Root "data\runs") -Recurse -File -Filter "*.pending-enrichment.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
$rejectedFiles = @(Get-ChildItem -Path (Join-Path $Root "data\runs") -Recurse -File -Filter "*.rejected.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
if ($pendingFiles.Count -gt 0) {
    Copy-Item -LiteralPath $pendingFiles[0].FullName -Destination (Join-Path $folders.RawCsv "latest_pending_enrichment_raw_backup.csv") -Force
}
if ($rejectedFiles.Count -gt 0) {
    Copy-Item -LiteralPath $rejectedFiles[0].FullName -Destination (Join-Path $folders.RawCsv "latest_rejected_raw_backup.csv") -Force
}

$readme = @"
# LeadForge Lead Files

Start here:

OPEN ME - LeadForge Master Viewer.xlsx

That is the polished master workbook. It opens directly in LibreOffice without the CSV import popup.

Simple folder map:

- 01 Leads By Niche: polished XLSX files for each service category.
- 02 Pending Review: shortcuts to rows that need more evidence before outreach.
- 03 Reports: status, health, offer-readiness, daily reports, and handoff notes.
- 99 Audit Backups: raw CSV exports, old generated shortcuts, logs, and system links.

Plain rule:

Use XLSX files for human review. Do not open CSV files unless you are auditing raw data. CSV backups are intentionally tucked away so LibreOffice does not ask import questions during normal viewing.
"@

Set-Content -LiteralPath (Join-Path $HubDir "START HERE - LeadForge Lead Files.md") -Value $readme -Encoding UTF8
Set-Content -LiteralPath (Join-Path $HubDir "README - LeadForge Files.txt") -Value ($readme -replace '# ', '') -Encoding UTF8

[pscustomobject]@{
    hub_dir = $HubDir
    desktop_viewer = $desktopViewer
    niche_xlsx_files_rebuilt = $nichePayload.Count
    niche_xlsx_files_skipped_locked = $skippedNicheViews.Count
    total_rows = $rows.Count
    raw_csv_backup_dir = $folders.RawCsv
}
