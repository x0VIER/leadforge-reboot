param(
    [string]$State = 'FL',
    [string]$InputCsv,
    [string]$OutputPath,
    [switch]$SkipDnsCheck
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $InputCsv) {
    $InputCsv = Join-Path $ScriptDir '..\data\master_leads.csv'
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $ScriptDir "..\agent_shared\status\MASTER_CONTAMINATION_AUDIT_$($State.ToUpper()).json"
}
$csvOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, '.csv')

function Normalize-Host([string]$url) {
    try {
        return ([uri]$url).Host.ToLower() -replace '^www\.', ''
    }
    catch {
        return ''
    }
}

function Get-AreaCode([string]$phone) {
    if (-not $phone) { return '' }
    $digits = ($phone -replace '[^0-9]', '')
    if ($digits.Length -eq 11 -and $digits.StartsWith('1')) {
        $digits = $digits.Substring(1)
    }
    if ($digits.Length -lt 10) { return '' }
    return $digits.Substring(0, 3)
}

function Test-WebsiteHostResolves([string]$url) {
    if (-not $url) { return $null }

    $hostName = Normalize-Host $url
    if (-not $hostName) { return $null }

    if ($script:HostResolutionCache.ContainsKey($hostName)) {
        return $script:HostResolutionCache[$hostName]
    }

    $resolved = $false
    try {
        Resolve-DnsName -Name $hostName -ErrorAction Stop | Out-Null
        $resolved = $true
    }
    catch {
        $resolved = $false
    }

    $script:HostResolutionCache[$hostName] = $resolved
    return $resolved
}

$resolvedInput = (Resolve-Path -LiteralPath $InputCsv).Path
$rows = Import-Csv -LiteralPath $resolvedInput
$stateRows = @($rows | Where-Object { $_.state -eq $State })
$script:HostResolutionCache = @{}

$websiteGroups = @(
    $stateRows |
        Where-Object { $_.website } |
        Group-Object website |
        Where-Object { $_.Count -gt 1 }
)

$suspiciousRows = New-Object System.Collections.Generic.List[object]
$suspiciousLeadIds = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($row in $stateRows) {
    if (-not $row.website) {
        continue
    }

    $flags = New-Object System.Collections.Generic.List[string]
    $websiteHost = Normalize-Host $row.website
    $areaCode = Get-AreaCode $row.public_phone

    if (-not $SkipDnsCheck) {
        $hostResolves = Test-WebsiteHostResolves $row.website
        if ($hostResolves -eq $false) {
            [void]$flags.Add('website_host_does_not_resolve')
        }
    }

    if ($areaCode -eq '813' -and $row.city -notin @('Tampa','Riverview','St. Petersburg')) {
        [void]$flags.Add('tampa_area_code_outside_tampa_cluster')
    }

    if ($flags.Count -gt 0 -and $suspiciousLeadIds.Add($row.lead_id)) {
        $suspiciousRows.Add([pscustomobject]@{
            lead_id = $row.lead_id
            business_name = $row.business_name
            niche = $row.niche
            city = $row.city
            state = $row.state
            website = $row.website
            public_phone = $row.public_phone
            public_email = $row.public_email
            validation_status = $row.validation_status
            priority_tier = $row.priority_tier
            suspicion_flags = ($flags -join ';')
        })
    }
}

foreach ($group in $websiteGroups) {
    $cities = @($group.Group.city | Sort-Object -Unique)
    if ($cities.Count -lt 2) {
        continue
    }

    foreach ($row in $group.Group) {
        $flags = New-Object System.Collections.Generic.List[string]
        $websiteHost = Normalize-Host $row.website
        $areaCode = Get-AreaCode $row.public_phone

        if ($cities.Count -ge 2) {
            [void]$flags.Add("duplicate_website_multi_city:$($cities.Count)")
        }
        if ($areaCode -eq '813' -and $row.city -notin @('Tampa','Riverview','St. Petersburg')) {
            [void]$flags.Add('tampa_area_code_outside_tampa_cluster')
        }
        if ($websiteHost -match 'of|pros|services|masters|experts|solutions|repair|cleaners|restoration|homeimpr|homeimprov|electricalp|wire|climate|roofing') {
            [void]$flags.Add('template_brand_pattern')
        }

        if ($flags.Count -gt 0 -and $suspiciousLeadIds.Add($row.lead_id)) {
            $suspiciousRows.Add([pscustomobject]@{
                lead_id = $row.lead_id
                business_name = $row.business_name
                niche = $row.niche
                city = $row.city
                state = $row.state
                website = $row.website
                public_phone = $row.public_phone
                public_email = $row.public_email
                validation_status = $row.validation_status
                priority_tier = $row.priority_tier
                suspicion_flags = ($flags -join ';')
            })
        }
    }
}

$duplicateGroupSummaries = @(
    $websiteGroups |
        Sort-Object Count -Descending |
        Select-Object -First 25 |
        ForEach-Object {
            [pscustomobject]@{
                website = $_.Name
                count = $_.Count
                cities = @($_.Group | ForEach-Object { $_.city } | Sort-Object -Unique)
                sample_businesses = @($_.Group | ForEach-Object { $_.business_name } | Select-Object -First 4)
            }
        }
)

$payload = New-Object System.Collections.Specialized.OrderedDictionary
$payload['generated_at'] = (Get-Date).ToString('s')
$payload['input_csv'] = $resolvedInput
$payload['state'] = $State
$payload['total_state_rows'] = $stateRows.Count
$payload['duplicate_website_groups'] = $websiteGroups.Count
$payload['dns_check_enabled'] = (-not $SkipDnsCheck)
$payload['unique_hosts_checked'] = $script:HostResolutionCache.Count
$payload['suspicious_row_count'] = $suspiciousRows.Count
$payload['duplicate_website_groups_top'] = @($duplicateGroupSummaries)
$suspiciousRowsArray = @($suspiciousRows | ForEach-Object { $_ })
$payload['suspicious_rows'] = $suspiciousRowsArray

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
[pscustomobject]$payload | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $OutputPath
if ($suspiciousRowsArray.Count -gt 0) {
    $suspiciousRowsArray | Export-Csv -LiteralPath $csvOutputPath -NoTypeInformation
}

[pscustomobject]@{
    output_path = $OutputPath
    csv_output_path = if (Test-Path -LiteralPath $csvOutputPath) { $csvOutputPath } else { '' }
    state = $State
    total_state_rows = $stateRows.Count
    duplicate_website_groups = $websiteGroups.Count
    suspicious_row_count = $suspiciousRows.Count
} | Format-List
