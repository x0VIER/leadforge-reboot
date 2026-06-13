param(
    [Parameter(Mandatory = $true)]
    [string]$NewCsv,
    [string]$MasterCsv,
    [string]$OutputCsv
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $MasterCsv) {
    $MasterCsv = Join-Path $ScriptDir '..\data\master_leads.csv'
}
if (-not $OutputCsv) {
    $OutputCsv = Join-Path $ScriptDir '..\data\master_leads.csv'
}

function Get-ColumnOrder() {
    @(
        'lead_id',
        'business_name',
        'niche',
        'city',
        'state',
        'website',
        'public_phone',
        'public_email',
        'contact_url',
        'owner_name',
        'owner_title',
        'owner_source',
        'source_type',
        'source_query',
        'source_evidence',
        'visible_gap',
        'offer_angle',
        'risk_score_1_5',
        'validation_status',
        'priority_tier',
        'last_checked'
    )
}

function Normalize-Key($row) {
    $parts = @(
        $row.business_name,
        $row.city,
        $row.state,
        $row.website
    ) | ForEach-Object {
        if ($null -eq $_) {
            ''
        }
        else {
            $_.ToString().Trim().ToLower()
        }
    }
    ($parts -join '|')
}

function Ensure-LeadId($rows) {
    $max = 0
    foreach ($row in $rows) {
        if ($row.lead_id -match '^LF-(\d+)$') {
            $value = [int]$Matches[1]
            if ($value -gt $max) {
                $max = $value
            }
        }
    }

    foreach ($row in $rows) {
        if (-not $row.lead_id) {
            $max += 1
            $row.lead_id = 'LF-{0:d4}' -f $max
        }
    }

    return $rows
}

function Get-WebsiteHost([string]$Url) {
    try {
        return ([uri]$Url).Host.ToLower() -replace '^www\.', ''
    }
    catch {
        return ''
    }
}

function Test-HostResolves([string]$Url) {
    $hostName = Get-WebsiteHost $Url
    if (-not $hostName) {
        return $false
    }

    try {
        [System.Net.Dns]::GetHostEntry($hostName) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Merge-PreferredFields($targetRow, $incomingRow) {
    foreach ($property in $incomingRow.PSObject.Properties.Name) {
        $incomingValue = $incomingRow.$property
        if (-not $incomingValue) {
            continue
        }

        $hasTargetProperty = $targetRow.PSObject.Properties.Name -contains $property
        if (-not $hasTargetProperty) {
            Add-Member -InputObject $targetRow -NotePropertyName $property -NotePropertyValue $incomingValue
            continue
        }

        $targetValue = $targetRow.$property
        if ($property -eq 'last_checked') {
            try {
                $incomingDate = [datetime]$incomingValue
                $targetDate = if ($targetValue) { [datetime]$targetValue } else { $null }
                if (-not $targetDate -or $incomingDate -gt $targetDate) {
                    $targetRow.$property = $incomingValue
                }
                continue
            }
            catch {
                if (-not $targetValue) {
                    $targetRow.$property = $incomingValue
                }
                continue
            }
        }

        if ($property -eq 'public_phone') {
            $targetDigits = if ($targetValue) { (($targetValue -replace '[^\d]', '')) } else { '' }
            $incomingDigits = (($incomingValue -replace '[^\d]', ''))
            $targetLooksPlaceholder = $targetDigits -match '^1?555' -or $targetDigits -match '555'
            $incomingLooksReal = $incomingDigits -and -not ($incomingDigits -match '^1?555' -or $incomingDigits -match '555')
            if ($targetLooksPlaceholder -and $incomingLooksReal) {
                $targetRow.$property = $incomingValue
                continue
            }
        }

        if ($property -eq 'website' -and $targetValue -and $incomingValue -and $targetValue -ne $incomingValue) {
            if ((-not (Test-HostResolves $targetValue)) -and (Test-HostResolves $incomingValue)) {
                $targetRow.$property = $incomingValue
                continue
            }
        }

        if (-not $targetValue) {
            $targetRow.$property = $incomingValue
        }
    }
}

$masterRows = @()
if (Test-Path -LiteralPath $MasterCsv) {
    $masterRows = Import-Csv -LiteralPath (Resolve-Path -LiteralPath $MasterCsv)
}

$newRows = Import-Csv -LiteralPath (Resolve-Path -LiteralPath $NewCsv)
$existing = @{}

foreach ($row in $masterRows) {
    $existing[(Normalize-Key $row)] = $row
}

$enrichedRows = 0
$approved = foreach ($row in $newRows) {
    $key = Normalize-Key $row
    if ($existing.ContainsKey($key)) {
        Merge-PreferredFields -targetRow $existing[$key] -incomingRow $row
        $enrichedRows += 1
    }
    else {
        $existing[$key] = $row
        $row
    }
}

$merged = @($masterRows + $approved)
$merged = Ensure-LeadId $merged
$columnOrder = Get-ColumnOrder
$normalized = foreach ($row in $merged) {
    $ordered = [ordered]@{}
    foreach ($column in $columnOrder) {
        $ordered[$column] = if ($row.PSObject.Properties.Name -contains $column) { $row.$column } else { '' }
    }
    foreach ($property in $row.PSObject.Properties.Name) {
        if ($columnOrder -notcontains $property) {
            $ordered[$property] = $row.$property
        }
    }
    [pscustomobject]$ordered
}

$normalized | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation

[pscustomobject]@{
    master_before = $masterRows.Count
    new_rows = $newRows.Count
    merged_rows = $normalized.Count
    added_rows = $approved.Count
    enriched_existing_rows = $enrichedRows
    output_csv = (Resolve-Path -LiteralPath $OutputCsv).Path
} | Format-List
