param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$WorktreeRoot = (Join-Path (Split-Path -Parent $RepoRoot) "PipsQuestWorld-worktrees")
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required to create worktrees."
}

$lanes = [ordered]@{
    "integrator"       = "develop"
    "maze-core"        = "feat/maze-core"
    "education-engine" = "feat/education-engine"
    "learning-gates"   = "feat/learning-gates"
    "pip-rewards"      = "feat/pip-rewards"
    "mobile-ux"        = "feat/mobile-ux"
    "qa"               = "qa/gameplay"
    "content"          = "content/emma-schoolwork"
}

Push-Location $RepoRoot
try {
    git fetch origin --prune
    if ($LASTEXITCODE -ne 0) { throw "git fetch failed" }

    New-Item -ItemType Directory -Force -Path $WorktreeRoot | Out-Null

    foreach ($entry in $lanes.GetEnumerator()) {
        $name = $entry.Key
        $branch = $entry.Value
        $path = Join-Path $WorktreeRoot $name

        if (Test-Path $path) {
            Write-Host "SKIP $name - path already exists: $path"
            continue
        }

        git show-ref --verify --quiet ("refs/heads/" + $branch)
        if ($LASTEXITCODE -ne 0) {
            git branch --track $branch ("origin/" + $branch)
            if ($LASTEXITCODE -ne 0) { throw "Could not create local tracking branch $branch" }
        }

        git worktree add $path $branch
        if ($LASTEXITCODE -ne 0) { throw "Could not create worktree for $branch" }

        Write-Host "READY $name -> $path [$branch]"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "All isolated development worktrees are ready."
