<#
    Create or update release with given tag. Also upload files.
    GH_TOKEN is mandatory!
#>
########################################
Set-StrictMode -Version 3.0            #
$ErrorActionPreference = "Stop"        #
########################################

[string]$InputDir = $args[0]
[string]$ReleaseVersion = $args[1]
[string]$Repo = $args[2]
[string]$Branch = $args[3]
[string]$CurrentLocation = (Get-Location)

$Files = @(Get-ChildItem -Path "$InputDir/*" -File -Include "*.tgz", "*.zip" -ErrorAction SilentlyContinue)
if ($Files.Count -eq 0)
{
    Write-Error ('::error title=Files not found::Cannot READ files in location: {0}' -f $InputDir)
    exit 2
}

Write-Host "Check if release exists"
gh release create $ReleaseVersion -R $Repo --generate-notes --target $Branch --title "$ReleaseVersion branch $Branch"
if ($LASTEXITCODE -gt 1)
{
    Write-Error ('::error title=Cannot create or check release::Tag: {0}, Repo: {1}, ErrorCode: {2}' -f $ReleaseVersion, $Repo, $LASTEXITCODE)
    exit 255
}

Write-Host "Start upload"
Set-Location $InputDir
$Files | ForEach-Object {
    Write-Host ('Uploading {0}' -f $_.Name)
    gh release upload $ReleaseVersion $_.Name -R $Repo --clobber
}

Write-Host "Release edit"
gh release edit $ReleaseVersion -R $Repo --latest --target $Branch

Set-Location $CurrentLocation
