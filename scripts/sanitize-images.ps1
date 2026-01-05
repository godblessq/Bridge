<#
Sanitize and rename image files to match filenames listed in products.json.

Usage (dry-run):
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\sanitize-images.ps1 -WhatIfRun

To perform changes:
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\sanitize-images.ps1

This script:
- Reads `products.json` in the repo root
- For each product, ensures files exist at the exact relative paths listed in the `images` array
- If a listed file is missing, attempts to find a candidate in the product's images folder by a
  simplified-name match (removes spaces, parentheses, non-alphanumerics) and renames it to the
  target filename.

Note: Review changes before committing. The script will create product folders if required.
#>

param(
  [switch]$WhatIfRun
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$productsPath = Join-Path $root 'products.json'
if(-not (Test-Path $productsPath)){
  Write-Error "products.json not found at $productsPath"; exit 1
}

Function SimplifyName([string]$s){
  if(-not $s){ return '' }
  $s = $s.ToLowerInvariant()
  # Replace spaces and parentheses with hyphens, remove other unsafe chars
  $s = $s -replace '[\s\(\)\[\]]','-'
  $s = $s -replace '[^a-z0-9\.\-_]',''
  $s = $s -replace '-+','-'
  return $s.Trim('-')
}

$products = Get-Content $productsPath -Raw | ConvertFrom-Json

foreach($p in $products){
  $productDir = Join-Path $root "images\$($p.id)"
  if(-not (Test-Path $productDir)){
    Write-Host "Product folder missing:" $productDir -ForegroundColor Yellow
    continue
  }

  $files = Get-ChildItem -Path $productDir -File -ErrorAction SilentlyContinue
  if(-not $files){ Write-Host "No files in" $productDir -ForegroundColor Yellow; continue }

  foreach($imgRel in $p.images){
    $targetName = [System.IO.Path]::GetFileName($imgRel)
    $targetPath = Join-Path $root $imgRel
    if(Test-Path $targetPath){
      Write-Host "OK:" $imgRel -ForegroundColor Green
      continue
    }

    $targetSimple = SimplifyName($targetName)
    $candidate = $null
    foreach($f in $files){
      if(SimplifyName($f.Name) -eq $targetSimple){
        $candidate = $f; break
      }
    }

    if($candidate){
      Write-Host "Will rename:" $candidate.Name "->" $imgRel
      if(-not $WhatIfRun){
        $destDir = Split-Path $targetPath -Parent
        if(-not (Test-Path $destDir)){ New-Item -ItemType Directory -Path $destDir | Out-Null }
        Move-Item -LiteralPath $candidate.FullName -Destination $targetPath -Force
        Write-Host "Renamed" -ForegroundColor Cyan
      }
    } else {
      Write-Host "No candidate found for" $targetName "in" $productDir -ForegroundColor Red
    }
  }
}

Write-Host "Done. Review changes and commit if correct." -ForegroundColor Green
