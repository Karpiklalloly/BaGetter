$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-True {
    param(
        [Parameter(Mandatory)]
        [bool] $Condition,

        [Parameter(Mandatory)]
        [string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Assert-SequenceEqual {
    param(
        [Parameter(Mandatory)]
        [string[]] $Expected,

        [Parameter(Mandatory)]
        [string[]] $Actual,

        [Parameter(Mandatory)]
        [string] $Message
    )

    $expectedJson = ConvertTo-Json -Compress -InputObject $Expected
    $actualJson = ConvertTo-Json -Compress -InputObject $Actual
    Assert-True ($expectedJson -ceq $actualJson) "$Message`nExpected: $expectedJson`nActual:   $actualJson"
}

$scriptsDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $scriptsDirectory
$publishScript = Join-Path $scriptsDirectory 'Publish.ps1'
$projectPath = Join-Path $repositoryRoot 'src/BaGetter/BaGetter.csproj'
$publishRoot = Join-Path $repositoryRoot 'artifacts/publish'
$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("BaGetterPublishTests-" + [guid]::NewGuid().ToString('N'))
$dotnetLog = Join-Path $temporaryDirectory 'dotnet.log'
$originalPath = $env:PATH
$originalLog = $env:BAGETTER_DOTNET_LOG

try {
    New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

    $dotnetShim = @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Arguments)
$line = ConvertTo-Json -Compress -InputObject $Arguments
[System.IO.File]::AppendAllText($env:BAGETTER_DOTNET_LOG, $line + [Environment]::NewLine)
exit 0
'@
    Set-Content -LiteralPath (Join-Path $temporaryDirectory 'dotnet.ps1') -Value $dotnetShim -Encoding utf8

    $env:PATH = "$temporaryDirectory$([System.IO.Path]::PathSeparator)$originalPath"
    $env:BAGETTER_DOTNET_LOG = $dotnetLog

    Assert-True (Test-Path -LiteralPath $publishScript -PathType Leaf) "Shared publish script is missing: $publishScript"

    $cases = @(
        @{ Platform = 'Windows'; Arm = $false; SelfContained = $false; Rid = 'win-x64' },
        @{ Platform = 'Windows'; Arm = $true;  SelfContained = $false; Rid = 'win-arm64' },
        @{ Platform = 'Windows'; Arm = $false; SelfContained = $true;  Rid = 'win-x64' },
        @{ Platform = 'Windows'; Arm = $true;  SelfContained = $true;  Rid = 'win-arm64' },
        @{ Platform = 'Linux';   Arm = $false; SelfContained = $false; Rid = 'linux-x64' },
        @{ Platform = 'Linux';   Arm = $true;  SelfContained = $false; Rid = 'linux-arm64' },
        @{ Platform = 'Linux';   Arm = $false; SelfContained = $true;  Rid = 'linux-x64' },
        @{ Platform = 'Linux';   Arm = $true;  SelfContained = $true;  Rid = 'linux-arm64' }
    )

    foreach ($case in $cases) {
        Set-Content -LiteralPath $dotnetLog -Value '' -NoNewline

        $parameters = @{
            Platform = $case.Platform
            Arm = $case.Arm
            SelfContained = $case.SelfContained
        }
        & $publishScript @parameters

        $commands = @(Get-Content -LiteralPath $dotnetLog | Where-Object { $_ } | ForEach-Object { @($_ | ConvertFrom-Json) })
        Assert-True ($commands.Count -eq 2) "$($case.Rid) should execute restore and publish"

        $dependencyMode = if ($case.SelfContained) { 'self-contained' } else { 'framework-dependent' }
        $platformName = $case.Platform.ToLowerInvariant()
        $architecture = if ($case.Arm) { 'arm64' } else { 'x64' }
        $outputPath = Join-Path $publishRoot "$platformName-$architecture-$dependencyMode"

        Assert-SequenceEqual @(
            'restore',
            $projectPath,
            '--runtime', $case.Rid,
            '--disable-parallel',
            '--disable-build-servers',
            '-p:BuildInParallel=false',
            '-m:1'
        ) @($commands[0]) "$($case.Rid) restore arguments"
        Assert-SequenceEqual @(
            'publish',
            $projectPath,
            '--configuration', 'Release',
            '--runtime', $case.Rid,
            '--self-contained', $case.SelfContained.ToString().ToLowerInvariant(),
            '--no-restore',
            '--disable-build-servers',
            '-p:BuildInParallel=false',
            '-m:1',
            '--output', $outputPath
        ) @($commands[1]) "$($case.Rid) publish arguments"
    }

    Write-Host "PASS: shared publish command matrix ($($cases.Count) cases)"

    $wrapperCases = @(
        @{ Script = 'Publish-Windows-FrameworkDependent.ps1'; SelfContained = $false; Rids = @('win-x64', 'win-arm64') },
        @{ Script = 'Publish-Windows-SelfContained.ps1';      SelfContained = $true;  Rids = @('win-x64', 'win-arm64') },
        @{ Script = 'Publish-Linux-FrameworkDependent.ps1';   SelfContained = $false; Rids = @('linux-x64', 'linux-arm64') },
        @{ Script = 'Publish-Linux-SelfContained.ps1';        SelfContained = $true;  Rids = @('linux-x64', 'linux-arm64') }
    )

    foreach ($wrapperCase in $wrapperCases) {
        $wrapperPath = Join-Path $scriptsDirectory $wrapperCase.Script
        Assert-True (Test-Path -LiteralPath $wrapperPath -PathType Leaf) "Wrapper script is missing: $wrapperPath"

        for ($architectureIndex = 0; $architectureIndex -lt 2; $architectureIndex++) {
            Set-Content -LiteralPath $dotnetLog -Value '' -NoNewline
            $wrapperParameters = @{ Arm = ($architectureIndex -eq 1) }
            & $wrapperPath @wrapperParameters

            $commands = @(Get-Content -LiteralPath $dotnetLog | Where-Object { $_ } | ForEach-Object { @($_ | ConvertFrom-Json) })
            Assert-True ($commands.Count -eq 2) "$($wrapperCase.Script) should execute restore and publish"

            $publishArguments = @($commands[1])
            $runtimeIndex = [Array]::IndexOf($publishArguments, '--runtime')
            $selfContainedIndex = [Array]::IndexOf($publishArguments, '--self-contained')
            Assert-True ($runtimeIndex -ge 0) "$($wrapperCase.Script) publish command should contain --runtime"
            Assert-True ($selfContainedIndex -ge 0) "$($wrapperCase.Script) publish command should contain --self-contained"
            Assert-True ($publishArguments[$runtimeIndex + 1] -ceq $wrapperCase.Rids[$architectureIndex]) "$($wrapperCase.Script) RID"
            Assert-True ($publishArguments[$selfContainedIndex + 1] -ceq $wrapperCase.SelfContained.ToString().ToLowerInvariant()) "$($wrapperCase.Script) dependency mode"
        }
    }

    $isolatedRepository = Join-Path $temporaryDirectory 'repository'
    $isolatedScripts = Join-Path $isolatedRepository 'scripts'
    $isolatedProjectDirectory = Join-Path $isolatedRepository 'src/BaGetter'
    New-Item -ItemType Directory -Path $isolatedScripts -Force | Out-Null
    New-Item -ItemType Directory -Path $isolatedProjectDirectory -Force | Out-Null
    Copy-Item -LiteralPath $publishScript -Destination (Join-Path $isolatedScripts 'Publish.ps1')
    Set-Content -LiteralPath (Join-Path $isolatedProjectDirectory 'BaGetter.csproj') -Value '<Project Sdk="Microsoft.NET.Sdk" />'

    $isolatedPublishRoot = Join-Path $isolatedRepository 'artifacts/publish'
    $cleanTarget = Join-Path $isolatedPublishRoot 'linux-x64-framework-dependent'
    $cleanSibling = Join-Path $isolatedPublishRoot 'linux-arm64-framework-dependent'
    New-Item -ItemType Directory -Path $cleanTarget -Force | Out-Null
    New-Item -ItemType Directory -Path $cleanSibling -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $cleanTarget 'remove.me') -Value 'target'
    Set-Content -LiteralPath (Join-Path $cleanSibling 'keep.me') -Value 'sibling'
    & (Join-Path $isolatedScripts 'Publish.ps1') -Platform Linux -Clean
    Assert-True (-not (Test-Path -LiteralPath $cleanTarget)) '-Clean should remove the selected output directory'
    Assert-True (Test-Path -LiteralPath (Join-Path $cleanSibling 'keep.me')) '-Clean should not remove sibling output directories'

    Write-Host "PASS: wrapper delegation ($($wrapperCases.Count * 2) cases) and safe clean"

    Remove-Item -LiteralPath (Join-Path $temporaryDirectory 'dotnet.ps1') -Force
    $env:PATH = $temporaryDirectory
    $missingDotnetError = $null
    try {
        & $publishScript -Platform Windows
    }
    catch {
        $missingDotnetError = $_.Exception.Message
    }

    Assert-True ($missingDotnetError -like "*'dotnet' was not found*") 'Missing dotnet should produce a clear error'
    Write-Host 'PASS: missing dotnet validation'
}
finally {
    $env:PATH = $originalPath
    $env:BAGETTER_DOTNET_LOG = $originalLog

    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
