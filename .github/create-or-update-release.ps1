<#
    Create or update release with given tag. Also upload files.
    GH_TOKEN is mandatory!
#>
########################################
Set-StrictMode -Version 3.0            #
$ErrorActionPreference = "Stop"        #
########################################

[string]$InputDir = $args[0]
[string]$AppName = $args[1]
[string]$ReleaseVersion = $args[2]
[string]$Repo = $args[3]
[string]$Branch = $args[4]
[string]$Sha = $args[5]
[string]$CurrentLocation = (Get-Location)
[string]$Tag = "$ReleaseVersion"

function Format-Bytes
{
    param(
        [int]$number
    )
    $sizes = 'KB', 'MB', 'GB', 'TB', 'PB'
    for ($x = 0; $x -lt $sizes.count; $x++) {
        if ($number -lt [int64]"1$( $sizes[$x] )")
        {
            if ($x -eq 0)
            {
                return "$number B"
            }
            else
            {
                $formattedNumber = $number / [int64]"1$( $sizes[$x - 1] )"
                $formattedNumber = "{0:N2}" -f $formattedNumber
                return "$formattedNumber $( $sizes[$x - 1] )"
            }
        }
    }
}

Set-Location $InputDir
[string]$ZipName = ('{0}.zip' -f $AppName)

New-Item -Name $AppName -ItemType Directory
Copy-Item -Force -Verbose -Path "./$AppName.*" -Destination "./$AppName"
Copy-Item -Force -Verbose -Path "./version" -Destination "./$AppName"
Copy-Item -Force -Verbose -Path "./manifest.json" -Destination "./$AppName"

zip -r -qq $ZipName "./$AppName"

if (!(Test-Path -Path $ZipName -PathType Leaf))
{
    Write-Error '::error title=Files not found::Cannot find files in location'
    exit 1
}

[string]$ZipSize = Format-Bytes (Get-Item -Path $ZipName).Length

$Files = @(Get-ChildItem -Path "./*" -File -Include "*.zip" -ErrorAction SilentlyContinue)
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

[string]$Mime = "Accept: application/vnd.github+json"
[string]$Api = "X-GitHub-Api-Version: 2022-11-28"
$Json = ((gh api -H $Mime -H $Api /repos/$Repo/releases) | ConvertFrom-Json)
$TagExists = ($null -ne ($Json.GetEnumerator() | Where-Object { $_.tag_name -eq "$Tag" }))
if ($false -eq $TagExists)
{
    gh api --method POST -H $Mime -H $Api /repos/$Repo/releases -f tag_name="$Tag" -f target_commitish="$Sha" -f name="$Tag" -F draft=false -F prerelease=false -F generate_release_notes=true

    if ($LASTEXITCODE -gt 1)
    {
        Write-Error ('::error title=Failed to create new tag::Tag: {0}, Repo: {1}, ErrorCode: {2}' -f $ReleaseVersion, $Repo, $LASTEXITCODE)
        exit 255
    }
}
gh release upload "$Tag" "$ZipName#$ZipName $ZipSize" --clobber -R $Repo

if ($LASTEXITCODE -gt 1)
{
    Write-Error ('::error title=Failed to upload::Tag: {0}, Repo: {1}, ErrorCode: {2}' -f $ReleaseVersion, $Repo, $LASTEXITCODE)
    exit 255
}

gh release edit "$Tag" --draft=false -R $Repo

if ($LASTEXITCODE -gt 1)
{
    Write-Error ('::error title=Failed to edit release::Tag: {0}, Repo: {1}, ErrorCode: {2}' -f $ReleaseVersion, $Repo, $LASTEXITCODE)
    exit 255
}

Set-Location $CurrentLocation
