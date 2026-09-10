param([string]$InputFile = ".env", [string]$OutputFile = "env.production.json")
$ErrorActionPreference = "Stop"
$map = @{}
Get-Content $InputFile | ForEach-Object {
  $line = $_.Trim()
  if (!$line -or $line.StartsWith('#')) { return }
  $i = $line.IndexOf('=')
  if ($i -le 0) { return }
  $key = $line.Substring(0,$i).Trim()
  $value = $line.Substring($i+1).Trim()
  if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) { $value = $value.Substring(1,$value.Length-2) }
  $map[$key] = $value
}
$map | ConvertTo-Json | Set-Content $OutputFile
Write-Host "Created $OutputFile. Do not commit it if it contains sensitive local values."
