param(
    [switch]$Force
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$configPath = Join-Path $ScriptDir '..\config\source-lanes.json'
$statusPath = Join-Path $ScriptDir '..\agent_shared\status\CURRENT_STATUS.json'
$runsRoot = Join-Path $ScriptDir '..\data\runs'

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$status = $null
if (Test-Path -LiteralPath $statusPath) {
    $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
}

if (-not $Force -and $status -and $status.state -notin @('complete_no_rows', 'complete')) {
    throw "Lane rotation is only allowed after a completed collector run unless -Force is used."
}

$windowSize = if ($config.activeLaneWindowSize) { [int]$config.activeLaneWindowSize } else { 4 }
$targetState = if ($config.targetState) {
    $config.targetState
} elseif ($config.lanes -and $config.lanes[0].state) {
    $config.lanes[0].state
} else {
    'FL'
}
$pool = @($config.lanePool)
if ($pool.Count -lt $windowSize) {
    throw "lanePool must contain at least $windowSize cities."
}

function Get-LanePoolEntryKey($entry) {
    if ($entry -is [string]) {
        return $entry
    }
    return "$($entry.city)|$($entry.state)"
}

function Convert-LanePoolEntryToLane($entry, $templateLane, $fallbackState) {
    if ($entry -is [string]) {
        return [pscustomobject]@{
            city = $entry
            state = $fallbackState
            niches = @($templateLane.niches)
            perNicheLimit = $templateLane.perNicheLimit
        }
    }

    $lane = [ordered]@{
        city = $entry.city
        state = $entry.state
        niches = @($templateLane.niches)
        perNicheLimit = $templateLane.perNicheLimit
    }
    if ($entry.PSObject.Properties.Name -contains 'stateName') {
        $lane['stateName'] = $entry.stateName
    }
    return [pscustomobject]$lane
}

$currentCities = @($config.lanes | ForEach-Object { "$($_.city)|$($_.state)" })
$currentStart = 0
if ($currentCities.Count -gt 0) {
    $poolKeys = @($pool | ForEach-Object { Get-LanePoolEntryKey $_ })
    $matchIndex = [array]::IndexOf($poolKeys, $currentCities[0])
    if ($matchIndex -ge 0) {
        $currentStart = $matchIndex
    }
}

$latestRunManifest = $null
if (Test-Path -LiteralPath $runsRoot) {
    $latestRunManifestFile = Get-ChildItem -LiteralPath $runsRoot -Recurse -File -Filter run-manifest.json |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestRunManifestFile) {
        try {
            $latestRunManifest = Get-Content -LiteralPath $latestRunManifestFile.FullName -Raw | ConvertFrom-Json
        }
        catch {
            $latestRunManifest = $null
        }
    }
}

$latestReviewedRunWasDry = $latestRunManifest -and $latestRunManifest.status -in @('rejected', 'merged_no_approved_rows')
$advance = $Force -or ($status -and $status.state -eq 'complete_no_rows') -or $latestReviewedRunWasDry
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
    Convert-LanePoolEntryToLane $city $templateLane $targetState
}

$updatedConfig = [ordered]@{
    batchName = $config.batchName
    collectorName = $config.collectorName
    scope = $config.scope
    targetState = $targetState
    targetStateName = $config.targetStateName
    sprintTargetRows = $config.sprintTargetRows
    maxOutputRows = $config.maxOutputRows
    overpassPauseMs = $config.overpassPauseMs
    lanePauseMs = $config.lanePauseMs
    overpassTimeoutMs = $config.overpassTimeoutMs
    overpassAttempts = $config.overpassAttempts
    activeLaneWindowSize = $windowSize
    lanePool = @($pool)
    lanes = @($newLanes)
}

$updatedConfig | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath

[pscustomobject]@{
    rotated = $true
    reason = if ($Force) {
        'Forced rotation.'
    } elseif ($latestReviewedRunWasDry) {
        "Latest reviewed run was $($latestRunManifest.status); rotating away from low-yield cities."
    } else {
        'Previous run completed with no fresh rows.'
    }
    cities = (@($newLanes | ForEach-Object { "$($_.city), $($_.state)" }) -join ', ')
} | Format-List
