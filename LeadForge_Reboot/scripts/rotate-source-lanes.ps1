param(
    [switch]$Force
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$configPath = Join-Path $ScriptDir '..\config\source-lanes.json'
$statusPath = Join-Path $ScriptDir '..\agent_shared\status\CURRENT_STATUS.json'

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$status = $null
if (Test-Path -LiteralPath $statusPath) {
    $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
}

if (-not $Force -and $status -and $status.state -notin @('complete_no_rows', 'complete')) {
    throw "Lane rotation is only allowed after a completed collector run unless -Force is used."
}

$windowSize = if ($config.activeLaneWindowSize) { [int]$config.activeLaneWindowSize } else { 4 }
$pool = @($config.lanePool)
if ($pool.Count -lt $windowSize) {
    throw "lanePool must contain at least $windowSize cities."
}

$currentCities = @($config.lanes | ForEach-Object { $_.city })
$currentStart = 0
if ($currentCities.Count -gt 0) {
    $matchIndex = [array]::IndexOf($pool, $currentCities[0])
    if ($matchIndex -ge 0) {
        $currentStart = $matchIndex
    }
}

$advance = $Force -or ($status -and $status.state -eq 'complete_no_rows')
if (-not $advance) {
    [pscustomobject]@{
        rotated = $false
        reason = 'Most recent run still produced rows; keeping current cities.'
        cities = ($currentCities -join ', ')
    } | Format-List
    exit 0
}

$nextStart = ($currentStart + $windowSize) % $pool.Count
$nextCities = for ($i = 0; $i -lt $windowSize; $i += 1) {
    $pool[($nextStart + $i) % $pool.Count]
}

$templateLane = $config.lanes[0]
$newLanes = foreach ($city in $nextCities) {
    [pscustomobject]@{
        city = $city
        state = 'FL'
        niches = @($templateLane.niches)
        perNicheLimit = $templateLane.perNicheLimit
    }
}

$updatedConfig = [ordered]@{
    batchName = $config.batchName
    collectorName = $config.collectorName
    maxOutputRows = $config.maxOutputRows
    overpassPauseMs = $config.overpassPauseMs
    lanePauseMs = $config.lanePauseMs
    activeLaneWindowSize = $windowSize
    lanePool = @($pool)
    lanes = @($newLanes)
}

$updatedConfig | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath

[pscustomobject]@{
    rotated = $true
    reason = if ($Force) { 'Forced rotation.' } else { 'Previous run completed with no fresh rows.' }
    cities = ($nextCities -join ', ')
} | Format-List
