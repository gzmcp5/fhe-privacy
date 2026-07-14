[CmdletBinding()]
param(
    [string]$Distro = $env:FHE_PRIVACY_WSL_DISTRO
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wslArgs = @()
if ($Distro) {
    $wslArgs += @("--distribution", $Distro)
}

$wslRoot = (& wsl.exe @wslArgs --cd $root -- pwd).Trim()
if ($LASTEXITCODE -ne 0 -or -not $wslRoot) {
    throw "Unable to resolve the repository path in WSL 2. Verify that WSL is installed and the selected distribution is running."
}

$bootstrap = @'
export PATH="$HOME/.local/bin:$PATH"
export FHE_PRIVACY_RUNTIME_TARGET=windows_wsl2_amd64
export OPENFHE_BUILD_ROOT="$HOME/.cache/fhe-privacy/openfhe-wheel"
export PYTHON=python3.13
bash ./tools/bootstrap-dev-runtime.sh
'@
& wsl.exe @wslArgs --cd $wslRoot -- bash -lc $bootstrap
if ($LASTEXITCODE -ne 0) {
    throw "Windows WSL 2 runtime bootstrap failed with exit code $LASTEXITCODE."
}
