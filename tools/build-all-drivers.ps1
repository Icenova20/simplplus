# Master Build Script for Portable Crestron Drivers
$ErrorActionPreference = "Stop"
$msbuildPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
$SplusccPath = "C:\Program Files (x86)\Crestron\Simpl\Spluscc.exe"

# Workspace Relative Paths
$WorkspaceRoot = Split-Path $PSScriptRoot -Parent
$BaseDir = Join-Path $WorkspaceRoot "modules\drivers"
$ModularSimplDir = Join-Path $WorkspaceRoot "modules\simpl"

# Tool Validation
if (-not (Test-Path $msbuildPath)) { Write-Error "MSBuild not found at $msbuildPath"; exit 1 }
if (-not (Test-Path $SplusccPath)) { Write-Error "Simpl+ Compiler not found at $SplusccPath"; exit 1 }

if (-not (Test-Path $ModularSimplDir)) { New-Item -ItemType Directory -Path $ModularSimplDir | Out-Null }

$script:buildLog = @()
function Add-BuildLogEntry { param($Name, $Status, $Message) $script:buildLog += [PSCustomObject]@{ Name = $Name; Status = $Status; Message = $Message } }

$Projects = @(
    "CiscoExternalSource\CiscoExternalSource.csproj",
    "SonosControl\SonosControl.csproj",
    "ShureMxw\ShureMxw.csproj",
    "PlanarDisplay\PlanarDisplay.csproj",
    "NvxRouteManager\NvxRouteManager.csproj",
    "ShureMxa920\ShureMxa920.csproj"
)

foreach ($ProjRelPath in $Projects) {
    $ProjPath = Join-Path $BaseDir $ProjRelPath
    Write-Host "Building: $ProjPath" -ForegroundColor Cyan
    
    & $msbuildPath $ProjPath /t:Restore /v:m
    & $msbuildPath $ProjPath /t:Build /p:Configuration=Release /p:Platform="Any CPU" /v:n
    
    if ($LASTEXITCODE -eq 0) {
        # Copy CLZ to Simpl directory
        $ProjName = [System.IO.Path]::GetFileNameWithoutExtension($ProjRelPath)
        $ClzSearch = Get-ChildItem -Path (Split-Path $ProjPath) -Filter "$ProjName.clz" -Recurse | Select-Object -First 1
        
        if ($null -ne $ClzSearch) {
            $ClzPath = $ClzSearch.FullName
            # Deploy to production module library
            Copy-Item $ClzPath $ModularSimplDir -Force
            
            Write-Host "Deployed: $ProjName.clz" -ForegroundColor Green
            Add-BuildLogEntry $ProjName "SUCCESS" "C# Build and CLZ Deployment complete."
        }
    }
    else {
        Write-Host "`nERROR: C# Build Failed for $ProjPath" -ForegroundColor Red
        Add-BuildLogEntry $ProjRelPath "FAILED" "MSBuild returned non-zero exit code."
    }
}

Write-Host "`nWiping SPlsWork Caches..." -ForegroundColor Cyan
Remove-Item -Path (Join-Path $ModularSimplDir "SPlsWork") -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nCompiling SIMPL+ Modular Wrappers..." -ForegroundColor Cyan
$ModularUspFiles = Get-ChildItem -Path $ModularSimplDir -Filter "*.usp"
foreach ($Usp in $ModularUspFiles) {
    Write-Host "Compiling Modular: $($Usp.Name)..." -ForegroundColor Yellow
    & $SplusccPath /rebuild $Usp.FullName /target series4
    if ($LASTEXITCODE -eq 0) {
        $ushPath = Join-Path $ModularSimplDir ($Usp.Name -replace ".usp", ".ush")
        
        # Immediate UMC Generation for this USH
        Write-Host "Generating UMC for $($Usp.Name)..." -ForegroundColor Cyan
        & ".\generate-umc-wrappers.ps1" -TargetUsh $ushPath -ModularSimplDir $ModularSimplDir
        
        $umcName = $Usp.Name -replace ".usp", ".umc"
        $umcPath = Join-Path $ModularSimplDir $umcName
        if (Test-Path $umcPath) {
            Write-Host "Deployed: $umcName" -ForegroundColor Green
            Add-BuildLogEntry $Usp.Name "SUCCESS" "Compiled USP and Generated/Deployed UMC."
        }
        else {
            Add-BuildLogEntry $Usp.Name "WARNING" "Compiled USP but UMC Generation failed/skipped."
        }
    }
    else {
        Write-Host "`nERROR: SIMPL+ compilation failed for $($Usp.Name)" -ForegroundColor Red
        Add-BuildLogEntry $Usp.Name "FAILED" "Simpl+ Compiler returned non-zero exit code."
    }
}

# Final Summary Report
$line = "=" * 50
$summary = @()
$summary += "`n`n$line"
$summary += " FINAL BUILD SUMMARY"
$summary += "$line"

$failedCount = 0
foreach ($item in $script:buildLog) {
    if ($item.Status -eq "FAILED") { $failedCount++ }
    $summary += ("[{0,-7}] {1,-30} : {2}" -f $item.Status, $item.Name, $item.Message)
}

$summary += "$line"
if ($failedCount -gt 0) {
    $summary += "Build finished with $failedCount errors."
}
else {
    $summary += "All components built and deployed successfully!"
}

# Output to both Console and Pipeline
foreach ($s in $summary) {
    # Determine color for console
    $color = "White"
    if ($s -match "\[SUCCESS\]") { $color = "Green" }
    elseif ($s -match "\[WARNING\]") { $color = "Yellow" }
    elseif ($s -match "\[FAILED\]" -or $s -match "errors") { $color = "Red" }
    elseif ($s -match "successfully") { $color = "Green" }
    
    Write-Host $s -ForegroundColor $color
    $s | Out-File -FilePath "build_summary.txt" -Append
}
if ($failedCount -gt 0) { exit 1 }
