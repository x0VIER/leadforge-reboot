param(
  [string]$SourceCsv = "",
  [string]$OutputDir = "",
  [switch]$OpenAfterBuild
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $SourceCsv) {
  $SourceCsv = Join-Path $Root "data\master_leads.csv"
}
if (-not $OutputDir) {
  $OutputDir = Join-Path $Root "data\views"
}

$SourceCsv = (Resolve-Path $SourceCsv).Path
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$python = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if (-not (Test-Path $python)) {
  $python = "python"
}

$outputXlsx = Join-Path $OutputDir "LeadForge_Master_Viewer.xlsx"
$desktopDir = Join-Path ([Environment]::GetFolderPath("Desktop")) "LeadForge Lead Files"
New-Item -ItemType Directory -Force -Path $desktopDir | Out-Null
$desktopXlsx = Join-Path $desktopDir "OPEN ME - LeadForge Master Viewer.xlsx"

$builder = Join-Path $env:TEMP "leadforge_viewer_builder.py"
@'
import csv
import os
import sys
from collections import Counter
from datetime import datetime

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.formatting.rule import FormulaRule
from openpyxl.utils import get_column_letter

source_csv, output_xlsx, desktop_xlsx = sys.argv[1:4]

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
        "email": "Email",
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
        "triage_reason": "Triage Reason",
        "lead_type": "Lead Type",
        "public_research_note": "Public Research Note",
        "recommended_action": "Recommended Action",
    }
    return labels.get(value, clean(value).replace("_", " ").replace("-", " ").title())

def pretty_value(header, value):
    text = clean(value)
    if not text:
        return ""
    exact_fields = {"lead_id", "website", "contact_url", "email", "owner_source", "source_evidence"}
    if header in exact_fields:
        return text
    humanized_fields = {"validation_status", "priority_tier", "lead_type", "triage_reason", "recommended_action", "niche"}
    if header in humanized_fields:
        if text.strip() in {"?", "1", "2", "0"}:
            return "Unknown / Legacy"
        label = text.replace("_", " ").replace("-", " ").title()
        return label.replace("Hvac", "HVAC").replace("Seo", "SEO").replace("Url", "URL")
    return text

with open(source_csv, "r", encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))

headers = list(rows[0].keys()) if rows else []

selected = [
    "lead_id", "business_name", "niche", "city", "state", "website", "public_phone",
    "owner_name", "owner_title", "owner_source", "visible_gap", "offer_angle",
    "risk_score_1_5", "validation_status", "priority_tier", "last_checked"
]
selected = [h for h in selected if h in headers]

callback_cols = [
    "lead_id", "business_name", "niche", "city", "state", "website", "public_phone",
    "owner_name", "owner_title", "validation_status", "priority_tier", "source_evidence",
    "last_checked"
]
callback_cols = [h for h in callback_cols if h in headers]

evidence_cols = [
    "lead_id", "business_name", "owner_name", "owner_title", "owner_source",
    "source_evidence", "website", "city", "state", "last_checked"
]
evidence_cols = [h for h in evidence_cols if h in headers]

wb = Workbook()
ws_dash = wb.active
ws_dash.title = "Dashboard"
ws_dash.sheet_properties.tabColor = "0F172A"

ws_source = wb.create_sheet("Full Lead Data")
ws_source.sheet_properties.tabColor = "2DD4BF"
ws_board = wb.create_sheet("Lead Board")
ws_board.sheet_properties.tabColor = "7C3AED"
ws_evidence = wb.create_sheet("Owner Evidence")
ws_evidence.sheet_properties.tabColor = "0D9488"
ws_callback = wb.create_sheet("Callback Queue")
ws_callback.sheet_properties.tabColor = "B45309"
ws_quality = wb.create_sheet("Data Quality")
ws_quality.sheet_properties.tabColor = "64748B"
ws_guide = wb.create_sheet("Field Guide")
ws_guide.sheet_properties.tabColor = "111827"

