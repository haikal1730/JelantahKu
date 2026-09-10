param(
  [Parameter(Mandatory=$true)][string]$KeystorePath,
  [Parameter(Mandatory=$true)][string]$StorePassword,
  [Parameter(Mandatory=$true)][string]$KeyPassword,
  [string]$Alias = "jelantahku-release"
)
$ErrorActionPreference = "Stop"
$androidDir = Join-Path $PSScriptRoot "..\android"
$relative = (Resolve-Path $KeystorePath).Path
$escaped = $relative.Replace('\','\\')
@"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$Alias
storeFile=$escaped
"@ | Set-Content (Join-Path $androidDir 'key.properties')
Write-Host "Created android/key.properties (do not commit)."
