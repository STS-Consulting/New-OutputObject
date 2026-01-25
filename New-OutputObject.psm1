<#

    .SYNOPSIS
    The PowerShell module New-OutputObject function

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, FileSystem, File, Folder

    CURRENT VERSION
    - 0.3.0 - 2017-10-16

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

#>

Set-StrictMode -Version Latest

#Get public and private function definition files

$PublicFunctions = @(
    'New-OutputFile.ps1'
    'New-OutputFolder.ps1'
    'New-OutputObject.ps1'
)

$PrivateFunctions = @(
    'Get-OverwriteDecision.ps1'
    'Test-CharsInPath.ps1'
)

$PublicValues = $PublicFunctions | ForEach-Object { Join-Path -Path $PSScriptRoot -ChildPath (Join-Path -Path 'Public' -ChildPath $PSItem ) }
$PrivateValues = $PrivateFunctions | ForEach-Object { Join-Path -Path $PSScriptRoot -ChildPath (Join-Path -Path 'Private' -ChildPath $PSItem ) }

#Dot source the files
foreach ($import in @($PublicValues + $PrivateValues)) {
    try {
        Write-Verbose "Import file: $import"
        . $import
    } catch {
        Write-Error -Message "Failed to import file $import : $PSItem"
    }
}