palette = {
    "navy": "101820",
    "slate": "243447",
    "muted": "617080",
    "line": "C9BFAF",
    "canvas": "E6DED0",
    "soft": "F3EBDD",
    "paper": "FFF8EA",
    "blue": "256D85",
    "teal": "0E7C7B",
    "orange": "B7791F",
    "coral": "C08440",
    "violet": "6C5CE7",
    "green": "0F7B55",
    "amber": "B7791F",
    "white": "FFFFFF",
}
thin = Side(style="thin", color=palette["line"])
border = Border(left=thin, right=thin, top=thin, bottom=thin)

def safe_sheet_name(label, existing):
    cleaned = "".join(ch for ch in label if ch not in r'[]:*?/\\').strip()
    if not cleaned:
        cleaned = "Leads"
    cleaned = cleaned[:31]
    base = cleaned
    suffix = 2
    while cleaned in existing:
        tail = f" {suffix}"
        cleaned = (base[:31-len(tail)] + tail)
        suffix += 1
    existing.add(cleaned)
    return cleaned

def style_title(ws, title, subtitle):
    ws.sheet_view.showGridLines = False
    for row in ws.iter_rows(min_row=1, max_row=80, min_col=1, max_col=18):
        for cell in row:
            cell.fill = PatternFill("solid", fgColor=palette["canvas"])
    ws["A1"] = title
    ws["A1"].font = Font(name="Segoe UI Semibold", size=24, bold=True, color=palette["white"])
    ws["A1"].fill = PatternFill("solid", fgColor=palette["navy"])
    ws["A2"] = subtitle
    ws["A2"].font = Font(name="Segoe UI", size=11, color="DDE7F3")
    ws["A2"].fill = PatternFill("solid", fgColor=palette["navy"])
    ws.merge_cells("A1:H1")
    ws.merge_cells("A2:H2")
    ws.row_dimensions[1].height = 34
    ws.row_dimensions[2].height = 24

def write_table(ws, table_headers, table_rows, title, subtitle, header_color, compact_rows=False, wrap_text=True):
    style_title(ws, title, subtitle)
    start_row = 4
    for col_idx, header in enumerate(table_headers, start=1):
        cell = ws.cell(start_row, col_idx, pretty_header(header))
        cell.font = Font(name="Segoe UI Semibold", bold=True, color=palette["white"])
        cell.fill = PatternFill("solid", fgColor=header_color)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = border
    for row_idx, row in enumerate(table_rows, start=start_row + 1):
        fill = PatternFill("solid", fgColor=(palette["paper"] if row_idx % 2 else palette["soft"]))
        for col_idx, header in enumerate(table_headers, start=1):
            value = pretty_value(header, row.get(header, ""))
            cell = ws.cell(row_idx, col_idx, value)
            cell.fill = fill
            cell.border = border
            cell.font = Font(name="Segoe UI", size=10, color="111827")
            cell.alignment = Alignment(vertical="top", wrap_text=wrap_text)
            if header in {"website", "contact_url"} and value.lower().startswith(("http://", "https://")):
                cell.hyperlink = value
                cell.font = Font(name="Segoe UI", size=10, color="0F766E", underline="single")
    last_row = max(start_row + len(table_rows), start_row + 1)
    last_col = max(len(table_headers), 1)
    ws.freeze_panes = "A5"
    ws.auto_filter.ref = f"A{start_row}:{get_column_letter(last_col)}{last_row}"
    ws.row_dimensions[start_row].height = 32
    for row_num in range(start_row + 1, last_row + 1):
        ws.row_dimensions[row_num].height = 24 if compact_rows else 42
    set_widths(ws, table_headers)
    apply_status_colors(ws, table_headers, start_row + 1, last_row)

def set_widths(ws, table_headers):
    widths = {
        "lead_id": 12,
        "business_name": 34,
        "niche": 16,
        "city": 16,
        "state": 10,
        "website": 42,
        "public_phone": 18,
        "owner_name": 24,
        "owner_title": 22,
        "owner_source": 52,
        "source_evidence": 72,
        "visible_gap": 58,
        "offer_angle": 62,
        "risk_score_1_5": 14,
        "validation_status": 20,
        "priority_tier": 15,
        "last_checked": 16,
    }
    for idx, header in enumerate(table_headers, start=1):
        ws.column_dimensions[get_column_letter(idx)].width = widths.get(header, 18)

