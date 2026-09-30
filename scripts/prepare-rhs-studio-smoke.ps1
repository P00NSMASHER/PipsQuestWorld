param(
    [switch]$LaunchStudio
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Working = Join-Path $RepoRoot "rhs\working\ROBLOX High School.rbxl"
$BuildState = Join-Path $RepoRoot "rhs\working\BUILD_STATE.json"

if (-not (Test-Path -LiteralPath $Working)) {
    throw "Working RHS place not found: $Working"
}
if (-not (Test-Path -LiteralPath $BuildState)) {
    throw "RHS build state not found: $BuildState"
}

$state = Get-Content -LiteralPath $BuildState -Raw | ConvertFrom-Json
$ExpectedSha256 = [string]$state.expectedWorkingSha256
if ([string]::IsNullOrWhiteSpace($ExpectedSha256)) {
    throw "BUILD_STATE.json does not contain expectedWorkingSha256"
}
if ($state.runtimeVerified -eq $true) {
    Write-Host "RHS_RUNTIME_STATE already marked verified; this launcher does not change verification state."
}
if ($state.published -eq $true) {
    Write-Host "RHS_PUBLICATION_STATE build state says published=true; verify target before any further action."
}

$actual = (Get-FileHash -LiteralPath $Working -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $ExpectedSha256.ToLowerInvariant()) {
    throw "RHS working SHA-256 mismatch. Expected $ExpectedSha256, got $actual"
}

Write-Host "RHS_WORKING_IDENTITY_OK $actual"
Write-Host "RHS_COMPATIBILITY_REPAIRS $($state.compatibilityRepairs.Count)"

if (-not $LaunchStudio) {
    Write-Host "RHS_SMOKE_PREP_OK"
    Write-Host "No GUI launched. Re-run with -LaunchStudio only when foreground Studio testing is allowed."
    exit 0
}

$versionsRoot = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
if (-not (Test-Path -LiteralPath $versionsRoot)) {
    throw "Roblox Versions directory not found: $versionsRoot"
}

$studio = Get-ChildItem -LiteralPath $versionsRoot -Directory |
    ForEach-Object {
        $candidate = Join-Path $_.FullName "RobloxStudioBeta.exe"
        if (Test-Path -LiteralPath $candidate) {
            Get-Item -LiteralPath $candidate
        }
    } |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1

if (-not $studio) {
    throw "RobloxStudioBeta.exe not found under $versionsRoot"
}

Write-Host "RHS_STUDIO_EXE $($studio.FullName)"
Write-Host "RHS_STUDIO_OPENING $Working"
Start-Process -FilePath $studio.FullName -ArgumentList @($Working)
