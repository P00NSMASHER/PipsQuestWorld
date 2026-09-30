param(
    [datetime]$Since = (Get-Date).AddHours(-2),
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Working = Join-Path $RepoRoot "rhs\working\ROBLOX High School.rbxl"
$BuildState = Join-Path $RepoRoot "rhs\working\BUILD_STATE.json"
$LogsRoot = Join-Path $env:LOCALAPPDATA "Roblox\logs"

if (-not (Test-Path -LiteralPath $Working)) {
    throw "Working RHS place not found: $Working"
}
if (-not (Test-Path -LiteralPath $BuildState)) {
    throw "RHS build state not found: $BuildState"
}
if (-not (Test-Path -LiteralPath $LogsRoot)) {
    throw "Roblox log directory not found: $LogsRoot"
}

$state = Get-Content -LiteralPath $BuildState -Raw | ConvertFrom-Json
$expected = ([string]$state.expectedWorkingSha256).ToLowerInvariant()
$actual = (Get-FileHash -LiteralPath $Working -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) {
    throw "RHS working SHA-256 mismatch. Expected $expected, got $actual"
}

$candidates = Get-ChildItem -LiteralPath $LogsRoot -File -Filter "*.log" |
    Where-Object { $_.LastWriteTime -ge $Since } |
    Sort-Object LastWriteTimeUtc -Descending

$studioLog = $candidates |
    Where-Object { $_.Name -match "(?i)studio" } |
    Select-Object -First 1

if (-not $studioLog) {
    $studioLog = $candidates | Select-Object -First 1
}
if (-not $studioLog) {
    throw "No Roblox log file modified since $($Since.ToString('o'))"
}

$lines = Get-Content -LiteralPath $studioLog.FullName -ErrorAction Stop

$fatalPattern = '(?i)(error|exception|stack begin|stack end|infinite yield|not a valid member|attempt to (index|call|perform)|failed to load|failed to require|module code did not return|script timeout)'
$compatPattern = '(?i)(DataStore|TeleportService|MarketplaceService|BadgeService|GamePassService|PointsService|HttpService|LoadAsset|require\(|asset)'
$scriptPattern = '(?i)(Script|LocalScript|ModuleScript|ServerScriptService|StarterGui|StarterPlayer|ReplicatedStorage|Workspace)'

$fatal = @()
$compat = @()
$script = @()

foreach ($line in $lines) {
    if ($line -match $fatalPattern) {
        $fatal += $line
    }
    if ($line -match $compatPattern) {
        $compat += $line
    }
    if ($line -match $scriptPattern -and ($line -match $fatalPattern -or $line -match $compatPattern)) {
        $script += $line
    }
}

function Take-Limited([object[]]$Values, [int]$Limit = 500) {
    if (-not $Values) { return @() }
    return @($Values | Select-Object -First $Limit)
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $env:TEMP "rhs-studio-smoke-$stamp.json"
}

$receipt = [ordered]@{
    schemaVersion = 1
    collectedAt = (Get-Date).ToUniversalTime().ToString("o")
    since = $Since.ToUniversalTime().ToString("o")
    candidate = [ordered]@{
        path = $Working
        sha256 = $actual
        compatibilityRepairs = @($state.compatibilityRepairs)
        runtimeVerifiedBeforeCollection = [bool]$state.runtimeVerified
        published = [bool]$state.published
    }
    studioLog = [ordered]@{
        path = $studioLog.FullName
        name = $studioLog.Name
        bytes = $studioLog.Length
        lastWriteTimeUtc = $studioLog.LastWriteTimeUtc.ToString("o")
        totalLines = $lines.Count
    }
    findings = [ordered]@{
        fatalMarkerCount = $fatal.Count
        compatibilityMarkerCount = $compat.Count
        scriptRelevantMarkerCount = $script.Count
        fatalLines = @(Take-Limited $fatal)
        compatibilityLines = @(Take-Limited $compat)
        scriptRelevantLines = @(Take-Limited $script)
    }
    interpretation = "Evidence capture only. Zero matching log markers does not by itself prove gameplay acceptance; Gates A/B still require direct runtime observation."
}

$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "RHS_SMOKE_LOG_CAPTURE_OK"
Write-Host "RHS_WORKING_SHA256 $actual"
Write-Host "RHS_STUDIO_LOG $($studioLog.FullName)"
Write-Host "RHS_FATAL_MARKERS $($fatal.Count)"
Write-Host "RHS_COMPAT_MARKERS $($compat.Count)"
Write-Host "RHS_SCRIPT_RELEVANT_MARKERS $($script.Count)"
Write-Host "RHS_SMOKE_RECEIPT $OutputPath"
