param(
    [string]$State = 'FL',
    [string]$AuditCsv,
    [string]$MasterCsv,
    [string]$QuarantineDir
)

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$stateCode = $State.ToUpper()
$stateSlug = $stateCode.ToLower()
if (-not $AuditCsv) {
    $AuditCsv = Join-Path $ScriptDir "..\agent_shared\status\MASTER_CONTAMINATION_AUDIT_$stateCode.csv"
}
if (-not $MasterCsv) {
    $MasterCsv = Join-Path $ScriptDir '..\data\master_leads.csv'
}
if (-not $QuarantineDir) {
    $QuarantineDir = Join-Path $ScriptDir '..\data\quarantine'
}

$resolvedAudit = (Resolve-Path -LiteralPath $AuditCsv).Path
$resolvedMaster = (Resolve-Path -LiteralPath $MasterCsv).Path
New-Item -ItemType Directory -Force -Path $QuarantineDir | Out-Null

$stamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$quarantineCsv = Join-Path $QuarantineDir "$stamp-$stateSlug-suspicious-leads.csv"
$leadIdsCsv = Join-Path $QuarantineDir "$stamp-$stateSlug-suspicious-lead-ids.csv"
$manifestJson = Join-Path $QuarantineDir "$stamp-$stateSlug-suspicious-quarantine.json"

$auditRows = Import-Csv -LiteralPath $resolvedAudit
$masterRows = Import-Csv -LiteralPath $resolvedMaster
$leadIdSet = New-Object System.Collections.Generic.HashSet[string]

foreach ($row in $auditRows) {
    if ($row.lead_id) {
        [void]$leadIdSet.Add([string]$row.lead_id)
    }
}

$quarantinedRows = @(
    $masterRows |
        Where-Object { $leadIdSet.Contains([string]$_.lead_id) } |
        ForEach-Object {
            $row = $_.PSObject.Copy()
            Add-Member -InputObject $row -NotePropertyName 'quarantine_reason' -NotePropertyValue 'master_contamination_audit' -Force
            $row
        }
)

$leadIdRows = @(
    $quarantinedRows |
        ForEach-Object {
            [pscustomobject]@{
                lead_id = $_.lead_id
            }
        }
)

$quarantinedRows | Export-Csv -LiteralPath $quarantineCsv -NoTypeInformation
$leadIdRows | Export-Csv -LiteralPath $leadIdsCsv -NoTypeInformation

[pscustomobject]@{
    quarantined_at = (Get-Date).ToString('s')
    state = $stateCode
    audit_csv = $resolvedAudit
    master_csv = $resolvedMaster
    quarantined_rows = $quarantinedRows.Count
    quarantine_csv = $quarantineCsv
    lead_ids_csv = $leadIdsCsv
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestJson

[pscustomobject]@{
    quarantine_csv = $quarantineCsv
    lead_ids_csv = $leadIdsCsv
    manifest_json = $manifestJson
    quarantined_rows = $quarantinedRows.Count
} | Format-List
