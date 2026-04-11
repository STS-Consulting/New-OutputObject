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
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBVbtaxyQYf9ITw
# DYy1K2fDzreuHXFgZxUbVvXEfWmv4qCCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
# iEa7joroOpM5MA0GCSqGSIb3DQEBCwUAMCwxKjAoBgNVBAMMIUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjUwNjAeFw0yNTA2MjQwNDE1MDJaFw0yNjA2MjQw
# NDM1MDJaMCwxKjAoBgNVBAMMIUF1dGhlbnRpY29kZSBDb2RlU2lnbmluZ0NlcnQg
# MjUwNjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANZc5uW9b35U8sm6
# K6q2uMsPC858n8/PQTYq/W+zJxNmG857R3Ul9j6+i8q+h13l1xokkn3ac5R9ZE9X
# 154ObTmBJ+Chpo/o/2fBR4fUJk8Vr6ayKo30CSH/CDOrEVbGaUCRd8Qn4/KlTLNs
# 2W+f3Yz8BUTJVWWyv0dwy/4M1Zd9bR821ZHLXxSHljLcMvGtM8Z3PCzGKYoc4rzy
# Srn/rq4dVhMiSoFlB5ap+1XjNtothuX6jsOapbMl7DnP5m408U19on9pa0P7pYq5
# 53MCcG+ey5iP1nov59owcgSys4hOcxEqtN+A+hfQk16mqT5d6ZR6D6h93tO5qNg7
# mU1+tAkCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMB0GA1UdDgQWBBS1bvdiW88c2QGbM+WPEf+fAEhZczANBgkqhkiG9w0BAQsF
# AAOCAQEAUnUKQWGJP+XnEoS9aCgi2ob7DogZUtpGHGvXGe9FmhkpoDb/VDEl/qQe
# QmQb3sYEBg+ZnVqocREbm72U+7Moq5L8tZZ2NOAfmcaWbAmd4jRdMlJzBNuXDnmP
# KWYsOaXFirU9i18/Ws2GL5MG6Xpff5WRo7MIJ5iKghIkGVi+l/Io/5mBzpkSyrrO
# hYpbMY8OV6TXc4jqEut4nvmB4jrJAzpmVpFuyw0ERxwp0jUFoK95w2ftrYaDmPuP
# 1BREeZ8GjSIk+kw6jHy0CzlK9w/HTOTxgt2CdzHZKEwddUf91dHwC5GvdPjuy1VX
# +Z6HHKm8nqHZPR6ejw6j9ohfyIBHSzCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ
# 4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMb
# RGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMx
# MTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQg
# VHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# v+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/Mb
# pDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlq
# czKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxb
# Grzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcva
# k17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sE
# cypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ck
# XEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA
# 5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFj
# GESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+
# Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotP
# wtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5
# BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# MBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhf
# oKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv
# 9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZ
# y51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTV
# Peix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGy
# WfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3Aamf
# V6peKOK5lDCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYwDQYJKoZIhvcN
# AQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3Rl
# ZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1OVowaTELMAkG
# A1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdp
# Q2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1
# IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4MdMKmEFyvjxG
# wBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6c+Gh/qm8Xi4a
# PCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3SYDEAd4dg2dD
# GpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVSTEG8yAR2CQWIM
# 1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpqumzTCNSOxm+S
# AWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJyUXzdtFUUt4a
# S4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/GcalNeJQ55IuwnKC
# gs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8Aw4wJkhU1JrPs
# FfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/nJ0+k6Mvqzfpz
# PDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA6tQbZl1KhBtT
# asySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2baoD6x0VR4RjSp
# WM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAG
# AQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAfBgNVHSMEGDAW
# gBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRS
# b290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkq
# hkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCHxYgaMH9Pw5tc
# BnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdhOP4hCFATuNT+
# ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDCvwzJv2sRUoKE
# fJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B0ba2H3LUiwDR
# AXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWGNqNX+DF0SQzH
# U0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRNivYuve3L2oiK
# NqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02OoXN4bFzK0vlNM
# svhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy4kbu4QFhOm0x
# JuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2wL40mm53+/j7t
# FaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQtyRN62JK4S1C8
# uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2zNaQ9k+5t1ww
# ggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHanlXRoMA0GCSqGSIb3DQEBCwUAMGkx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYg
# MjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcNMzYwOTAzMjM1OTU5WjBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNwb25kZXIgMjAyNSAxMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0EasLRLGntDqrmBWsytXum9R
# /4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVMF3BsfAFI54um8+dnxk36+jx0Tb+k
# +87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqRK71Em3/hCGC5KyyneqiZ7syvFXJ9
# A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXymOtRwJXcrcTTPPT2V1D/+cFllESvi
# H8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH+JRJE5Qg0NP3yiSyi5MxgU6cehGH
# r7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD23DZgPfDrJJJK77epTwMP6eKA0kW
# a3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJukx7jphx40DQt82yepyekl4i0r8OEp
# s/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzix4A77p3awLbr89A90/nWGjXMGn7F
# QhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAeNIeWrzHKYueMJtItnj2Q+aTyLLKL
# M0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vMRHoRon4CWIvuiNN1Lk9Y+xZ66laz
# s2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOsNyEhzZtCGmnQigpFHti58CSmvEyJ
# cAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGRMAwGA1UdEwEB/wQCMAAwHQYDVR0O
# BBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8GA1UdIwQYMBaAFO9vU0rp5AZ8esri
# kFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIw
# MjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYy
# MDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJ
# KoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB7NEIRJ5jQHIh+OT2Ik/bNYulCrVv
# hREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FPsLSTwVQWo2H62yGBvg7ouCODwrx6
# ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0oU62PtgxOao872bOySCILdBghQ/Z
# LcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9lctZTTOJM3pHfKBAEcxQFoHlt2s9s
# XoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ueLaceRf9Cq9ec1v5iQMWTFQa0xNqI
# tH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiMEgV5GWoBy4RVPRwqxv7Mk0Sy4QHs
# 7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtSSpGGhLdjnQ4eBpjtP+XB3pQCtv4E
# 5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZi/uuhqdwkgVxuiMFzGVFwYbQsiGn
# oa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/jsJ3FVF3+d1SVDTmjFjLbNFZUWMXuZ
# yvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVkT+um1vshETaWyQo8gmBto/m3acaP
# 9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvmpovq90K8eWyG2N01c4IhSOxqt81n
# MYIFHDCCBRgCAQEwQDAsMSowKAYDVQQDDCFBdXRoZW50aWNvZGUgQ29kZVNpZ25p
# bmdDZXJ0IDI1MDYCEFIOb6JgEauIRruOiug6kzkwDQYJYIZIAWUDBAIBBQCggYQw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQx
# IgQghXkEADvMq9aRs9NH9ky8ZciBg5czeFXsN3S+A8+vq2IwDQYJKoZIhvcNAQEB
# BQAEggEAbHJzkV/Ltzrao3wCtXVRv8f6xMcbC/kkAOY/FvjOdW2/q5+sQCR7uc+v
# 4LzK++6v6DDY9s0/0iaVVkuP/tSvnESj6UsnlBHCZrkPCDfZM4/Xa9raCa/dpfcD
# SjotcVPKXV1vkbiizpxlo5ksuSXTz6xhnORrZdYKofjfhQjbORNCml4ep6Pbdf6B
# 92dv+rgm5F4WsFBiWGZf7CxgeFd4daWqotnWzwUtIkZnaKCKjgtePW4qYT1wuF/+
# hMQz8ozRq2FL3QAxUW+/F33ziGW2HRmHlb2Q7blczWZ7kNdf3ORxZipaokxgkfyD
# f+FznuxVE3/JgzA0y2KvAg+pmp5VjaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjA0MTEwNjE5MDRaMC8GCSqGSIb3DQEJBDEiBCCOhKFATvN4N7S6lbXIIySvQ9JP
# jrVS67oDB9RJBLy/oDANBgkqhkiG9w0BAQEFAASCAgAKSiYer5W+408dw5aAntku
# EJjY0ujFlQdzPBtSs8eehsY7RwHxIZTw42dNDHICYnGNpRZvU4iy917dzelGIjvK
# eawzy71vl+aSyYrLpz46V9xybXf1eG0fMXOoTvitmIHTwg5PRuTk822cVK0UT5W+
# jD/hKGanILe02YX2cfHlkv10Hcr7qLsIJ6E+fKRvX+OoCmoBDxLEHj84acOikpwC
# A3M6hpfFZp3mzgoYugquYTm2mesw2ZbBQSjhQWYIvk+WVdokLhr/QXxVjHCaqnCV
# +UmX/RMSGlotqjvsTOWjr33ny22ydzJPSNKOMOjvbg7n5sIDU6nyZWMYqy6FMikL
# 47HRP09bmKl92Y4U3HCW+XrqZDnnRuhNujxvmL2hAb78gBWganv2aKX7W7nolsga
# D+9zRJTWRZhtOwaGkDA/mTzG57fc0UoMwPrR3qXGU6TGKFgpHIJyOWWe5XmMbGJB
# GGHogzvyLUx616XsgVDIp8Lj4K8gzSrTURqH0Ymip2aM95yEDpNCq4ECo5HH9lLy
# LzVJp1/2XTLzx1sQLsZRZa63zpAXonObWq0AdRhW5VXoINvYHbsqTV8aHDOf8N6s
# XVLNvVjuj+9tbBgWFPhmQ1G/q4xY7ts7wXKfaGYnOBdfSgSqkE4PiPjAfLy5ep1g
# 8wnhysdr7MEeC3lBEu9bpg==
# SIG # End signature block
