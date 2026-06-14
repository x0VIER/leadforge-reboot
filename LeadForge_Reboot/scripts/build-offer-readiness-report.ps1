param(
    [string]$MasterCsv = "",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $MasterCsv) {
    $MasterCsv = Join-Path $Root "data\master_leads.csv"
}
if (-not $OutputDir) {
    $OutputDir = Join-Path $Root "agent_shared\status"
}

$MasterCsv = (Resolve-Path -LiteralPath $MasterCsv).Path
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Get-CleanText {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value -replace "`r", " " -replace "`n", " ").Trim()
}

function Test-HasText {
    param([object]$Value)
    return [bool](Get-CleanText $Value)
}

function Get-PrimaryContactPath {
    param([pscustomobject]$Lead)
    $contactUrl = Get-CleanText $Lead.contact_url
    $email = Get-CleanText $Lead.public_email
    $phone = Get-CleanText $Lead.public_phone
    $website = Get-CleanText $Lead.website

    if ($contactUrl) { return [pscustomobject]@{ Path = $contactUrl; Type = "Contact form or booking URL" } }
    if ($email) { return [pscustomobject]@{ Path = $email; Type = "Public business email" } }
    if ($phone) { return [pscustomobject]@{ Path = $phone; Type = "Public business phone" } }
    if ($website) { return [pscustomobject]@{ Path = $website; Type = "Website review only" } }
    return [pscustomobject]@{ Path = ""; Type = "No safe public contact path yet" }
}

function Get-OfferRecommendations {
    param([pscustomobject]$Lead)
    $website = Get-CleanText $Lead.website
    $visibleGap = (Get-CleanText $Lead.visible_gap).ToLowerInvariant()
    $offerAngle = (Get-CleanText $Lead.offer_angle).ToLowerInvariant()
    $niche = (Get-CleanText $Lead.niche).ToLowerInvariant()
    $offers = New-Object System.Collections.Generic.List[string]

    if (-not $website) {
        [void]$offers.Add("AI Website / No Website Rescue")
        [void]$offers.Add("Google Business Profile and local listing cleanup")
    } else {
        [void]$offers.Add("AI website and conversion audit")
        [void]$offers.Add("AI SEO / GEO local visibility audit")
    }

    if ($visibleGap -match "review|trust|reputation" -or $offerAngle -match "review|trust|reputation") {
        [void]$offers.Add("Reviews and local prominence improvement")
    }
    if ($visibleGap -match "booking|form|contact|estimate|quote|scheduler|phone" -or $offerAngle -match "booking|form|contact|estimate|quote|scheduler|phone") {
        [void]$offers.Add("Conversion path cleanup")
    }
    if ($niche -match "roof|hvac|plumb|electric|locksmith|landscap|tree|pool|garage|window|door|clean|paint|floor|mason|carpent|fenc") {
        [void]$offers.Add("Best services listing placement")
    }

    return (($offers | Select-Object -Unique) -join "; ")
}

function Get-AuditAngles {
    param([pscustomobject]$Lead)
    $angles = New-Object System.Collections.Generic.List[string]
    $website = Get-CleanText $Lead.website
    $phone = Get-CleanText $Lead.public_phone
    $email = Get-CleanText $Lead.public_email
    $contactUrl = Get-CleanText $Lead.contact_url

    if ($website) {
        [void]$angles.Add("Website UX and conversion path")
        [void]$angles.Add("AI answer visibility and service-area content")
    } else {
        [void]$angles.Add("No-website public presence gap")
    }
    if (-not $contactUrl) { [void]$angles.Add("Missing or weak contact page") }
    if (-not $email) { [void]$angles.Add("No public email on file") }
    if (-not $phone) { [void]$angles.Add("No public phone on file") }
    [void]$angles.Add("Local SEO relevance, distance, and prominence")
    [void]$angles.Add("Competitor comparison and local trust signals")
    [void]$angles.Add("Reviews, citations, and listing consistency")

    return (($angles | Select-Object -Unique) -join "; ")
}

