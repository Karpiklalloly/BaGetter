[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Windows', 'Linux')]
    [string] $Platform,

    [switch] $SelfContained,

    [switch] $Arm,

    [switch] $Clean
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $dotnetCommand) {
    throw "The .NET SDK command 'dotnet' was not found in PATH."
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$projectPath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot 'src/BaGetter/BaGetter.csproj'))
$publishRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot 'artifacts/publish'))

if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
    throw "BaGetter project was not found: $projectPath"
}

$platformName = $Platform.ToLowerInvariant()
$runtimePlatform = if ($Platform -eq 'Windows') { 'win' } else { 'linux' }
$architecture = if ($Arm) { 'arm64' } else { 'x64' }
$dependencyMode = if ($SelfContained) { 'self-contained' } else { 'framework-dependent' }
$runtimeIdentifier = "$runtimePlatform-$architecture"
$outputPath = [System.IO.Path]::GetFullPath((Join-Path $publishRoot "$platformName-$architecture-$dependencyMode"))

$directorySeparator = [System.IO.Path]::DirectorySeparatorChar
$publishRootPrefix = $publishRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + $directorySeparator

if (-not $outputPath.StartsWith($publishRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to use an output directory outside '$publishRoot': $outputPath"
}

if ($Clean) {
    if (Test-Path -LiteralPath $outputPath) {
        Write-Host "Cleaning publish output: $outputPath"
        Remove-Item -LiteralPath $outputPath -Recurse -Force
    }
}

Write-Host "Publishing BaGetter"
Write-Host "  Runtime: $runtimeIdentifier"
Write-Host "  Mode:    $dependencyMode"
Write-Host "  Output:  $outputPath"

$restoreArguments = @(
    'restore',
    $projectPath,
    '--runtime', $runtimeIdentifier,
    '--disable-parallel',
    '--disable-build-servers',
    '-p:BuildInParallel=false',
    '-m:1'
)

& $dotnetCommand.Source @restoreArguments
if ($LASTEXITCODE -ne 0) {
    throw "dotnet restore failed with exit code $LASTEXITCODE."
}

if ($Clean) {
    Write-Host "Cleaning Release build outputs for $runtimeIdentifier"
    $cleanArguments = @(
        'clean',
        $projectPath,
        '--configuration', 'Release',
        '--runtime', $runtimeIdentifier,
        '--disable-build-servers',
        '-p:BuildInParallel=false',
        '-m:1'
    )

    & $dotnetCommand.Source @cleanArguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet clean failed with exit code $LASTEXITCODE."
    }
}

$publishArguments = @(
    'publish',
    $projectPath,
    '--configuration', 'Release',
    '--runtime', $runtimeIdentifier,
    '--self-contained', $SelfContained.IsPresent.ToString().ToLowerInvariant(),
    '--no-restore',
    '--disable-build-servers',
    '-p:BuildInParallel=false',
    '-m:1',
    '--output', $outputPath
)

& $dotnetCommand.Source @publishArguments
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE."
}

Write-Host "Publish completed: $outputPath"
