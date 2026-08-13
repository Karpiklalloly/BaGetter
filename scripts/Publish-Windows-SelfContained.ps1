[CmdletBinding()]
param(
    [switch] $Arm,
    [switch] $Clean
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'Publish.ps1') -Platform Windows -SelfContained -Arm:$Arm -Clean:$Clean
