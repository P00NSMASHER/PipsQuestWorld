param(
    [switch]$LaunchStudio
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Working = Join-Path $RepoRoot "rhs\working\ROBLOX High School.rbxl"
$ExpectedSha256 = "04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4"

if (-not (Test-Path -LiteralPath $Working)) {
    throw "Working RHS place not found: $Working"
}

$actual = (Get-FileHash -LiteralPath $Working -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $ExpectedSha256) {
    throw "RHS working SHA-256 mismatch. Expected $ExpectedSha256, got $actual"
}

Write-Host "RHS_WORKING_IDENTITY_OK $actual"

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
