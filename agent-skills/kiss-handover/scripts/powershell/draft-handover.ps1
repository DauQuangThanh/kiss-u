#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) {
    @'
Usage: draft-handover.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Drafts the operations hand-over package for a feature or release.

Answer keys: HANDOVER_FEATURE, HANDOVER_RECEIVING_TEAM,
             HANDOVER_WARRANTY_DAYS, HANDOVER_ONCALL.
'@ | Write-Host; exit 0
}

$ctx         = Read-Context
$SkillDir    = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$Date        = Get-Date -Format 'yyyy-MM-dd'

$Feature      = Resolve-Auto -Key 'HANDOVER_FEATURE'        -Default ($ctx.CURRENT_FEATURE ?? '')
$Receiving    = Resolve-Auto -Key 'HANDOVER_RECEIVING_TEAM' -Default 'internal-ops'
$WarrantyDays = [int](Resolve-Auto -Key 'HANDOVER_WARRANTY_DAYS' -Default '30')
$Oncall       = Resolve-Auto -Key 'HANDOVER_ONCALL'         -Default 'business-hours'

if ([string]::IsNullOrEmpty($Feature)) {
    Write-Error "HANDOVER_FEATURE is required."; exit 2
}

$WarrantyEnd = (Get-Date).AddDays($WarrantyDays).ToString('yyyy-MM-dd')

$HandoverDir  = Join-Path (Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'operations') 'handover'
$Out          = Join-Path $HandoverDir 'handover-package.md'
$RunbookIndex = Join-Path $HandoverDir 'runbook-index.md'
$Escalation   = Join-Path $HandoverDir 'support-escalation.md'
$Training     = Join-Path $HandoverDir 'training-checklist.md'
$Debts        = Join-Path $HandoverDir 'handover-debts.md'

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $HandoverDir)
    Write-Host ("  feature={0}  receiving={1}  warranty_days={2}" -f $Feature, $Receiving, $WarrantyDays)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Write hand-over package to $HandoverDir/.")) {
    Write-Error 'Aborted.'; exit 1
}

New-Item -ItemType Directory -Force -Path $HandoverDir | Out-Null

$oncallModel = switch ($Oncall) {
    '247'            { '24/7 on-call' }
    'business-hours' { 'Business hours (Mon–Fri)' }
    'nbd'            { 'Next business day' }
    default          { $Oncall }
}

$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\handover-package-template.md') -Raw
$tpl = $tpl.Replace('{feature}', $Feature).Replace('{date}', $Date).Replace('{go_live_date}', $Date)
$tpl = $tpl.Replace('{warranty_end}', $WarrantyEnd).Replace('{receiving_team}', $Receiving)
$tpl = $tpl.Replace('{oncall_model}', $oncallModel)
$tpl = $tpl.Replace('{system_overview}', '<!-- AI: populate from architecture and deployment artefacts -->')
$tpl = $tpl.Replace('{runbook_rows}', '<!-- AI: populate from deployment-strategy.md -->')
$tpl = $tpl.Replace('{known_limitations}', '<!-- AI: populate from risk-register and uat-sign-off waivers -->')
$tpl = $tpl.Replace('{l1_sla}', '4h').Replace('{l2_sla}', '8h').Replace('{l3_sla}', '2 business days')
$tpl = $tpl.Replace('{l1_escalate_hrs}', '4').Replace('{critical_response_sla}', '2 hours').Replace('{rca_sla}', '2')
Set-Content -LiteralPath $Out -Value $tpl

Set-Content -LiteralPath $RunbookIndex -Value @"
# Runbook Index

**Feature:** $Feature
**Date:** $Date

| Runbook | Scenario | Owner | Location | Last tested |
|---|---|---|---|---|
| Deployment runbook | Deploy / rollback | Ops team | docs/operations/deployment-strategy.md | *(TBD)* |
| Incident response | Unplanned outage | On-call | *(TBD)* | *(TBD)* |
| Data backup | DB backup / restore | Ops team | *(TBD)* | *(TBD)* |
"@

Set-Content -LiteralPath $Escalation -Value @"
# Support Escalation Matrix

**Feature:** $Feature

| Tier | Trigger | Team | Response SLA | Escalates to |
|---|---|---|---|---|
| L1 | User-reported; known issue | Support helpdesk | 4h | L2 after 4h |
| L2 | Unknown issue | Application team | 8h | L3 if code change needed |
| L3 | Code defect | Development team | 2 business days | Vendor if 3rd party |
| Vendor | 3rd-party failure | Vendor support | Per contract | — |
"@

Set-Content -LiteralPath $Training -Value @"
# Knowledge Transfer Checklist

**Feature:** $Feature
**Target audience:** $Receiving

## Critical (complete before go-live)

- [ ] System architecture overview (30 min walkthrough)
- [ ] Deployment and rollback procedures (live demo)
- [ ] Alerting and monitoring dashboard (live demo)
- [ ] Escalation process and contacts

## Important (complete within first 2 weeks)

- [ ] Common support scenarios and resolutions
- [ ] Known limitations and workarounds
- [ ] Data backup and recovery procedures

## Reference (self-study)

- [ ] ADRs and design decisions
- [ ] API documentation
- [ ] Security considerations
"@

Write-Extract -ArtefactPath $Out `
    "HANDOVER_DATE=$Date" `
    "WARRANTY_END=$WarrantyEnd" `
    "WARRANTY_DAYS=$WarrantyDays" `
    "ONCALL_MODEL=$oncallModel" `
    "RECEIVING_TEAM=$Receiving" `
    "FEATURE=$Feature" | Out-Null

Write-Host ("Wrote {0}" -f $Out)
Write-Host ("Wrote {0}" -f $RunbookIndex)
Write-Host ("Wrote {0}" -f $Escalation)
Write-Host ("Wrote {0}" -f $Training)
