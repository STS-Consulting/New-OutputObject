<#
    .SYNOPSIS
    Pester tests to validate the New-OutputObject.ps1 function

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, Pester, psd1, New-OutputObject, New-OutputObject

    CURRENT VERSION
    - 0.9.13 - 2017-05-01

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

#>

$ModuleName = 'New-OutputObject'

$VerboseInternal = $false

if (-not $TestDrive) { $TestDrive = $Env:TEMP }

#Provided path asume that your module manifest (a file with the psd1 extension) exists in the parent directory for directory where the current test script is stored
$RelativePathToModuleManifest = '{0}{2}..{2}{1}.psd1' -f $PSScriptRoot, $ModuleName, [System.IO.Path]::DirectorySeparatorChar

#Remove module if it's currently loaded
Get-Module -Name $ModuleName -ErrorAction SilentlyContinue | Remove-Module

Import-Module -FullyQualifiedName $RelativePathToModuleManifest -Force -Scope Global

$FunctionName = 'New-OutputObject'

$ObjectTypes = @('File', 'Folder')

foreach ($ObjectType in $ObjectTypes) {

    Describe "Tests for $FunctionName and the ObjectType [$ObjectType]" {

        BeforeEach {
            $LocationAtBegin = Get-Location
            Set-Location $TestDrive

            if ($ObjectType -eq 'File') {
                $ItemTypeLower = 'file'
                $ExpectedObjectType = [System.IO.FileInfo]
                [System.String]$DateTimeFormatToMock = 'yyyyMMdd-HHmmss'

                if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $ISLinux) {
                    [String]$IncorrectFileNameOnly = "Test-File-201606$([char]0)08-1315.txt"
                    [String]$IncorrectDateTimeFormat = 'yyyy/MM/dd-HH:mm:ss'
                } elseif ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $IsMacOS) {
                    [String]$IncorrectFileNameOnly = "Test-File-201606$([char]58)08-1315.txt"
                    [String]$IncorrectDateTimeFormat = 'yyyyMMdd-HH:mm:ss'
                } else {
                    [String]$IncorrectFileNameOnly = 'Test-File-201606*08-1315.txt'
                    [String]$IncorrectDateTimeFormat = 'yyyyMMdd-HH:mm:ss'
                }

            } else {
                $ItemTypeLower = 'folder'
                $ExpectedObjectType = [System.IO.DirectoryInfo]
                [System.String]$DateTimeObjectToMock = 'yyyyMMdd'

                if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $ISLinux) {
                    [String]$IncorrectDirectoryOnly = "/usr/share/loc$([char]0)al/"
                    [String]$IncorrectDateTimeFormat = 'yyyy/MM/dd-HH:mm:ss'
                } elseif ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $IsMacOS) {
                    [String]$IncorrectDirectoryOnly = "/usr/share/loc$([char]58)al/"
                    [String]$IncorrectDateTimeFormat = 'yyyy-MM-dd-HH:mm:ss'
                } elseif ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $IsWindows) {
                    #chars UTF8 34, 60,62 for [System.IO.Path]::GetInvalidPathChars()
                    [String]$IncorrectDirectoryOnly = 'C:\AppData\Loc|al\'
                    [String]$IncorrectDateTimeFormat = 'yyyy-MM-dd-HH|mm:ss'
                } else {
                    [String]$IncorrectDirectoryOnly = 'C:\AppData\Loc>al\'
                    [String]$IncorrectDateTimeFormat = 'yyyy-MM-dd-HH>mm:ss'
                }
            }
        }

        $ContextName = 'run without parameters'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType
            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0
            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'
            }

        }

        $ContextName = 'run with OutputObjectNamePrefix'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'AAA-20161108-000002.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -OutputFileNamePrefix 'AAA'

            } else {
                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'AAA-20161108'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -OutputFolderNamePrefix 'AAA'

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -OutputObjectNamePrefix 'AAA'

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }


            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0
            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'
            }
        }

        $ContextName = 'run with OutputObjectNameStem'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-BBB-20161108-000002.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -OutputFileNameStem 'BBB'

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-BBB-20161108'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -OutputFolderNameStem 'BBB'

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -OutputObjectNameStem 'BBB'

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType
            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName
            }


            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0
            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'
            }

        }

        $ContextName = 'run with OutputObjectNameSuffix'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002-CCC.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -OutputFileNameSuffix 'CCC'

            } else {
                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-CCC'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -OutputFolderNameSuffix 'CCC'

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -OutputObjectNameSuffix 'CCC'

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType
            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName
            }


            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }


        $ContextName = 'run with DateTimePartInOutputFileName'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161101-120001' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161101-120001.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -DateTimePartInOutputFileName (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161101' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161101'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -DateTimePartInOutputFolderName (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -DateTimePartInOutputObjectName (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')


            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }

        $ContextName = 'run with DateTimePartInOutputObjectName, without DateTimePart'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                $ExpectedOutputObjectName = 'Output.txt'

                $params = @{

                    DateTimePartInOutputFileName        = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                    IncludeDateTimePartInOutputFileName = $false

                }

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal @params

            } else {

                $ExpectedOutputObjectName = 'Output'

                $params = @{

                    DateTimePartInOutputFolderName        = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                    IncludeDateTimePartInOutputFolderName = $false

                }

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal @params

            }

            $params = @{

                ObjectType                            = $ObjectType

                DateTimePartInOutputObjectName        = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                IncludeDateTimePartInOutputObjectName = $false

            }

            $Result = New-OutputObject @params

            It "Function $FunctionName - $ContextName - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }

        $ContextName = 'run with OutputFileNameExtension'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.csv'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -OutputFileNameExtension '.csv'

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -OutputFileNameExtension 'csv'

            It "Function $FunctionName - $ContextName - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }

        $ContextName = 'run with NamePartsSeparator'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output_20161108-000002.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -NamePartsSeparator '_'

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output_20161108'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -NamePartsSeparator '_'

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -NamePartsSeparator '_'

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }


            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }

        $ContextName = 'run with all name parts, with DateTimePartInOutputObjectName'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161101-120001' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'AAA-BBB-20161101-120001-CCC.txt'

                $params = @{

                    OutputFileNamePrefix         = 'AAA'

                    OutputFileNameStem           = 'BBB'

                    OutputFileNameSuffix         = 'CCC'

                    DateTimePartInOutputFileName = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                }

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal @params

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161101' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'AAA-BBB-20161101-CCC'

                $params = @{

                    OutputFolderNamePrefix         = 'AAA'

                    OutputFolderNameStem           = 'BBB'

                    OutputFolderNameSuffix         = 'CCC'

                    DateTimePartInOutputFolderName = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                }

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal @params

            }

            $params = @{

                ObjectType                     = $ObjectType

                OutputObjectNamePrefix         = 'AAA'

                OutputObjectNameStem           = 'BBB'

                OutputObjectNameSuffix         = 'CCC'

                DateTimePartInOutputObjectName = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

            }

            $Result = New-OutputObject @params

            It "Function $FunctionName -  $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName -  $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName -  $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName -  $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }

        $ContextName = 'run with all name parts, without DateTimePart'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                $ExpectedOutputObjectName = 'AAA-BBB-CCC.txt'

                $params = @{

                    OutputFileNamePrefix                = 'AAA'

                    OutputFileNameStem                  = 'BBB'

                    OutputFileNameSuffix                = 'CCC'

                    DateTimePartInOutputFileName        = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                    IncludeDateTimePartInOutputFileName = $false

                }

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal @params

            } else {

                $ExpectedOutputObjectName = 'AAA-BBB-CCC'

                $params = @{

                    OutputFolderNamePrefix                = 'AAA'

                    OutputFolderNameStem                  = 'BBB'

                    OutputFolderNameSuffix                = 'CCC'

                    DateTimePartInOutputFolderName        = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                    IncludeDateTimePartInOutputFolderName = $false

                }

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal @params

            }

            $params = @{

                ObjectType                            = $ObjectType

                OutputObjectNamePrefix                = 'AAA'

                OutputObjectNameStem                  = 'BBB'

                OutputObjectNameSuffix                = 'CCC'

                DateTimePartInOutputObjectName        = (Get-Date -Date '2016-11-01 12:00:01' -Format 'yyyy-MM-dd hh:mm:ss')

                IncludeDateTimePartInOutputObjectName = $false

            }

            $Result = New-OutputObject @params

            It "Function $FunctionName -  $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName -  $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName -  $ContextName - exit code" {

                $Result.ExitCode | Should -Be 0

                $ResultProxyFunction.ExitCode | Should -Be 0

            }

            It "Function $FunctionName -  $ContextName - exit code description" {

                $Result.ExitCodeDescription | Should -Be 'Everything is fine :-)'

                $ResultProxyFunction.ExitCodeDescription | Should -Be 'Everything is fine :-)'

            }

        }

        $ContextName = 'run without parameters, non existing destination directory.'

        Context "Function $FunctionName - $ContextName" {

            $ParentPath = "$TestDrive\TestFolder"

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -ParentPath $ParentPath

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -ParentPath $ParentPath

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -ParentPath $ParentPath

            It "Function $FunctionName -  $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName -  $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName -  $ContextName - exit code" {

                $Result.ExitCode | Should -Be 1

                $ResultProxyFunction.ExitCode | Should -Be 1

            }

            It "Function $FunctionName -  $ContextName - exit code description" {

                [System.String]$RequiredMessage = "Provided parent path {0} doesn't exist" -f $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$ParentPath")

                $Result.ExitCodeDescription | Should -Be $RequiredMessage

            }

        }

        $ContextName = 'run with existing, non writable destination folder.'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

            }

            [String]$TestDestinationFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$TestDrive\ExistingNotWritable\")

            New-Item -Path $TestDestinationFolder -ItemType Directory | Out-Null

            if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and ($ISLinux - $IsMacOS)) {

                & chmod 0550 $TestDestinationFolder

            }
            #Windows
            else {

                $ChangedACL = $OriginalAcl = Get-Acl -Path $TestDestinationFolder

                $colRights = [System.Security.AccessControl.FileSystemRights]'AppendData,WriteData'

                $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None

                $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::InheritOnly

                $objType = [System.Security.AccessControl.AccessControlType]::Deny

                $objUser = New-Object System.Security.Principal.NTAccount($(whoami))

                $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType)

                $ChangedACL.AddAccessRule($objACE)

                Set-Acl -Path $TestDestinationFolder $ChangedACL

            }

            if ($ObjectType -eq 'File') {

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -ParentPath $TestDestinationFolder

            } else {

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -ParentPath $TestDestinationFolder

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -ParentPath $TestDestinationFolder

            It "Function $FunctionName -  $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName -  $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName -  $ContextName - exit code" {

                $Result.ExitCode | Should -Be 3

                $ResultProxyFunction.ExitCode | Should -Be 3

            }

            It "Function $FunctionName -  $ContextName - exit code description" {

                [System.String]$RequiredMessage = 'Provided path {0} is not writable' -f $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$TestDestinationFolder")

                $Result.ExitCodeDescription | Should -Be $RequiredMessage

                $ResultProxyFunction.ExitCodeDescription | Should -Be $RequiredMessage

            }

            #Restore ACLs to cleanly remove TestDrive
            if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and ($ISLinux - $IsMacOS)) {

                & chmod 0770 $TestDestinationFolder

            }

            else {

                Set-Acl -Path $TestDestinationFolder $OriginalAcl

            }

        }

        $ContextName = 'run with existing, non writable destination folder, break on error'

        Context "Function $FunctionName - $ContextName" {

            [String]$TestDestinationFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$TestDrive\ExistingNotWritable\")

            New-Item -Path $TestDestinationFolder -ItemType Container | Out-Null

            if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and ($ISLinux - $IsMacOS)) {

                & chmod 0550 $TestDestinationFolder

            }

            else {

                $ChangedACL = $OriginalAcl = Get-Acl -Path $TestDestinationFolder

                $colRights = [System.Security.AccessControl.FileSystemRights]'AppendData,WriteData'

                $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None

                $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::InheritOnly

                $objType = [System.Security.AccessControl.AccessControlType]::Deny

                $objUser = New-Object System.Security.Principal.NTAccount($(whoami))

                $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType)

                $ChangedACL.AddAccessRule($objACE)

                Set-Acl -Path $TestDestinationFolder $ChangedACL

            }

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                It "Function $FunctionName -  $ContextName - OutputObjectPath - an object type" {

                    { $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -ParentPath $TestDestinationFolder -BreakIfError } | Should -Throw

                    { $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -ParentPath $TestDestinationFolder -BreakIfError } | Should -Throw

                }

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                It "Function $FunctionName -  $ContextName - OutputObjectPath - an object type" {

                    { $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -ParentPath $TestDestinationFolder -BreakIfError } | Should -Throw

                    { $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -ParentPath $TestDestinationFolder -BreakIfError } | Should -Throw

                }

            }

            #Restore ACLs to cleanly remove TestDrive
            if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and ($ISLinux - $IsMacOS)) {

                & chmod 0770 $TestDestinationFolder

            }

            else {

                Set-Acl -Path $TestDestinationFolder $OriginalAcl

            }

        }

        [System.String]$ContextName = 'run without parameters, destination {0} exists, decision overwrite' -f $ObjectType

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

                $OutputTypeToCreate = 'file'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108-000002.txt"

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $OutputTypeToCreate = 'directory'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108"

            }

            New-Item -Path $TestExistingObject -ItemType $OutputTypeToCreate

            Mock -ModuleName New-OutputObject -CommandName Get-OverwriteDecision -MockWith { return [int]0 }

            if ($ObjectType -eq 'File') {

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal

            } else {

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 4

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                [System.String]$RequiredMessage = 'The {0} {1} already exist - can be overwritten' -f $ObjectType, $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$TestExistingObject")

                $Result.ExitCodeDescription | Should -Be $RequiredMessage

                $ResultProxyFunction.ExitCodeDescription | Should -Be $RequiredMessage

            }

        }

        [System.String]$ContextName = 'run without parameters, destination {0} exists, decision leave' -f $ObjectType

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

                $OutputTypeToCreate = 'file'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108-000002.txt"

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $OutputTypeToCreate = 'directory'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108"


            }


            New-Item -Path $TestExistingObject -ItemType $OutputTypeToCreate

            Mock -ModuleName New-OutputObject -CommandName Get-OverwriteDecision -MockWith { return [int]1 }

            if ($ObjectType -eq 'File') {

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal

            } else {

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal

            }

            $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 5

                $ResultProxyFunction.ExitCode | Should -Be 5

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                [System.String]$RequiredMessage = "The {0} {1} already exist - can't be overwritten" -f $ItemTypeLower, $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$TestExistingObject")

                $Result.ExitCodeDescription | Should -Be $RequiredMessage

                $ResultProxyFunction.ExitCodeDescription | Should -Be $RequiredMessage

            }

        }

        $ContextName = 'run without parameters, destination file exists, decision cancel'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

                $OutputTypeToCreate = 'file'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108-000002.txt"

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $OutputTypeToCreate = 'directory'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108"

            }

            New-Item -Path $TestExistingObject -ItemType $OutputTypeToCreate

            Mock -ModuleName New-OutputObject -CommandName Get-OverwriteDecision -MockWith { return [int]2 }

            if ($ObjectType -eq 'File') {

                It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                    { $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType } | Should -Throw

                    { $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal } | Should -Throw

                }

            } else {

                It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                    { $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType } | Should -Throw

                    { $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal } | Should -Throw


                }
            }

        }

        [System.String]$ContextName = 'run without parameters, destination {0} exists, the Force defined' -f $ObjectType

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

                $OutputTypeToCreate = 'file'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108-000002.txt"

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

                $OutputTypeToCreate = 'directory'

                [System.String]$TestExistingObject = "$TestDrive\Output-20161108"


            }


            New-Item -Path $TestExistingObject -ItemType $OutputTypeToCreate

            if ($ObjectType -eq 'File') {

                $ResultProxyFunction = New-OutputFile -Force -Verbose:$VerboseInternal

            } else {

                $ResultProxyFunction = New-OutputFolder -Force -Verbose:$VerboseInternal

            }

            $Result = New-OutputObject -Force -Verbose:$VerboseInternal -ObjectType $ObjectType

            It "Function $FunctionName - $ContextName - OutputObjectPath - an object type" {

                $Result.OutputObjectPath | Should -BeOfType $ExpectedObjectType

                $ResultProxyFunction.OutputObjectPath | Should -BeOfType $ExpectedObjectType

            }

            It "Function $FunctionName - $ContextName - OutputObjectPath - Name " {

                $Result.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

                $ResultProxyFunction.OutputObjectPath.Name | Should -Be $ExpectedOutputObjectName

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 6

                $ResultProxyFunction.ExitCode | Should -Be 6

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                [System.String]$RequiredMessage = 'The {0} {1} already exist - can be overwritten due to used the Force switch' -f $ItemTypeLower, $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$TestExistingObject")

                $Result.ExitCodeDescription | Should -Be $RequiredMessage

                $ResultProxyFunction.ExitCodeDescription | Should -Be $RequiredMessage

            }

        }

        $ContextName = 'run with incorrect chars in DateTimePartFormat, BreakIfError'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108-000002' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108-000002.txt'

            } else {

                Mock -ModuleName New-OutputObject -CommandName Get-Date -MockWith { return [System.String]'20161108' } -ParameterFilter { $Format }

                $ExpectedOutputObjectName = 'Output-20161108'

            }

            if ($ObjectType -eq 'File') {

                It "Function $FunctionName - $ContextName" {

                    { $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -DateTimePartFormat $IncorrectDateTimeFormat -BreakIfError } | Should -Throw

                    { $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -DateTimePartFormat $IncorrectDateTimeFormat -BreakIfError } | Should -Throw

                }

            } else {

                It "Function $FunctionName - $ContextName" {

                    { $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -DateTimePartFormat $IncorrectDateTimeFormat -BreakIfError } | Should -Throw

                    { $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -DateTimePartFormat $IncorrectDateTimeFormat -BreakIfError } | Should -Throw

                }

            }

        }

        $ContextName = 'run with incorrect chars in DateTimePartFormat, not BreakIfError'

        Context "Function $FunctionName - $ContextName" {

            if ($ObjectType -eq 'File') {

                $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -DateTimePartFormat $IncorrectDateTimeFormat

                $ResultProxyFunction = New-OutputFile -Verbose:$VerboseInternal -DateTimePartFormat $IncorrectDateTimeFormat

            } else {

                $Result = New-OutputObject -Verbose:$VerboseInternal -ObjectType $ObjectType -DateTimePartFormat $IncorrectDateTimeFormat

                $ResultProxyFunction = New-OutputFolder -Verbose:$VerboseInternal -DateTimePartFormat $IncorrectDateTimeFormat

            }

            It "Function $FunctionName - $ContextName - exit code" {

                $Result.ExitCode | Should -Be 2

                $ResultProxyFunction.ExitCode | Should -Be 2

            }

            It "Function $FunctionName - $ContextName - exit code description" {

                [System.String]$RequiredMessage = 'The name not created due to unaccepatable chars'

                $Result.ExitCodeDescription | Should -Be $RequiredMessage

                $ResultProxyFunction.ExitCodeDescription | Should -Be $RequiredMessage

            }


        }

        Set-Location -Path $LocationAtBegin

    }

}

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCcIKbd3rTMk1WJ
# r3/1xW91F+y9kKi6jvUJXOscgzKYQqCCFnYwggM4MIICIKADAgECAhBq68etXxgs
# l0IzUnGnriXYMA0GCSqGSIb3DQEBCwUAMDQxMjAwBgNVBAMMKUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjYwOC4zMC4yMTM5MB4XDTI2MDgzMTA0MjkyNFoX
# DTI3MDgzMTA0NDkyNFowNDEyMDAGA1UEAwwpQXV0aGVudGljb2RlIENvZGVTaWdu
# aW5nQ2VydCAyNjA4LjMwLjIxMzkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDdJxoL2uUcJvum1pKa1VHYOTI3J6OR1BT5eYATKlN3JKjyNnKX9J4xF+SU
# R2GH9rXl2BqGZxBiRJRUORzw8dRx64Lt+O4LRDoB9nLrIDB7BR792m+2rLa6LplB
# o899uNObHkf1sLe3H8VU82Cbet0jC8wuhdZtXPQ2Y+Z+W+1knLDEY80dnCXcO+5l
# Vdv/UralKO/Iugx/OTulLFmSPV6DbSpqILn/EiIB1xDUsJvuRc/M/JQDDnqY5zNK
# ebxmc686/4zx6Stsiowa/xN0cbuVEwbepBwVTRJFUafLXIo+KtRiylMcL1lEM/fT
# 5+9FHTjvlnrQtEuHj78KawkXQxIdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUXAahq4JHkDCDfcmaMghq01gw
# lSowDQYJKoZIhvcNAQELBQADggEBAJxnSVTvVOf6APMUdus7Op+YThqeLtKb3g5f
# BKGDvAfed6YX1EndJ7QwBYftzuf5zdEgMuUI8Ktlv7576G9TvdcPsUi4KQvOS+DF
# KjuUB+tYa6dk9Bqf00ZrwkERkBu7drtNnSxhCUKeEFIKs11glGtUhC5K0WVyN+8U
# GejJ0u5dh2MPhlXllMqCsYARGvtHQayvjbpNZBsqzNFWJJsmFjMhx+oEtaAw4weC
# jbvCCbGqawBHOx/oTro2ba7LmQkHcLmXQp/6eUyoYc+r7/QY8aBT9tHmCeDcus5x
# tNwKWLcjLhSLbXD7faZbk1Uh+200mSjDhPhvX9vL9IeBKak+OIkwggWNMIIEdaAD
# AgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0y
# MjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4Smn
# PVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6f
# qVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O
# 7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZ
# Vu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4F
# fYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLm
# qaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMre
# Sx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/ch
# srIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+U
# DCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xM
# dT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUb
# AgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFd
# ZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAO
# BgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0f
# BD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEM
# BQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLt
# pIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouy
# XtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jS
# TEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAc
# AgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2
# h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIEnKADAgECAhANx6xXBf8hmS5A
# QyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMT
# GERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcwMDAwMDBaFw0zODAx
# MTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51NrY0NlLWZloMsVO1DahGPNRcy
# bEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5bap+0lgloM2zX4kftn5B1IpYzT
# qpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf77S2uPoCj7GH8BLuxBG5AvftB
# dsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQSku2Ws3IfDReb6e3
# mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80FiocSk1VYLZlDwFt+cVFBURJg6z
# MUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+8y9oHRaQT/aofEnS
# 5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl92QOMeRxykvq6gbylsXQskBB
# BnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGPRdtBx3yGOP+rx3rKWDEJlIqL
# XvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//Wx+5kMqIMRvUBDx6z1ev+7ps
# NOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm1UUl9VnePs6BaaeE
# WvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM7Bu2ayBjUwIDAQABo4IBXTCC
# AVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU729TSunkBnx6yuKQVvYv
# 1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/
# BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBABfO+xaAHP4HPRF2cTC9vgvI
# tTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQM2qEJPe36zwbSI/m
# S83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt6vJy9lMDPjTLxLgX
# f9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr0UdqirZ7bowe9Vj2AIMD8liy
# rukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmSNq1UH410ANVko43+
# Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKqMVuqte69M9J6A47OvgRaPs+2
# ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiyfTPjLbnFRsjsYg39OlV8cipD
# oq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmMThi0vw9vODRzW6Ax
# nJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTjd6xpR6oaQf/DJbg3s6KCLPAl
# Z66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx9yHbxtl5TPau1j/1
# MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3/BAPvIXKUjPSxyZs
# q8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQCE/cM09+RU7bww+P+ZIYNTAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI2MDgwNTAwMDAwMFoXDTM3MTEw
# NDIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjYgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALZ7
# pvLJ/s1K+NSbTGWz/TjGMPh8CQ6RucZCLv5anHzWJjF/NWJrFIhy24fcpKXlgRik
# y4WAawDfU3YP0BMxt9l3Dm5oCG5Z69AqEN1kgHg2epx+l+lZBcmJCcN0ASURML5u
# FIS80sZsDwO3BSkUxDjLJhBI+qiZP3aixAC/qEGLjsBNlLol9VZ7pfGEXiMlneJI
# C5/YKuizVzNFKZZEeoy/0B8Zm+nzKBgSWG52lCO1w+nCg6XpCtklTJXeIg283hw7
# TmmsZXR+SMbjbrEOvZ3fP2VxIgeR28Y90ZStd3F9VuA5RVynb/whITPAo9b75Zr4
# Ta6Mj3URm26QZYMn/FnbuTegcoRcFEZ9FOqM5T6MTdtr/n74lIT/ug0eeOzmZ6QT
# Fg33otX+bFRsIolvykE1jive4PuESaT8zzVeFWDAMDtozNgLctkGD1ZjkEyZtJrL
# l5ya0m5doH/ScpaZCZVl6pNUOCybMc/kxC6EAmSJY24L0yYKD1Nkddsnb/ItVKi/
# 2nXpQNMu1PT5prW83vV8d67WowuUs0HdY4H8AMLGvdL/WHEj3ZnqMqAQQP9u3Ai9
# t+5eQ02GDwy0ODjdzi0xlp70W+ow63/0++YDEX1M0iwgUHwbrJvfpklkZQvw3+kv
# 3vUPItdwroczk9icflf55W1zOEKAcJVAIXpcMCU9AgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBQUyWOKMC7USvtulPPm40B+9ezN4jAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQCNxTphHp1SCt+ZrAmAfn0o
# QLFr0mLywSLaDXQIENoyKqxrFbJblzCVP/pkXmwXOdrOpWygLzlT12os5ipDCy35
# RBCg2UMeApEtrfGhz45F4Wt4WGdNdIbRWt3YTYJmpR+b7lr4d7Uwn+H600u4D7Rn
# OGf8Wj4UNgAdZkfHhHv1mx9EVh71SJelcEN/oORSjXzdjfw1iZH9d8Nh/thn6hH2
# 3d+VsPAr6GAYyzSA02nXD1nYLI7Ijmiv+xLCiYC41DSFYL3GhTiy0PxpawPtGRya
# BVGzq+UiTfM8pD7KVyF5aQyWP4KhVGUUTnmm/RlYJoW3TiXA/+t0YcT2oRVBm3JE
# TjajHug2AL+v5jhtKVnd3D0rbHXEu27o+Q8p4sEWPMqKDB+qbceb6T/6WcwTwXmQ
# 9lOCLLYcsQeSWmvKqzpAec9etE14jOQAzLKWdE3w/TCaKtLRaRT7LCkRYVnhA2D7
# 3FLje1O5b3HR5eHs0NzU/+xX7NbEdcofy0W3Wdwd1XOqtlpg/JgwtKfZM5dqO94l
# bUveOiJBI+xZEbGRsMNbXmMREUTgu+Oca7Y73MPWcslIx2VhkSKSXjDbD6rgg39H
# 5Mh7QfieAIjWagkJNt68Yfim6cjEzVSiLSeZfdkr5dtFPTW6jATlWJdYeeDRGCya
# tf8R1hSjzSvdN8yWQPT9gzGCBSQwggUgAgEBMEgwNDEyMDAGA1UEAwwpQXV0aGVu
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA4LjMwLjIxMzkCEGrrx61fGCyXQjNS
# caeuJdgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgH3jPTPnj0pxoLcbxj6/5+D1a5boE
# Ln6lRWXhYcH4u6wwDQYJKoZIhvcNAQEBBQAEggEAbO9/O9rEFO7OvrkLLwJ/SjPR
# 0nIlfaL+AKOtTq0Go9T/2H/EvgYUD7hDNtH6BxUQs8FPWTb2zdHaRrAjn7l6BenM
# R8BK+u6e5edRQ1WKGK8i2Nydf7Yi+HomDgaD5Qf9cOyOMGEfPhZXfLgOfASccfs6
# bZt7aNEqbPjicTNGP4zInfS7SBa/jEToXxzj9qFHfkWgTaJNDE+QSmsK/mDz19cK
# BN3u1FpYVm1CaUQwWzg9xWKrSCi1raSMoXYL0c7w1bk1layAUDrDhhRzLrhErzOA
# Ss1JTL4Q/LrqEdKcvloUQylMyjtcshp/6Z+JHo+F9eoDS/xc4JJAWYLeg7SpraGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAhP3DNP
# fkVO28MPj/mSGDUwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA5MTIwNDMwMzRaMC8GCSqGSIb3DQEJ
# BDEiBCBEh5LfAQ8v6cFnMmu9SSDmNKypba/X0xUOFe1Pbof6+DANBgkqhkiG9w0B
# AQEFAASCAgBOnOB8Hs9dihFk56opZGWiwnUYVMUuceNq5avgZP+T31y6t60/nf7T
# apQibYQ4XO+FpKTKKKZQI3I7rbTQ+opQRaFMtWSD6M6tbF+4+Qb4bs0i7xu3sBzc
# kUayoW1vZGL+tUGnkA88YqnT6oWCn5Jg0kumFFxfGtrJxp1mQD5LDwiinN+Feuwa
# JTlGTnMSlfh5I3eTfWbvjQVro30qAFvpRDPmfK+PQ7LSc/x3lpKi7h2AmyO3jEXx
# EdcvL1c3HL/Oy70CPHhKl2/W/3NTzI4lYcBorsW9/CsW2uCA4TYrwfWtMHPvz24D
# Q/HN8a5bm9ndVtWn4JVIKpKwSaTGoxm1b/VxCmV9VSL9UmaHsNnAc2n+TFTjMbyU
# 4lSKHi5ZBF14Y+XT0WnhXTfC5orh8tBzkNxUZ5dz123ROMFA0L8zCvOnh5W50wh+
# rsmkZqml56j6b9kiGaZuFvRC0RmPG2gTuzTr0+NTx0H5NGaXahR8olu0yqDKjZzX
# vpDlb6WQDokZfu6i3Bc0vgE7sNDZq3uQ/dTz+7cqsPPLqYWjK7nTYCkoPcKAkc05
# 0gEyxAgfW9mB8P9DasAfbgBxw/CSPFa/dGin0v/RE4lKo1bxDd1bRUujIhXEEljM
# pw9a6vwVta8AsvDzx5yo8nAhmgz/G/sPtMWBDcSxa/mLvDqfhe3H+g==
# SIG # End signature block
