# Runs scripts/check.sh in the same Ubuntu release and packages as CI.
# Needs Docker Desktop running. The repository is mounted read-only.
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$setup = @(
    'apt-get update -qq'
    'apt-get install -y -qq --no-install-recommends lua5.1 lua-check python3 >/dev/null'
    'bash scripts/check.sh'
) -join ' && '

docker run --rm `
    --volume "${repo}:/repo:ro" `
    --workdir /repo `
    --env PYTHONDONTWRITEBYTECODE=1 `
    ubuntu:24.04 bash -c $setup

if ($LASTEXITCODE -ne 0) {
    throw "Checks failed (exit code $LASTEXITCODE)."
}
