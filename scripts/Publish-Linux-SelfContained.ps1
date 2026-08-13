[CmdletBinding()]
param(
    [switch] $Arm,
    [switch] $Clean
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'Publish.ps1') -Platform Linux -SelfContained -Arm:$Arm -Clean:$Clean
