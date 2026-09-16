# winmd-probe

Reads Windows Runtime metadata (`.winmd`, and projection assemblies such as
`Microsoft.WinUI.dll`) and dumps types, implemented interfaces and public method
signatures.

## Why this exists

API claims in this tutorial used to be checked by eye against the docs site, which drifts
from the SDK actually installed. `winmd-probe` checks them against the real metadata on
disk instead — and it needs **no Windows SDK, no cppwinrt and no build**: it targets
`net8.0` and uses only `System.Reflection.Metadata`, which ships in the base class
library. That made it the first line of verification, before a compiling environment
existed at all (see the repo-root `WinUI3/README.md` 「验证状态」).

It proves a signature *exists* and its *shape*. It cannot prove runtime behaviour.

## Build

```powershell
.\build.ps1                 # Release build + two smoke tests against the NuGet cache
.\build.ps1 -Configuration Debug
```

`build.ps1` locates `dotnet.exe` (PATH, then `D:\scoop\apps\dotnet-sdk\current`, then
`C:\Program Files\dotnet`). Output lands in `bin/<Configuration>/net8.0/winmd-probe.dll`;
`RollForward=LatestMajor` lets a newer installed runtime run the `net8.0` build.

## Usage

```
winmd-probe <file.winmd> [TypeFilter] [--types-only]
winmd-probe --find <TypeName> [searchDir]
```

- `TypeFilter` — substring match on the namespace-qualified type name.
- `--types-only` — print type names without members.
- `--find` — scan every `*.winmd` (plus `Microsoft.WinUI.dll`) under `searchDir`
  (default: `%USERPROFILE%\.nuget\packages`) for a type and report **which metadata file
  declares it**. Exit code 2 when nothing matches. This is the workhorse for questions
  like "which namespace is `INotifyPropertyChanged` actually in?"

## Examples

```powershell
# Which metadata file declares INotifyPropertyChanged, and under what name?
.\winmd-probe.dll --find "Xaml.Data.INotifyPropertyChanged"

# Full public surface of the WASDK file picker
.\winmd-probe.dll "$HOME\.nuget\packages\...\Microsoft.Windows.Storage.Pickers.winmd" `
                  "Microsoft.Windows.Storage.Pickers.FileOpenPicker"

# Just the type names in Microsoft.UI.Xaml.winmd that mention Window
.\winmd-probe.dll Microsoft.UI.Xaml.winmd Window --types-only
```

## Findings it produced

Running `--find` against the local 1.8 cache is what surfaced several
"looks right, does not compile" claims now corrected in the chapters, e.g. `Window` has no
`XamlRoot` member; `ICommand` / `INotifyPropertyChanged` / `INotifyCollectionChanged` live
in `Microsoft.UI.Xaml.Input` / `.Data` / `.Interop`, not `System.Windows.*`; and the WASDK
`FileOpenPicker` takes its `WindowId` as a constructor argument rather than a settable
property.
