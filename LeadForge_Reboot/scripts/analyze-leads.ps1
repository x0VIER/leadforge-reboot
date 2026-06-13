param(
    [string]$InputCsv,
    [switch]$EmitJson
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $InputCsv) {
    $InputCsv = Join-Path $ScriptDir '..\data\archive\Recovered_Leads_Database_2026-06-12_snapshot.csv'
}

$resolved = Resolve-Path -LiteralPath $InputCsv
$rows = Import-Csv -LiteralPath $resolved

function GroupSummary($items, $property) {
    ($items |
        Group-Object -Property $property |
        Sort-Object Count -Descending |
        ForEach-Object { "{0}={1}" -f $_.Name, $_.Count }) -join '; '
}

$duplicateKeys = $rows |
    Group-Object -Property business_name, city, state, website |
    Where-Object Count -gt 1

$summary = [pscustomobject]@{
    source_csv = $resolved.Path
    row_count = $rows.Count
    state_mix = GroupSummary $rows 'state'
    niche_mix = GroupSummary $rows 'niche'
    priority_mix = GroupSummary $rows 'priority_tier'
    phone_count = ($rows | Where-Object { $_.public_phone }).Count
    email_count = ($rows | Where-Object { $_.public_email }).Count
    website_count = ($rows | Where-Object { $_.website }).Count
    duplicate_groups = $duplicateKeys.Count
    missing_lead_ids = ($rows | Where-Object { -not $_.lead_id }).Count
}

if ($EmitJson) {
    $summary | ConvertTo-Json -Depth 3
    exit 0
}

$summary | Format-List