def apply_status_colors(ws, table_headers, first_row, last_row):
    if not table_headers or last_row < first_row:
        return
    if "validation_status" in table_headers:
        col = get_column_letter(table_headers.index("validation_status") + 1)
        ws.conditional_formatting.add(
            f"{col}{first_row}:{col}{last_row}",
            FormulaRule(formula=[f'ISNUMBER(SEARCH("strong",{col}{first_row}))'], fill=PatternFill("solid", fgColor="DCFCE7"), font=Font(color="166534", bold=True))
        )
        ws.conditional_formatting.add(
            f"{col}{first_row}:{col}{last_row}",
            FormulaRule(formula=[f'ISNUMBER(SEARCH("pending",{col}{first_row}))'], fill=PatternFill("solid", fgColor="FEF3C7"), font=Font(color="92400E", bold=True))
        )
        ws.conditional_formatting.add(
            f"{col}{first_row}:{col}{last_row}",
            FormulaRule(formula=[f'ISNUMBER(SEARCH("reject",{col}{first_row}))'], fill=PatternFill("solid", fgColor="FDECC8"), font=Font(color="7C2D12", bold=True))
        )
    if "priority_tier" in table_headers:
        col = get_column_letter(table_headers.index("priority_tier") + 1)
        ws.conditional_formatting.add(
            f"{col}{first_row}:{col}{last_row}",
            FormulaRule(formula=[f'OR(ISNUMBER(SEARCH("A",{col}{first_row})),ISNUMBER(SEARCH("high",{col}{first_row})))'], fill=PatternFill("solid", fgColor="DBEAFE"), font=Font(color="1D4ED8", bold=True))
        )

def count_missing(field):
    return sum(1 for r in rows if not clean(r.get(field, "")))

state_counts = Counter(clean(r.get("state", "")) or "Unknown" for r in rows)
niche_counts = Counter(clean(r.get("niche", "")) or "Unknown" for r in rows)
status_counts = Counter(clean(r.get("validation_status", "")) or "Unknown" for r in rows)

field_descriptions = {
    "lead_id": "Internal LeadForge ID for callback and dedupe.",
    "business_name": "Public business name as discovered or verified.",
    "niche": "Service category or business type.",
    "city": "Primary city for the lead.",
    "state": "State abbreviation or target geography.",
    "website": "Public website used for identity/contact review.",
    "public_phone": "Public business phone, not guessed personal phone.",
    "email": "Public business email when available.",
    "contact_url": "Best public contact, quote, booking, or inquiry page.",
    "owner_name": "Owner or decision-maker name verified from public evidence.",
    "owner_title": "Owner or decision-maker title.",
    "owner_source": "Public source that supports the owner/decision-maker claim.",
    "source_evidence": "Short factual note describing public evidence used.",
    "visible_gap": "Observed website/contact/marketing gap that creates an offer angle.",
    "offer_angle": "Plain-English reason this business may benefit from outreach.",
    "risk_score_1_5": "Lead quality risk score. Lower is safer.",
    "validation_status": "Current QA/evidence status for the row.",
    "priority_tier": "Outreach priority tier based on fit and evidence.",
    "last_checked": "Most recent date the row was checked.",
    "triage_reason": "Why a row was rejected or routed away from final merge.",
    "lead_type": "Useful classification such as local service, supplier, chain, or pending enrichment.",
    "public_research_note": "Human-readable note on what was checked and what is still missing.",
    "recommended_action": "Next step for rejected or pending rows.",
}

critical_fields = ["business_name", "niche", "city", "state", "website", "public_phone", "owner_name", "owner_source", "source_evidence", "validation_status", "last_checked"]

