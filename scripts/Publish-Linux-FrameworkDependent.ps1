[CmdletBinding()]
param(
    [switch] $Arm,
    [switch] $Clean
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'Publish.ps1') -Platform Linux -Arm:$Arm -Clean:$Clean
