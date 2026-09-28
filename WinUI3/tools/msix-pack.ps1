<#
.SYNOPSIS
    Packages an unpackaged WinUI 3 example into a signed MSIX and installs it.

.DESCRIPTION
    Chapter 42's hands-on pipeline, scripted: build layout -> hand-written
    AppxManifest -> makeappx pack -> self-signed cert -> signtool sign ->
    trust -> Add-AppxPackage. Run AFTER building the example (Debug|x64).

.EXAMPLE
    pwsh tools/msix-pack.ps1 -Example 37-media-library -ExeName MediaLibrary.exe `
        -Identity GuideTutorial.MediaLibrary -DisplayName "Media Library (guide)"
#>
param(
    [Parameter(Mandatory)] [string]$Example,
    [Parameter(Mandatory)] [string]$ExeName,
    [Parameter(Mandatory)] [string]$Identity,
    [Parameter(Mandatory)] [string]$DisplayName,
    [string]$Publisher = 'CN=GuideTutorial',
    # 1.0.0.0-style version for the manifest
    [string]$Version = '1.0.0.0',
    [switch]$Keep     # keep cert/package after the run for inspection
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$out  = Join-Path $root "examples\$Example\x64\Debug"
# The self-contained deploy folder is named after the project (<proj>\<exe>.exe);
# fall back to the plain output folder for projects that deploy in place.
if (-not (Test-Path (Join-Path $out $ExeName)))
{
    $deploy = Get-ChildItem $out -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName $ExeName) } |
        Select-Object -First 1
    if ($deploy) { $out = $deploy.FullName }
}
if (-not (Test-Path (Join-Path $out $ExeName))) { throw "build output not found: $out\$ExeName (build first)" }

# --- locate makeappx + signtool in the newest Windows SDK ---
$sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
$sdk = Get-ChildItem $sdkRoot -Directory | Sort-Object Name -Descending |
    Where-Object { Test-Path (Join-Path $_.FullName 'x64\makeappx.exe') } | Select-Object -First 1
if (-not $sdk) { throw 'no Windows SDK with makeappx found' }
$makeappx = Join-Path $sdk.FullName 'x64\makeappx.exe'
$signtool = Join-Path $sdk.FullName 'x64\signtool.exe'
"SDK: $($sdk.FullName)"

# --- stage the layout (payload only; skip symbols/obj leftovers) ---
$stage = Join-Path $root "examples\$Example\.msix-stage"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory $stage | Out-Null
$exclude = '*.pdb', '*.lib', '*.exp', '*.ilk', '*.iobj', '*.ipdb', '*.pri?'
Copy-Item (Join-Path $out '*') $stage -Exclude $exclude -Recurse
if (Test-Path (Join-Path $stage 'Assets')) { Copy-Item (Join-Path $out 'Assets') $stage -Recurse -Force }

# --- hand-written AppxManifest ---
$manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap rescap">
  <Identity Name="$Identity" Publisher="$Publisher" Version="$Version"
            ProcessorArchitecture="x64" />
  <Properties>
    <DisplayName>$DisplayName</DisplayName>
    <PublisherDisplayName>Guide Tutorial</PublisherDisplayName>
    <Logo>Assets\appicon.png</Logo>
  </Properties>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0"
                        MaxVersionTested="10.0.26100.0" />
  </Dependencies>
  <Resources>
    <Resource Language="en-US" />
  </Resources>
  <Applications>
    <Application Id="App" Executable="$ExeName" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="$DisplayName" Description="WinUI 3 guide sample"
          BackgroundColor="#0078D7" Square150x150Logo="Assets\appicon.png"
          Square44x44Logo="Assets\appicon.png" />
    </Application>
  </Applications>
  <!-- Desktop (Win32) apps in MSIX must declare runFullTrust; makeappx rejects
       the manifest without it (0x80080204). -->
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
</Package>
"@
$manifest | Set-Content (Join-Path $stage 'AppxManifest.xml') -Encoding utf8

# 37 has its own icon; generate one for projects without Assets
if (-not (Test-Path (Join-Path $stage 'Assets'))) {
    New-Item -ItemType Directory (Join-Path $stage 'Assets') | Out-Null
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 48,48
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(255,0,120,212)); $g.Dispose()
    $bmp.Save((Join-Path $stage 'Assets\appicon.png'),
        [System.Drawing.Imaging.ImageFormat]::Png)
}

# --- self-signed code-signing cert (subject MUST equal Publisher) ---
$cert = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Subject -eq $Publisher -and $_.EnhancedKeyUsageList.FriendlyName -contains 'Code Signing' } |
    Select-Object -First 1
if (-not $cert) {
    $cert = New-SelfSignedCertificate -Type Custom -Subject $Publisher `
        -KeyUsage DigitalSignature -FriendlyName 'Guide tutorial signing' `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
    "cert created: $($cert.Thumbprint)"
}
$pfxPath = Join-Path $stage '..\signing.pfx'
$pw = ConvertTo-SecureString -String 'guide-tutorial' -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pw | Out-Null

# --- pack + sign ---
$msixPath = Join-Path $root "examples\$Example\$($Identity)_$Version.x64.msix"
if (Test-Path $msixPath) { Remove-Item $msixPath -Force }
& $makeappx pack /d $stage /p $msixPath /nv
if ($LASTEXITCODE) { throw 'makeappx failed' }

& $signtool sign /fd SHA256 /a /f $pfxPath /p 'guide-tutorial' $msixPath
if ($LASTEXITCODE) { throw 'signtool failed' }

# --- trust the cert for this user, then install ---
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('TrustedPeople','CurrentUser')
$store.Open('ReadWrite'); $store.Add($cert); $store.Close()

Add-AppxPackage -Path $msixPath
$installed = Get-AppxPackage $Identity
"INSTALLED: $($installed.Name) $($installed.Version) -> $($installed.InstallLocation)"

if (-not $Keep) {
    # leave the package installed (launch from Start menu); clean the staging
    Remove-Item $stage -Recurse -Force
    Remove-Item $pfxPath -Force
}
"MSIX: $msixPath"
"uninstall with: Remove-AppxPackage $Identity"

# 42.4: AppX deployment only trusts certs in LOCALMACHINE stores -- adding the
# self-signed cert there needs one UAC elevation. Run this elevated snippet if
# Add-AppxPackage above failed with 0x800B0109:
#
#   $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
#       "<pfx path>", "guide-tutorial")
#   $s = New-Object System.Security.Cryptography.X509Certificates.X509Store('TrustedPeople','LocalMachine')
#   $s.Open('ReadWrite'); $s.Add($cert); $s.Close()
#   Add-AppxPackage -Path "<msix path>"
