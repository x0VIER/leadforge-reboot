param(
    [string]$State = 'FL',
    [string]$InputCsv,
    [string]$OutputPath,
    [switch]$IncludeSuspiciousRows
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $InputCsv) {
    $InputCsv = Join-Path $ScriptDir '..\data\master_leads.csv'
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $ScriptDir "..\agent_shared\status\OWNER_ENRICHMENT_BACKLOG_$($State.ToUpper()).json"
}
$contaminationAuditPath = Join-Path $ScriptDir "..\agent_shared\status\MASTER_CONTAMINATION_AUDIT_$($State.ToUpper()).json"

function Normalize-Host([string]$url) {
    try {
        return ([uri]$url).Host.ToLower() -replace '^www\.', ''
    }
    catch {
        return ''
    }
}

$resolvedInput = (Resolve-Path -LiteralPath $InputCsv).Path
$rows = Import-Csv -LiteralPath $resolvedInput
$stateRows = @($rows | Where-Object { $_.state -eq $State })
$missingOwnerRows = @($stateRows | Where-Object { -not $_.owner_name })

$suspiciousLeadIds = New-Object System.Collections.Generic.HashSet[string]
if ((-not $IncludeSuspiciousRows) -and (Test-Path -LiteralPath $contaminationAuditPath)) {
    try {
        $audit = Get-Content -LiteralPath $contaminationAuditPath -Raw | ConvertFrom-Json
        foreach ($row in @($audit.suspicious_rows)) {
            if ($row.lead_id) {
                [void]$suspiciousLeadIds.Add([string]$row.lead_id)
            }
        }
    }
    catch {
        # If the audit cannot be read, fall back to the unfiltered backlog.
    }
}

$eligibleMissingOwnerRows = if ($IncludeSuspiciousRows) {
    @($missingOwnerRows)
} else {
    @($missingOwnerRows | Where-Object { -not $suspiciousLeadIds.Contains([string]$_.lead_id) })
}

$topCandidates = @(
    $eligibleMissingOwnerRows |
        Sort-Object @{
            Expression = {
                $score = 0
                if ($_.priority_tier -eq 'P0_offer_ready_review') { $score += 100 }
                elseif ($_.priority_tier -eq 'P1_manual_enrichment') { $score += 60 }
                if ($_.validation_status -eq 'validated_public_business_source') { $score += 20 }
                if ($_.website) { $score += 10 }
                if ($_.public_email) { $score += 5 }
                if ($_.contact_url) { $score += 5 }
                $score
            }
            Descending = $true
        }, niche, city, business_name |
        Select-Object -First 40 `
            lead_id,
            business_name,
            niche,
            city,
            state,
            website,
            public_phone,
            public_email,
            contact_url,
            validation_status,
            priority_tier,
            visible_gap,
            offer_angle
)

$payload = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    input_csv = $resolvedInput
    state = $State
    total_state_rows = $stateRows.Count
    missing_owner_rows = $missingOwnerRows.Count
    suspicious_rows_excluded = if ($IncludeSuspiciousRows) { 0 } else { $missingOwnerRows.Count - $eligibleMissingOwnerRows.Count }
    eligible_missing_owner_rows = $eligibleMissingOwnerRows.Count
    coverage_percent = if ($stateRows.Count -gt 0) {
        [math]::Round((($stateRows.Count - $missingOwnerRows.Count) / $stateRows.Count) * 100, 2)
    } else {
        0
    }
    by_niche = @(
        $eligibleMissingOwnerRows |
            Group-Object niche |
            Sort-Object Count -Descending |
            ForEach-Object {
                [pscustomobject]@{
                    niche = $_.Name
                    missing_owner_rows = $_.Count
                }
            }
    )
    by_city = @(
        $eligibleMissingOwnerRows |
            Group-Object city |
            Sort-Object Count -Descending |
            Select-Object -First 20 |
            ForEach-Object {
                [pscustomobject]@{
                    city = $_.Name
                    missing_owner_rows = $_.Count
                }
            }
    )
    top_candidates = @($topCandidates)
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
$payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath

[pscustomobject]@{
    output_path = $OutputPath
    state = $State
    total_state_rows = $stateRows.Count
    missing_owner_rows = $missingOwnerRows.Count
    eligible_missing_owner_rows = $eligibleMissingOwnerRows.Count
    top_candidate_count = $topCandidates.Count
} | Format-List
