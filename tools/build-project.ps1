param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectName
)

$ErrorActionPreference = "Stop"
$SplusccPath = "C:\Program Files (x86)\Crestron\Simpl\Spluscc.exe"
if (-not (Test-Path $SplusccPath)) { Write-Error "Simpl+ Compiler not found at $SplusccPath"; exit 1 }

$WorkspaceRoot = Split-Path $PSScriptRoot -Parent
$ModularSimplDir = Join-Path $WorkspaceRoot "modules\simpl"
$ProjectDir = Join-Path $WorkspaceRoot "projects\$ProjectName"

if (-not (Test-Path $ProjectDir)) {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

$DependenciesPath = Join-Path $ProjectDir "dependencies.json"
if (-not (Test-Path $DependenciesPath)) {
    Write-Error "dependencies.json not found in $ProjectDir"
    exit 1
}

$Deps = Get-Content $DependenciesPath | ConvertFrom-Json
$TargetSimplDir = Join-Path $ProjectDir $Deps.TargetSimplDir

if (-not (Test-Path $TargetSimplDir)) {
    New-Item -ItemType Directory -Path $TargetSimplDir | Out-Null
}

Write-Host "Pulling dependencies for $ProjectName..." -ForegroundColor Cyan

foreach ($Mod in $Deps.Modules) {
    Write-Host "  Copying $Mod..."
    
    $SearchPattern = $Mod -creplace "([a-z])([A-Z])", '$1*$2'
    
    $Extensions = @(".clz", ".ush", ".umc", ".usp")
    foreach ($Ext in $Extensions) {
        $Files = Get-ChildItem -Path $ModularSimplDir -Filter "*$SearchPattern*$Ext" -ErrorAction SilentlyContinue
        foreach ($File in $Files) {
            Copy-Item $File.FullName $TargetSimplDir -Force
            Write-Host "    -> Copied $($File.Name)" -ForegroundColor DarkGray
        }
    }
}

Write-Host "`nCompiling SIMPL+ Project Logic in $TargetSimplDir..." -ForegroundColor Cyan
Remove-Item -Path (Join-Path $TargetSimplDir "SPlsWork") -Recurse -Force -ErrorAction SilentlyContinue

$LogicUspFiles = Get-ChildItem -Path $TargetSimplDir -Filter "*.usp"
$LogicCompiles = 0
$failedCount = 0

foreach ($Usp in $LogicUspFiles) {
    $isDep = $false
    foreach ($Mod in $Deps.Modules) {
        if ($Usp.Name -like "$Mod*") { $isDep = $true; break }
    }
    
    if (-not $isDep) {
        Write-Host "Compiling Project Logic: $($Usp.Name)..." -ForegroundColor Yellow
        & $SplusccPath /rebuild $Usp.FullName /target series4
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully compiled $($Usp.Name)" -ForegroundColor Green
            $LogicCompiles++
        }
        else {
            Write-Host "`nERROR: Logic compilation failed for $($Usp.Name)" -ForegroundColor Red
            $failedCount++
        }
    }
}

Write-Host "`nProject Build Summary for $($ProjectName):" -ForegroundColor Cyan
Write-Host "Dependencies pulled: $($Deps.Modules.Count)"
Write-Host "Project logic files compiled: $LogicCompiles"
if ($failedCount -gt 0) {
    Write-Host "Finished with $failedCount errors." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "Build completed successfully!" -ForegroundColor Green
}