function Get-QualificationScore {
    param([pscustomobject]$Lead)
    $score = 0
    $status = (Get-CleanText $Lead.validation_status).ToLowerInvariant()
    $riskText = Get-CleanText $Lead.risk_score_1_5
    $risk = 3
    [void][int]::TryParse($riskText, [ref]$risk)

    if (Test-HasText $Lead.owner_name) { $score += 12 }
    if (Test-HasText $Lead.owner_source) { $score += 12 }
    if (Test-HasText $Lead.website) { $score += 12 } else { $score += 8 }
    if (Test-HasText $Lead.public_phone) { $score += 10 }
    if (Test-HasText $Lead.public_email) { $score += 8 }
    if (Test-HasText $Lead.contact_url) { $score += 8 }
    if (Test-HasText $Lead.visible_gap) { $score += 10 }
    if (Test-HasText $Lead.offer_angle) { $score += 10 }
    if ($status -match "reviewed|validated|public|verified") { $score += 12 }
    if ($risk -le 1) { $score += 6 } elseif ($risk -eq 2) { $score += 4 } elseif ($risk -ge 4) { $score -= 10 }

    if ($score -lt 0) { return 0 }
    if ($score -gt 100) { return 100 }
    return $score
}

function Get-QualificationTier {
    param([int]$Score)
    if ($Score -ge 80) { return "A - Offer Ready" }
    if ($Score -ge 65) { return "B - Strong Audit Candidate" }
    if ($Score -ge 45) { return "C - Needs More Evidence" }
    return "D - Hold / Research First"
}

function Get-ContactStrategyNote {
    param([pscustomobject]$Lead)
    $business = Get-CleanText $Lead.business_name
    $gap = Get-CleanText $Lead.visible_gap
    $offer = Get-CleanText $Lead.offer_angle
    $contact = Get-PrimaryContactPath -Lead $Lead

    if (-not $contact.Path) {
        return "Do not contact yet. First find a safe public business contact path and verify identity."
    }

    $valuePoint = if ($gap) { $gap } elseif ($offer) { $offer } else { "a short public-facing audit note" }
    return "Value-first opener for ${business}: mention $valuePoint, offer a quick audit snapshot, and avoid generic pitching. Use $($contact.Type) only as the visible public business contact path."
}

function Get-NextAction {
    param([int]$Score, [pscustomobject]$Lead)
    if (-not (Test-HasText $Lead.owner_name) -or -not (Test-HasText $Lead.owner_source)) {
        return "Research owner or decision-maker from public official/social/business sources before outreach."
    }
    if (-not (Test-HasText $Lead.public_phone) -and -not (Test-HasText $Lead.public_email) -and -not (Test-HasText $Lead.contact_url)) {
        return "Find safe public business contact path before outreach."
    }
    if ($Score -ge 80) { return "Prepare AI audit and value-first offer brief." }
    if ($Score -ge 65) { return "Run website/local visibility audit and competitor scan." }
    return "Keep in research queue until evidence and contact path improve."
}