style_title(ws_dash, "LeadForge Master Viewer", "Clean lead board generated for human review. The live master source file stays separate so automation can keep merging safely.")
cards = [
    ("Total Leads", len(rows), palette["teal"]),
    ("States Covered", len(state_counts), palette["blue"]),
    ("Missing Owner", count_missing("owner_name"), palette["amber"]),
    ("Missing Website", count_missing("website"), palette["coral"]),
]
for idx, (label, value, color) in enumerate(cards):
    col = 1 + idx * 2
    ws_dash.cell(4, col, label)
    ws_dash.cell(5, col, value)
    ws_dash.merge_cells(start_row=4, start_column=col, end_row=4, end_column=col + 1)
    ws_dash.merge_cells(start_row=5, start_column=col, end_row=5, end_column=col + 1)
    for r in range(4, 6):
        for c in range(col, col + 2):
            ws_dash.cell(r, c).fill = PatternFill("solid", fgColor=color)
            ws_dash.cell(r, c).border = border
            ws_dash.cell(r, c).alignment = Alignment(horizontal="center", vertical="center")
    ws_dash.cell(4, col).font = Font(name="Segoe UI Semibold", size=11, bold=True, color=palette["white"])
    ws_dash.cell(5, col).font = Font(name="Segoe UI Semibold", size=24, bold=True, color=palette["white"])

for row in ws_dash.iter_rows(min_row=8, max_row=22, min_col=1, max_col=8):
    for cell in row:
        cell.fill = PatternFill("solid", fgColor="E8E3D7")
ws_dash["A8"] = "Top Niches"
ws_dash["D8"] = "Validation Status"
ws_dash["A8"].font = ws_dash["D8"].font = Font(name="Segoe UI Semibold", size=14, bold=True, color=palette["navy"])
for i, (name, count) in enumerate(niche_counts.most_common(10), start=9):
    ws_dash.cell(i, 1, pretty_value("niche", name))
    ws_dash.cell(i, 2, count)
for i, (name, count) in enumerate(status_counts.most_common(10), start=9):
    ws_dash.cell(i, 4, pretty_value("validation_status", name))
    ws_dash.cell(i, 5, count)
for rng in ("A8:B19", "D8:E19"):
    for row in ws_dash[rng]:
        for cell in row:
            cell.border = border
            cell.alignment = Alignment(vertical="center", wrap_text=True)
            if cell.row > 8:
                cell.fill = PatternFill("solid", fgColor=(palette["paper"] if cell.row % 2 else palette["soft"]))
for col in "ABCDEFGH":
    ws_dash.column_dimensions[col].width = 14
ws_dash.column_dimensions["A"].width = 20
ws_dash.column_dimensions["B"].width = 8
ws_dash.column_dimensions["D"].width = 18
ws_dash.column_dimensions["E"].width = 10

write_table(ws_source, headers, rows, "Full Lead Data", "Complete master data with every source column. Use horizontal scroll for full-scope review; nothing is hidden or summarized away.", palette["teal"], compact_rows=True, wrap_text=False)
for row_num in range(5, ws_source.max_row + 1):
    ws_source.row_dimensions[row_num].height = 24
for idx, header in enumerate(headers, start=1):
    col_letter = get_column_letter(idx)
    if header in ("source_evidence", "owner_source", "visible_gap", "offer_angle"):
        ws_source.column_dimensions[col_letter].width = 90
    elif header in ("website", "contact_url"):
        ws_source.column_dimensions[col_letter].width = 52
    elif header in ("business_name", "owner_name"):
        ws_source.column_dimensions[col_letter].width = 36
    else:
        ws_source.column_dimensions[col_letter].width = max(ws_source.column_dimensions[col_letter].width or 0, 18)

write_table(ws_board, selected, rows, "Lead Board", "Readable selling view with owners, websites, offer angles, risk, priority, and validation.", palette["violet"])

existing_sheet_names = set(wb.sheetnames)
niche_palette = [palette["teal"], palette["blue"], palette["orange"], palette["violet"], palette["green"], palette["slate"]]
for niche_index, (niche_name, _count) in enumerate(niche_counts.most_common()):
    niche_rows = [r for r in rows if (clean(r.get("niche", "")) or "Unknown") == niche_name]
    if not niche_rows:
        continue
    label = pretty_value("niche", niche_name)
    sheet_name = safe_sheet_name(f"{label} Leads", existing_sheet_names)
    ws_niche = wb.create_sheet(sheet_name)
    ws_niche.sheet_properties.tabColor = niche_palette[niche_index % len(niche_palette)]
    write_table(
        ws_niche,
        selected,
        niche_rows,
        f"{label} Leads",
        "Filtered polished view for this service category. Full source details remain in Full Lead Data.",
        niche_palette[niche_index % len(niche_palette)],
        compact_rows=False,
        wrap_text=True,
    )

