param(
    [string]$OutputJson,
    [string]$OutputCsv
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..')
$statusDir = Join-Path $root 'agent_shared\status'
$runsRoot = Join-Path $root 'data\runs'
$masterCsv = Join-Path $root 'data\master_leads.csv'

if (-not $OutputJson) { $OutputJson = Join-Path $statusDir 'LEAD_MEMORY_INDEX.json' }
if (-not $OutputCsv) { $OutputCsv = Join-Path $statusDir 'LEAD_MEMORY_INDEX.csv' }

New-Item -ItemType Directory -Force -Path $statusDir | Out-Null

function Normalize-Text([string]$value) {
    if (-not $value) { return '' }
    return (($value.ToLowerInvariant() -replace '[^a-z0-9]+', ' ').Trim() -replace '\s+', ' ')
}

function Normalize-Website([string]$value) {
    if (-not $value) { return '' }
    try {
        $uri = [uri]$value
        $host = $uri.Host.ToLowerInvariant() -replace '^www\.', ''
        return $host
    }
    catch {
        return (($value.ToLowerInvariant() -replace '^https?://', '') -replace '^www\.', '').TrimEnd('/')
    }
}

function Get-LeadKey($row) {
    $website = Normalize-Website $row.website
    if ($website) { return "website:$website" }
    $name = Normalize-Text $row.business_name
    $city = Normalize-Text $row.city
    $state = Normalize-Text $row.state
    return "name-city-state:$name|$city|$state"
}

function Get-PropertyValue($row, [string]$name) {
    if ($row -and $row.PSObject.Properties.Name -contains $name) {
        return $row.$name
    }
    return ''
}

$items = New-Object System.Collections.Generic.List[object]

if (Test-Path -LiteralPath $masterCsv) {
    foreach ($row in @(Import-Csv -LiteralPath $masterCsv)) {
        $items.Add([pscustomobject]@{
            lead_key = Get-LeadKey $row
            status = 'master'
            business_name = $row.business_name
            niche = $row.niche
            city = $row.city
            state = $row.state
            website = $row.website
            owner_name = $row.owner_name
            validation_status = $row.validation_status
            triage_reason = ''
            recommended_action = ''
            source_file = 'data/master_leads.csv'
            last_checked = $row.last_checked
        })
    }
}

if (Test-Path -LiteralPath $runsRoot) {
    $runFiles = @(Get-ChildItem -LiteralPath $runsRoot -Recurse -File -Include *.csv)
    foreach ($file in $runFiles) {
        $firstLine = ''
        try {
            $firstLine = Get-Content -LiteralPath $file.FullName -TotalCount 1 -ErrorAction Stop
        }
        catch {
            continue
        }
        if ([string]::IsNullOrWhiteSpace($firstLine) -or $firstLine -notmatch 'business_name') {
            continue
        }

        $relative = $file.FullName.Substring($root.Path.Length).TrimStart('\') -replace '\\', '/'
        $status = if ($relative -match '/final/') {
            'final_artifact'
        } elseif ($relative -match '/reviewed/') {
            'reviewed_artifact'
        } elseif ($relative -match '\.pending-enrichment\.csv$') {
            'pending'
        } elseif ($relative -match '\.rejected\.csv$') {
            'rejected'
        } elseif ($relative -match '/raw/') {
            'raw'
        } else {
            'artifact'
        }

        foreach ($row in @(Import-Csv -LiteralPath $file.FullName)) {
            if (-not (Get-PropertyValue $row 'business_name')) { continue }
            $items.Add([pscustomobject]@{
                lead_key = Get-LeadKey $row
                status = $status
                business_name = Get-PropertyValue $row 'business_name'
                niche = Get-PropertyValue $row 'niche'
                city = Get-PropertyValue $row 'city'
                state = Get-PropertyValue $row 'state'
                website = Get-PropertyValue $row 'website'
                owner_name = Get-PropertyValue $row 'owner_name'
                validation_status = Get-PropertyValue $row 'validation_status'
                triage_reason = Get-PropertyValue $row 'triage_reason'
                recommended_action = Get-PropertyValue $row 'recommended_action'
                source_file = $relative
                last_checked = Get-PropertyValue $row 'last_checked'
            })
        }
    }
}

$grouped = @(
    $items |
        Group-Object lead_key |
        Sort-Object Count -Descending |
        ForEach-Object {
            $latest = @($_.Group | Sort-Object last_checked -Descending | Select-Object -First 1)[0]
            [pscustomobject]@{
                lead_key = $_.Name
                occurrence_count = $_.Count
                statuses = (@($_.Group.status | Sort-Object -Unique) -join ';')
                business_name = $latest.business_name
                niche = $latest.niche
                city = $latest.city
                state = $latest.state
                website = $latest.website
                owner_name = $latest.owner_name
                validation_status = $latest.validation_status
                triage_reason = $latest.triage_reason
                recommended_action = $latest.recommended_action
                source_files = (@($_.Group.source_file | Sort-Object -Unique) -join ';')
                should_skip_research = if ($_.Group.status -contains 'master') { $true } else { $false }
                should_skip_collection = if (($_.Group.status -contains 'master') -or ($_.Group.status -contains 'pending') -or ($_.Group.status -contains 'rejected')) { $true } else { $false }
            }
        }
)

$payload = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    total_artifact_rows = $items.Count
    unique_lead_keys = $grouped.Count
    duplicate_key_count = @($grouped | Where-Object { $_.occurrence_count -gt 1 }).Count
    counts_by_status = @(
        $items |
            Group-Object status |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject]@{
                    status = $_.Name
                    rows = $_.Count
                }
            }
    )
    items = @($grouped)
}

$payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputJson
$grouped | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation

[pscustomobject]@{
    output_json = $OutputJson
    output_csv = $OutputCsv
    unique_lead_keys = $grouped.Count
    duplicate_key_count = $payload.duplicate_key_count
} | Format-List
