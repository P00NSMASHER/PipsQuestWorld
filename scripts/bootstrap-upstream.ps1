param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$UpstreamUrl = "https://github.com/MayGo/maze-world.git"
$PinnedCommit = "2dba386aaa66c3351087ae5848bc5f6bf7a832b8"
$Scratch = Join-Path $RepoRoot ".bootstrap\maze-world"
$GameDir = Join-Path $RepoRoot "game"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required for the pristine Maze World import. Install Git, then rerun this script."
}

if (Test-Path $Scratch) {
    Remove-Item $Scratch -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Split-Path $Scratch) | Out-Null

Write-Host "Cloning Maze World recursively..."
git clone --recursive $UpstreamUrl $Scratch
if ($LASTEXITCODE -ne 0) { throw "git clone failed" }

Push-Location $Scratch
try {
    git checkout --detach $PinnedCommit
    if ($LASTEXITCODE -ne 0) { throw "git checkout failed" }

    git submodule sync --recursive
    git submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) { throw "git submodule update failed" }

    $Actual = (git rev-parse HEAD).Trim()
    if ($Actual -ne $PinnedCommit) {
        throw "Pinned commit mismatch. Expected $PinnedCommit, got $Actual"
    }
}
finally {
    Pop-Location
}

if (Test-Path $GameDir) {
    Remove-Item $GameDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $GameDir | Out-Null

Write-Host "Copying complete working tree into game/..."
robocopy $Scratch $GameDir /E /XD .git /XF .git Game.rbxlx /NFL /NDL /NJH /NJS /NP | Out-Null
$Code = $LASTEXITCODE
if ($Code -ge 8) {
    throw "robocopy failed with code $Code"
}

$Receipt = [ordered]@{
    upstream = "MayGo/maze-world"
    upstreamUrl = $UpstreamUrl
    pinnedCommit = $PinnedCommit
    importedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    recursiveSubmodules = $true
    importMethod = "git clone --recursive + detached checkout + working-tree copy"
    omittedArtifacts = @("Game.rbxlx (upstream Git LFS build artifact; expanded file exceeds GitHub normal-file limit)")
}
$Receipt | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $GameDir "UPSTREAM_SOURCE.json") -Encoding UTF8

Write-Host ""
Write-Host "Maze World import complete."
Write-Host "Pinned commit: $PinnedCommit"
Write-Host "Next: run the baseline acceptance checklist before modifying game code."
