param(
    [Parameter(Mandatory = $true)]
    [string]$InputCsv,
    [string]$MemoryCsv
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..')
$statusDir = Join-Path $root 'agent_shared\status'

if (-not $MemoryCsv) {
    $MemoryCsv = Join-Path $statusDir 'LEAD_MEMORY_INDEX.csv'
}
if (-not (Test-Path -LiteralPath $MemoryCsv)) {
    & (Join-Path $ScriptDir 'build-lead-memory-index.ps1') | Out-Null
}

function Normalize-Text([string]$value) {
    if (-not $value) { return '' }
    return (($value.ToLowerInvariant() -replace '[^a-z0-9]+', ' ').Trim() -replace '\s+', ' ')
}

function Normalize-Website([string]$value) {
    if (-not $value) { return '' }
    try {
        $uri = [uri]$value
        return ($uri.Host.ToLowerInvariant() -replace '^www\.', '')
    }
    catch {
        return (($value.ToLowerInvariant() -replace '^https?://', '') -replace '^www\.', '').TrimEnd('/')
    }
}

function Get-LeadKey($row) {
    $websiteHost = Normalize-Website $row.website
    if ($websiteHost) { return "website:$websiteHost" }
    return "name-city-state:$(Normalize-Text $row.business_name)|$(Normalize-Text $row.city)|$(Normalize-Text $row.state)"
}

$rows = @(Import-Csv -LiteralPath (Resolve-Path -LiteralPath $InputCsv).Path)
$memory = @(Import-Csv -LiteralPath (Resolve-Path -LiteralPath $MemoryCsv).Path)

foreach ($row in $rows) {
    $key = Get-LeadKey $row
    $hit = @($memory | Where-Object { $_.lead_key -eq $key } | Select-Object -First 1)
    [pscustomobject]@{
        business_name = $row.business_name
        city = $row.city
        state = $row.state
        niche = $row.niche
        lead_key = $key
        memory_statuses = if ($hit.Count) { $hit[0].statuses } else { '' }
        should_skip_collection = if ($hit.Count) { $hit[0].should_skip_collection } else { 'False' }
        should_skip_research = if ($hit.Count) { $hit[0].should_skip_research } else { 'False' }
        source_files = if ($hit.Count) { $hit[0].source_files } else { '' }
    }
}
