param(
    [Parameter(Mandatory = $true)]
    [string]$InputCsv
)

$resolved = (Resolve-Path -LiteralPath $InputCsv).Path
$rows = Import-Csv -LiteralPath $resolved

function Test-CommonMailboxDomain([string]$email) {
    if (-not $email) { return $false }
    $domain = ($email -split '@')[-1].ToLower()
    $common = @('gmail.com','outlook.com','hotmail.com','live.com','yahoo.com','icloud.com','aol.com','proton.me','protonmail.com')
    return $common -contains $domain
}

function Get-Host([string]$url) {
    try {
        return ([uri]$url).Host.ToLower().TrimStart('w','w','w','.')
    }
    catch {
        return ''
    }
}

function Get-DomainRoot([string]$hostOrDomain) {
    if (-not $hostOrDomain) { return '' }
    $value = $hostOrDomain.ToLower()
    $value = $value -replace '^www\.', ''
    $parts = $value -split '\.'
    if ($parts.Count -lt 2) { return $value }
    return $parts[$parts.Count - 2]
}

function Test-DomainBrandMatch([string]$websiteHost, [string]$emailHost) {
    if (-not $websiteHost -or -not $emailHost) { return $false }
    $websiteRoot = Get-DomainRoot $websiteHost
    $emailRoot = Get-DomainRoot $emailHost
    if (-not $websiteRoot -or -not $emailRoot) { return $false }
    if ($websiteRoot -eq $emailRoot) { return $true }
    if ($websiteRoot.Length -ge 6 -and $emailRoot.Contains($websiteRoot)) { return $true }
    if ($emailRoot.Length -ge 6 -and $websiteRoot.Contains($emailRoot)) { return $true }
    return $false
}

$findings = foreach ($row in $rows) {
    $flags = @()
    $websiteHost = Get-Host $row.website
    $emailHost = if ($row.public_email -and $row.public_email.Contains('@')) { ($row.public_email -split '@')[-1].ToLower() } else { '' }

    if (-not $row.website) { $flags += 'missing_website' }
    if (-not $row.public_phone) { $flags += 'missing_phone' }
    if (-not $row.owner_name) { $flags += 'missing_owner' }
    if (-not $row.owner_source) { $flags += 'missing_owner_source' }
    if ($row.public_email -and ($emailHost -in @('company.com','example.com','email.com'))) { $flags += 'placeholder_email' }
    if (
        $row.public_email -and
        -not (Test-CommonMailboxDomain $row.public_email) -and
        $websiteHost -and
        $emailHost -and
        -not $emailHost.EndsWith($websiteHost) -and
        -not $websiteHost.EndsWith($emailHost) -and
        -not (Test-DomainBrandMatch -websiteHost $websiteHost -emailHost $emailHost)
    ) { $flags += 'email_domain_mismatch' }
    if ($row.contact_url -match 'facebook.com|instagram.com|housecallpro.com') { $flags += 'third_party_contact_path' }
    if ($row.validation_status -eq 'validated_public_business_source' -and -not $row.website) { $flags += 'validated_without_website' }

    if ($flags.Count -gt 0) {
        [pscustomobject]@{
            business_name = $row.business_name
            city = $row.city
            state = $row.state
            public_email = $row.public_email
            website = $row.website
            owner_name = $row.owner_name
            flags = ($flags -join ';')
        }
    }
}

$findings | Format-Table -AutoSize
