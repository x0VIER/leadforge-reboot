param(
    [int]$MaxSeconds = 180,
    [int]$PollSeconds = 5
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..')
$nodeScript = Join-Path $ScriptDir 'run-source-batch.mjs'
$activityLog = Join-Path $root 'agent_shared\shared_activity_log.md'
$logsDir = Join-Path $root 'agent_shared\logs'
$statusPath = Join-Path $root 'agent_shared\status\CURRENT_STATUS.json'
$failedDir = Join-Path $root 'agent_shared\failed'
$workingDir = Join-Path $root 'agent_shared\working'

function Add-Activity([string]$Message) {
    $stamp = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
    Add-Content -LiteralPath $activityLog -Value "- $stamp $Message"
}

function Read-JsonFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Convert-StatusToFailure([string]$Reason) {
    $status = Read-JsonFile $statusPath
    $claimName = if ($status -and $status.claimFile) { $status.claimFile } else { '' }
    if ($status) {
        $status.state = 'timeout_killed'
        $status.activeLane = ''
        Add-Member -InputObject $status -NotePropertyName 'error' -NotePropertyValue $Reason -Force
        Add-Member -InputObject $status -NotePropertyName 'timeoutSeconds' -NotePropertyValue $MaxSeconds -Force
        $status | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $statusPath
    }

    if ($claimName) {
        $claimPath = Join-Path $workingDir $claimName
        if (Test-Path -LiteralPath $claimPath) {
            New-Item -ItemType Directory -Force -Path $failedDir | Out-Null
            $claim = Read-JsonFile $claimPath
            if (-not $claim) {
                $claim = [pscustomobject]@{}
            }
            Add-Member -InputObject $claim -NotePropertyName 'status' -NotePropertyValue 'timeout_killed' -Force
            Add-Member -InputObject $claim -NotePropertyName 'failureReason' -NotePropertyValue $Reason -Force
            Add-Member -InputObject $claim -NotePropertyName 'updatedAt' -NotePropertyValue ((Get-Date).ToUniversalTime().ToString('o')) -Force
            if ($status) {
                Add-Member -InputObject $claim -NotePropertyName 'rowsWritten' -NotePropertyValue $status.rowsWritten -Force
                Add-Member -InputObject $claim -NotePropertyName 'lanes' -NotePropertyValue $status.lanes -Force
            }
            $claim | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $failedDir $claimName)
            Remove-Item -LiteralPath $claimPath -Force
        }
    }
}

$guardJson = & (Join-Path $ScriptDir 'get-collector-guard-status.ps1')
$guard = $guardJson | ConvertFrom-Json
if (-not $guard.can_start_collector) {
    Add-Activity "Hermes guarded collector skipped because guard blocked start: $($guard.reasons -join ';')."
    [pscustomobject]@{
        started = $false
        reason = 'collector_guard_blocked'
        guard_reasons = @($guard.reasons)
    } | Format-List
    exit 2
}

Add-Activity "Hermes guarded collector starting with max runtime ${MaxSeconds}s."
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$runStamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ssZ')
$stdoutPath = Join-Path $logsDir "$runStamp-guarded-collector.stdout.log"
$stderrPath = Join-Path $logsDir "$runStamp-guarded-collector.stderr.log"
$quotedNodeScript = '"' + $nodeScript + '"'
$process = Start-Process -FilePath 'node' -ArgumentList $quotedNodeScript -WorkingDirectory $root -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
$startedAt = Get-Date

while (-not $process.HasExited) {
    Start-Sleep -Seconds $PollSeconds
    $process.Refresh()
    $elapsed = ((Get-Date) - $startedAt).TotalSeconds
    if ($elapsed -ge $MaxSeconds) {
        Stop-Process -Id $process.Id -Force
        $reason = "Collector exceeded guarded max runtime of ${MaxSeconds}s and was stopped to prevent ghost overlap."
        Convert-StatusToFailure $reason
        Add-Activity "Knox timeout fix: $reason"
        [pscustomobject]@{
            started = $true
            timed_out = $true
            max_seconds = $MaxSeconds
            process_id = $process.Id
            reason = $reason
        } | Format-List
        exit 124
    }
}

$process.WaitForExit()
$process.Refresh()
$exitCode = if ($null -ne $process.ExitCode) { [int]$process.ExitCode } else { 1 }
Add-Activity "Hermes guarded collector finished with exit code $exitCode."
[pscustomobject]@{
    started = $true
    timed_out = $false
    max_seconds = $MaxSeconds
    process_id = $process.Id
    exit_code = $exitCode
    stdout_log = $stdoutPath
    stderr_log = $stderrPath
} | Format-List
exit $exitCode
