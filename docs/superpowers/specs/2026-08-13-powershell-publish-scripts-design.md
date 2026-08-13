# PowerShell Publish Scripts Design

## Goal

Provide convenient PowerShell scripts for publishing BaGetter for Windows and Linux, with either a bundled .NET runtime or a required external .NET runtime. Both x64 and ARM64 targets must be supported.

## Structure

Create a `scripts` directory containing one shared implementation and four thin entry-point wrappers:

- `Publish.ps1`
- `Publish-Windows-SelfContained.ps1`
- `Publish-Windows-FrameworkDependent.ps1`
- `Publish-Linux-SelfContained.ps1`
- `Publish-Linux-FrameworkDependent.ps1`

The wrappers delegate to `Publish.ps1` so restore and publish behavior is defined in one place.

## Interface

`Publish.ps1` accepts:

- `-Platform Windows|Linux`, required;
- `-SelfContained`, optional switch;
- `-Arm`, optional switch selecting ARM64 instead of x64;
- `-Clean`, optional switch that removes only the selected output directory before publishing.

Each wrapper exposes `-Arm` and `-Clean` and supplies its fixed platform and dependency mode to the shared script.

Examples:

```powershell
.\scripts\Publish-Linux-SelfContained.ps1
.\scripts\Publish-Linux-SelfContained.ps1 -Arm
.\scripts\Publish.ps1 -Platform Windows -SelfContained -Arm -Clean
```

## Runtime identifiers and outputs

The shared script maps parameters to these runtime identifiers:

| Platform | Default | With `-Arm` |
| --- | --- | --- |
| Windows | `win-x64` | `win-arm64` |
| Linux | `linux-x64` | `linux-arm64` |

Published files are placed under `artifacts/publish` in a directory whose name includes the platform, architecture, and dependency mode, for example:

```text
artifacts/publish/linux-x64-self-contained/
artifacts/publish/windows-arm64-framework-dependent/
```

## Publish behavior

The scripts publish only `src/BaGetter/BaGetter.csproj` in Release configuration. They perform an explicit runtime-specific restore followed by publish with `--no-restore`. Self-contained builds pass `--self-contained true`; framework-dependent builds pass `--self-contained false`. Trimming and single-file publishing are not enabled.

The scripts resolve all paths relative to their own location, so they work regardless of the caller's current directory.

## Error handling and safety

Execution stops on the first failed native command. The shared script checks that `dotnet` is available before starting and reports the resolved runtime identifier and output directory.

`-Clean` may delete only the fully resolved directory beneath `artifacts/publish`; the script validates this boundary before removal. No other directories are removed.

## Verification

Tests statically and behaviorally verify parameter mapping, wrapper delegation, safe output paths, and failure when `dotnet` is unavailable. A publish smoke test runs a framework-dependent Windows publish locally. Linux and self-contained command construction are verified without requiring all runtime packs to be downloaded during routine tests.
