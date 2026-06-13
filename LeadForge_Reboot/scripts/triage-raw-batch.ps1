param(
    [Parameter(Mandatory = $true)]
    [string]$InputCsv,
    [string]$ReviewedCsv
)

$resolved = (Resolve-Path -LiteralPath $InputCsv).Path
$rows = Import-Csv -LiteralPath $resolved
$runRoot = Split-Path -Parent (Split-Path -Parent $resolved)
$tmpDir = Join-Path $runRoot 'tmp'
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolved)
$pendingPath = Join-Path $tmpDir "$baseName.pending-enrichment.csv"
$rejectedPath = Join-Path $tmpDir "$baseName.rejected.csv"
$summaryPath = Join-Path $tmpDir "$baseName.triage-summary.json"

foreach ($stalePath in @($pendingPath, $rejectedPath, $summaryPath)) {
    if (Test-Path -LiteralPath $stalePath) {
        Remove-Item -LiteralPath $stalePath -Force
    }
}

function Get-Host([string]$url) {
    try {
        return ([uri]$url).Host.ToLower().TrimStart('w','w','w','.')
    }
    catch {
        return ''
    }
}

function Test-ThirdPartyContactPath([string]$url) {
    if (-not $url) { return $false }
    $contactHost = Get-Host $url
    return $contactHost -match 'facebook\.com|instagram\.com|x\.com|twitter\.com|linkedin\.com|youtube\.com|tiktok\.com|housecallpro\.com'
}

function Test-NonLocalSupplierOrManufacturer($row) {
    $name = ([string]$row.business_name).ToLower()
    $websiteHost = Get-Host $row.website
    if ($name -match '\b(distribution|distributor|wholesale|supply|manufacturing|manufacturer)\b') {
        return $true
    }
    if ($websiteHost -match '(goodmanmfg|daikincomfort|carrierenterprise|ferguson|johnstonesupply)') {
        return $true
    }
    return $false
}

$pending = @()
$rejected = @()
$ready = @()
$reviewedKeys = New-Object System.Collections.Generic.HashSet[string]

if ($ReviewedCsv -and (Test-Path -LiteralPath $ReviewedCsv)) {
    $reviewedRows = Import-Csv -LiteralPath (Resolve-Path -LiteralPath $ReviewedCsv)
    foreach ($row in $reviewedRows) {
        $reviewedKey = @(
            ([string]$row.business_name).Trim().ToLower(),
            ([string]$row.city).Trim().ToLower(),
            ([string]$row.state).Trim().ToLower(),
            ([string]$row.website).Trim().ToLower()
        ) -join '|'
        [void]$reviewedKeys.Add($reviewedKey)
    }
}

foreach ($row in $rows) {
    $rowKey = @(
        ([string]$row.business_name).Trim().ToLower(),
        ([string]$row.city).Trim().ToLower(),
        ([string]$row.state).Trim().ToLower(),
        ([string]$row.website).Trim().ToLower()
    ) -join '|'
    if ($reviewedKeys.Contains($rowKey)) {
        continue
    }

    $reasons = @()

    if (-not $row.website -and -not $row.public_phone) {
        $reasons += 'no_public_website_or_phone'
    }
    if (-not $row.website -and -not $row.public_phone -and -not $row.public_email) {
        $reasons += 'low_signal_listing'
    }
    if (Test-NonLocalSupplierOrManufacturer $row) {
        $reasons += 'non_local_supplier_or_manufacturer'
    }

    if ($reasons.Count -gt 0) {
        $copy = $row.PSObject.Copy()
        Add-Member -InputObject $copy -NotePropertyName 'triage_reason' -NotePropertyValue ($reasons -join ';') -Force
        $rejected += $copy
        continue
    }

    $pendingReasons = @()
    if (-not $row.owner_name) { $pendingReasons += 'missing_owner' }
    if (-not $row.owner_source) { $pendingReasons += 'missing_owner_source' }
    if (Test-ThirdPartyContactPath $row.contact_url) { $pendingReasons += 'third_party_contact_path' }
    if (-not $row.contact_url) { $pendingReasons += 'missing_first_party_contact_path' }

    if ($pendingReasons.Count -gt 0) {
        $copy = $row.PSObject.Copy()
        Add-Member -InputObject $copy -NotePropertyName 'triage_reason' -NotePropertyValue ($pendingReasons -join ';') -Force
        $pending += $copy
        continue
    }

    $ready += $row
}

if ($pending.Count -gt 0) {
    $pending | Export-Csv -LiteralPath $pendingPath -NoTypeInformation
}
if ($rejected.Count -gt 0) {
    $rejected | Export-Csv -LiteralPath $rejectedPath -NoTypeInformation
}

$summary = [ordered]@{
    input_csv = $resolved
    total_rows = $rows.Count
    excluded_reviewed_rows = $reviewedKeys.Count
    reviewed_ready_rows = $ready.Count
    pending_enrichment_rows = $pending.Count
    rejected_rows = $rejected.Count
    pending_csv = if (Test-Path -LiteralPath $pendingPath) { $pendingPath } else { '' }
    rejected_csv = if (Test-Path -LiteralPath $rejectedPath) { $rejectedPath } else { '' }
}

$summary | ConvertTo-Json | Set-Content -LiteralPath $summaryPath

[pscustomobject]$summary | Format-List
