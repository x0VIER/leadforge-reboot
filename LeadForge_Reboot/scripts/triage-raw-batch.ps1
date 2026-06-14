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
        $candidate = $url
        if ($candidate -and $candidate -notmatch '^https?://') {
            $candidate = "https://$candidate"
        }
        return ([uri]$candidate).Host.ToLower().TrimStart('w','w','w','.')
    }
    catch {
        return ''
    }
}

function Get-ReviewKey($row) {
    @(
        ([string]$row.business_name).Trim().ToLower(),
        ([string]$row.city).Trim().ToLower(),
        ([string]$row.state).Trim().ToLower(),
        (Get-Host $row.website)
    ) -join '|'
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

function Get-LeadType($row) {
    $niche = if ($row.niche) { ([string]$row.niche).Trim() } else { 'unknown_niche' }
    $city = if ($row.city) { ([string]$row.city).Trim() } else { 'unknown_city' }
    $state = if ($row.state) { ([string]$row.state).Trim() } else { 'unknown_state' }
    return "$niche local service candidate in $city, $state"
}

function Get-RecommendedAction($reasons) {
    if ($reasons -contains 'non_local_supplier_or_manufacturer') {
        return 'reject_for_this_campaign_non_local_supplier_or_manufacturer'
    }
    if ($reasons -contains 'no_public_website_or_phone' -or $reasons -contains 'low_signal_listing') {
        return 'reject_until_public_website_or_phone_is_found'
    }
    if ($reasons -contains 'third_party_contact_path') {
        return 'hold_pending_until_first_party_contact_or_stronger_owner_evidence'
    }
    return 'monitor_or_move_on_until_stronger_public_evidence'
}

function Get-PublicResearchNote($row, $reasons, [string]$decision) {
    $leadType = Get-LeadType $row
    $evidence = if ($row.source_evidence) { ([string]$row.source_evidence).Trim() } else { 'Collector surfaced limited public business evidence.' }
    $reasonText = ($reasons -join ';')
    if ($decision -eq 'rejected') {
        return "$leadType rejected for this campaign. Public checks available in the collector row: $evidence Blockers: $reasonText. Do not contact until the blocker is resolved with stronger public evidence."
    }
    return "$leadType held for owner/contact enrichment. Public checks available in the collector row: $evidence Blockers: $reasonText. Do not guess missing owner, registration, or contact details."
}

function Add-TriageMetadata($row, $reasons, [string]$decision) {
    $copy = $row.PSObject.Copy()
    Add-Member -InputObject $copy -NotePropertyName 'triage_reason' -NotePropertyValue ($reasons -join ';') -Force
    Add-Member -InputObject $copy -NotePropertyName 'lead_type' -NotePropertyValue (Get-LeadType $row) -Force
    Add-Member -InputObject $copy -NotePropertyName 'public_research_note' -NotePropertyValue (Get-PublicResearchNote -row $row -reasons $reasons -decision $decision) -Force
    Add-Member -InputObject $copy -NotePropertyName 'recommended_action' -NotePropertyValue (Get-RecommendedAction $reasons) -Force
    foreach ($field in @('business_address','registration_source','registration_status','registration_notes')) {
        if ($copy.PSObject.Properties.Name -notcontains $field) {
            Add-Member -InputObject $copy -NotePropertyName $field -NotePropertyValue '' -Force
        }
    }
    return $copy
}

$pending = @()
$rejected = @()
$ready = @()
$reviewedKeys = New-Object System.Collections.Generic.HashSet[string]

if ($ReviewedCsv -and (Test-Path -LiteralPath $ReviewedCsv)) {
    $reviewedRows = Import-Csv -LiteralPath (Resolve-Path -LiteralPath $ReviewedCsv)
    foreach ($row in $reviewedRows) {
        $reviewedKey = Get-ReviewKey $row
        [void]$reviewedKeys.Add($reviewedKey)
    }
}

foreach ($row in $rows) {
    $rowKey = Get-ReviewKey $row
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
        $rejected += Add-TriageMetadata -row $row -reasons $reasons -decision 'rejected'
        continue
    }

    $pendingReasons = @()
    if (-not $row.owner_name) { $pendingReasons += 'missing_owner' }
    if (-not $row.owner_source) { $pendingReasons += 'missing_owner_source' }
    if (Test-ThirdPartyContactPath $row.contact_url) { $pendingReasons += 'third_party_contact_path' }
    if (-not $row.contact_url) { $pendingReasons += 'missing_first_party_contact_path' }

    if ($pendingReasons.Count -gt 0) {
        $pending += Add-TriageMetadata -row $row -reasons $pendingReasons -decision 'pending'
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