$leads = @(Import-Csv -LiteralPath $MasterCsv)
$reportRows = foreach ($lead in $leads) {
    $contact = Get-PrimaryContactPath -Lead $lead
    $score = Get-QualificationScore -Lead $lead
    $ownerPhoneNote = if (Test-HasText $lead.public_phone) {
        "Public business phone on file; no owner-direct number verified unless owner source explicitly says so."
    } else {
        "No safe public phone on file yet."
    }

    [pscustomobject]@{
        lead_id = Get-CleanText $lead.lead_id
        business_name = Get-CleanText $lead.business_name
        niche = Get-CleanText $lead.niche
        city = Get-CleanText $lead.city
        state = Get-CleanText $lead.state
        website = Get-CleanText $lead.website
        public_phone = Get-CleanText $lead.public_phone
        public_email = Get-CleanText $lead.public_email
        contact_url = Get-CleanText $lead.contact_url
        owner_name = Get-CleanText $lead.owner_name
        owner_title = Get-CleanText $lead.owner_title
        public_owner_or_business_phone = Get-CleanText $lead.public_phone
        owner_number_note = $ownerPhoneNote
        owner_source = Get-CleanText $lead.owner_source
        source_evidence = Get-CleanText $lead.source_evidence
        primary_contact_path = $contact.Path
        contact_point_type = $contact.Type
        lead_qualification_score = $score
        qualification_tier = Get-QualificationTier -Score $score
        offer_recommendations = Get-OfferRecommendations -Lead $lead
        audit_angles = Get-AuditAngles -Lead $lead
        competitor_research_needed = "Find 3 to 5 same-city/same-niche competitors; compare website, reviews, local visibility, offers, speed/contact path, and trust signals."
        contact_strategy_note = Get-ContactStrategyNote -Lead $lead
        compliance_note = "Public-source research only. SMS/WhatsApp outreach requires opt-in and opt-out workflow before automation."
        next_action = Get-NextAction -Score $score -Lead $lead
        last_checked = Get-CleanText $lead.last_checked
    }
}

$csvPath = Join-Path $OutputDir "OFFER_READINESS_REPORT.csv"
$jsonPath = Join-Path $OutputDir "OFFER_READINESS_REPORT.json"
$mdPath = Join-Path $OutputDir "OFFER_READINESS_REPORT.md"

$reportRows | Sort-Object @{ Expression = "lead_qualification_score"; Descending = $true }, business_name |
    Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$summary = [ordered]@{
    generated_at = (Get-Date).ToString("s")
    source = $MasterCsv
    rows = $reportRows.Count
    tier_counts = @($reportRows | Group-Object qualification_tier | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ tier = $_.Name; count = $_.Count }
    })
    contact_type_counts = @($reportRows | Group-Object contact_point_type | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ contact_point_type = $_.Name; count = $_.Count }
    })
    top_offer_ready = @($reportRows | Sort-Object @{ Expression = "lead_qualification_score"; Descending = $true }, business_name | Select-Object -First 25)
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$topRows = @($reportRows | Sort-Object @{ Expression = "lead_qualification_score"; Descending = $true }, business_name | Select-Object -First 20)
$tierLines = @($summary.tier_counts | ForEach-Object { "- $($_.tier): $($_.count)" })
$contactLines = @($summary.contact_type_counts | ForEach-Object { "- $($_.contact_point_type): $($_.count)" })
$topLines = @($topRows | ForEach-Object {
    "- $($_.lead_id) | $($_.business_name) | $($_.niche) | $($_.city), $($_.state) | score $($_.lead_qualification_score) | $($_.qualification_tier) | $($_.offer_recommendations)"
})

$markdown = @(
    "# Offer Readiness Report",
    "",
    "Generated: $((Get-Date).ToString('s'))",
    "",
    "Source: $MasterCsv",
    "",
    "This report is a sidecar planning view. It does not mutate master leads and it does not authorize outreach by itself.",
    "",
    "## Tier Counts",
    "",
    $tierLines,
    "",
    "## Contact Path Counts",
    "",
    $contactLines,
    "",
    "## Top Offer-Ready Leads",
    "",
    $topLines,
    "",
    "## Process Notes",
    "",
    "- Owner-direct numbers are only stored when clearly public for business use. Otherwise use public business phone only.",
    "- Social media is allowed as public OSINT evidence when it verifies business identity, decision-maker context, contact path, or offer fit.",
    "- Every serious outreach should start with a value-first audit note, not a generic pitch.",
    "- SMS and WhatsApp automation require opt-in and opt-out handling before use."
)
$markdown | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    csv = $csvPath
    json = $jsonPath
    markdown = $mdPath
    rows = $reportRows.Count
    top_score = (($reportRows | Measure-Object lead_qualification_score -Maximum).Maximum)
} | ConvertTo-Json -Depth 4
