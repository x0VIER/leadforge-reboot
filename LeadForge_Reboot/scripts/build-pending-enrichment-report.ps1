param()

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$runsRoot = Join-Path $ScriptDir '..\data\runs'
$statusDir = Join-Path $ScriptDir '..\agent_shared\status'
$reportPath = Join-Path $statusDir 'PENDING_ENRICHMENT_QUEUE.json'

New-Item -ItemType Directory -Force -Path $statusDir | Out-Null

$manifests = @(Get-ChildItem -Path $runsRoot -Recurse -File -Filter run-manifest.json | Sort-Object FullName)
$queue = @()

foreach ($manifestFile in $manifests) {
    $manifest = Get-Content -LiteralPath $manifestFile.FullName -Raw | ConvertFrom-Json
    $runRoot = Split-Path -Parent $manifestFile.FullName
    $createdAt = $null
    try {
        $createdAt = [datetime]$manifest.created_at
    }
    catch {
        $createdAt = $null
    }

    foreach ($relativeFile in @($manifest.pending_files)) {
        if (-not $relativeFile) { continue }
        $pendingPath = Join-Path $runRoot "tmp\$relativeFile"
        if (-not (Test-Path -LiteralPath $pendingPath)) { continue }

        $rows = Import-Csv -LiteralPath $pendingPath
        foreach ($row in $rows) {
            $ageDays = if ($createdAt) { [math]::Floor(((Get-Date) - $createdAt).TotalDays) } else { 0 }
            $triageReasons = @($row.triage_reason -split ';' | Where-Object { $_ })
            $hasResearchNote = $row.PSObject.Properties.Name -contains 'public_research_note' -and [string]::IsNullOrWhiteSpace($row.public_research_note) -eq $false
            $pendingState = if (($triageReasons -contains 'missing_owner') -and $hasResearchNote) {
                'researched_owner_unresolved'
            }
            elseif (($triageReasons -contains 'missing_owner') -or ($triageReasons -contains 'missing_owner_source')) {
                'needs_owner_research'
            }
            elseif ($triageReasons -contains 'third_party_contact_path') {
                'needs_first_party_contact_path'
            }
            else {
                'manual_review'
            }

            $recommendedAction = if ($pendingState -eq 'researched_owner_unresolved') {
                'monitor_or_move_on_until_stronger_public_evidence'
            }
            elseif (($triageReasons -contains 'missing_owner') -or ($triageReasons -contains 'missing_owner_source')) {
                'public_owner_research'
            }
            elseif ($triageReasons -contains 'third_party_contact_path') {
                'replace_with_first_party_contact_path'
            }
            else {
                'manual_review'
            }

            $queue += [pscustomobject]@{
                run_name = $manifest.run_name
                run_status = $manifest.status
                run_created_at = $manifest.created_at
                pending_age_days = $ageDays
                business_name = $row.business_name
                niche = $row.niche
                city = $row.city
                state = $row.state
                website = $row.website
                public_phone = $row.public_phone
                public_email = $row.public_email
                contact_url = $row.contact_url
                triage_reason = $row.triage_reason
                pending_state = $pendingState
                public_research_note = if ($row.PSObject.Properties.Name -contains 'public_research_note') { $row.public_research_note } else { '' }
                recommended_action = $recommendedAction
                pending_file = $relativeFile
                pending_path = $pendingPath
            }
        }
    }
}

$payload = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    pending_rows = $queue.Count
    items = @($queue)
}

$payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath
[pscustomobject]@{
    report_path = $reportPath
    pending_rows = $queue.Count
} | Format-List
