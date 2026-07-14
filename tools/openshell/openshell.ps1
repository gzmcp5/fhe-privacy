[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$OpenShellArgs,
    [string]$Distro = $env:FHE_PRIVACY_WSL_DISTRO
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$wslArgs = @()
if ($Distro) {
    $wslArgs += @("--distribution", $Distro)
}

& wsl.exe @wslArgs --cd $root -- ./artifacts/bin/openshell @OpenShellArgs
exit $LASTEXITCODE