write_table(ws_evidence, evidence_cols, rows, "Owner Evidence", "Owner and decision-maker evidence trail. Use this when checking whether a row is outreach-ready.", palette["teal"])

callback_rows = []
for r in rows:
    missing = []
    if not clean(r.get("owner_name", "")):
        missing.append("owner")
    if not clean(r.get("website", "")):
        missing.append("website")
    if not clean(r.get("public_phone", "")):
        missing.append("phone")
    if "pending" in clean(r.get("validation_status", "")).lower():
        missing.append("pending validation")
    if missing:
        copy = dict(r)
        copy["source_evidence"] = "Missing: " + ", ".join(sorted(set(missing))) + ". " + clean(r.get("source_evidence", ""))
        callback_rows.append(copy)
write_table(ws_callback, callback_cols, callback_rows, "Callback Queue", "Rows needing owner, website, phone, or validation follow-up before clean outreach.", palette["orange"])

quality_rows = []
for field in headers:
    missing = sum(1 for r in rows if not clean(r.get(field, "")))
    filled = len(rows) - missing
    pct = round((filled / len(rows)) * 100, 1) if rows else 0
    quality_rows.append({
        "field": field,
        "field_name": pretty_header(field),
        "filled_rows": filled,
        "missing_rows": missing,
        "filled_percent": f"{pct}%",
        "importance": "Critical" if field in critical_fields else "Support",
        "note": field_descriptions.get(field, "Supporting field used for review, routing, or audit context."),
    })
write_table(ws_quality, ["field_name", "importance", "filled_rows", "missing_rows", "filled_percent", "note"], quality_rows, "Data Quality", "Completeness and field coverage so missing information has a named callback path.", palette["muted"], compact_rows=False, wrap_text=True)

guide_rows = []
for field in headers:
    guide_rows.append({
        "field": field,
        "field_name": pretty_header(field),
        "category": "Core Lead Data" if field in critical_fields else "Support And Notes",
        "description": field_descriptions.get(field, "Supporting field used for review, routing, or audit context."),
        "human_rule": "Keep exact if it is a URL, evidence source, ID, or phone. Otherwise use plain business-readable wording.",
    })
write_table(ws_guide, ["field_name", "category", "description", "human_rule"], guide_rows, "Field Guide", "Plain-English definitions for every column so the lead database is easy to understand and review.", palette["navy"], compact_rows=False, wrap_text=True)

for ws in wb.worksheets:
    ws.sheet_view.zoomScale = 90
    for row in ws.iter_rows():
        for cell in row:
            if cell.value is not None:
                cell.alignment = Alignment(
                    horizontal=cell.alignment.horizontal or "left",
                    vertical=cell.alignment.vertical or "top",
                    wrap_text=cell.alignment.wrap_text,
                )

wb.active = wb.sheetnames.index("Dashboard")
for path in (output_xlsx, desktop_xlsx):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    wb.save(path)

print(output_xlsx)
print(desktop_xlsx)
'@ | Set-Content -LiteralPath $builder -Encoding UTF8

& $python $builder $SourceCsv $outputXlsx $desktopXlsx

if ($OpenAfterBuild) {
  $soffice = Join-Path $env:ProgramFiles "LibreOffice\program\soffice.exe"
  if (Test-Path $soffice) {
    Start-Process -FilePath $soffice -ArgumentList @("--norestore", "`"$desktopXlsx`"")
  } else {
    Invoke-Item -LiteralPath $desktopXlsx
  }
}

Write-Output "LeadForge viewer workbook created:"
Write-Output $outputXlsx
Write-Output $desktopXlsx
