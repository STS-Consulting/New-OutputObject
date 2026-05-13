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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBVbtaxyQYf9ITw
# DYy1K2fDzreuHXFgZxUbVvXEfWmv4qCCFnYwggM4MIICIKADAgECAhAXnbjlqWZv
# uU+9AGMD/IcFMA0GCSqGSIb3DQEBCwUAMDQxMjAwBgNVBAMMKUF1dGhlbnRpY29k
# ZSBDb2RlU2lnbmluZ0NlcnQgMjYwNS4wNi4xMzI2MB4XDTI2MDUwNjIwMTYwNFoX
# DTI3MDUwNjIwMzYwNFowNDEyMDAGA1UEAwwpQXV0aGVudGljb2RlIENvZGVTaWdu
# aW5nQ2VydCAyNjA1LjA2LjEzMjYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDgmQPwmZ8pamXWV3OpU62nN4i0tWv+CBFIM7GzaPdaZe4vjp1a+oylSUQD
# 2lJUs9QdA5VZ1q4Jxq/pD2CFlTIS1ZTwdWkHHtxBXS+rI6InVSODffmXokV7tjw0
# dRlRi7PCLNmNQnr7IYp/ldJ8R0UvnMTEHgxg5OcIfqkN968kv4cyXOMgaSoLPp6m
# FgGOiD8CvJPyrptTh45OUhtIJuh6Rk2utfO5PcYrDDq7Ov7B5BmDVWvvJ3XyZEse
# 5c+GGVL+SWFO/+QDATanT8wUM+0v+t3qkuKc6jU9EwDi5etYUK69PfAeZWQBxXzH
# ZTf2EESlbXpwZvdvWqH1g8ebOj3xAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUGjEuXccQjyNJPpFvTGTa6Y1C
# LIcwDQYJKoZIhvcNAQELBQADggEBAJcEQMoDXuqpU+bNovJ52Weou2B5r9jYhh2R
# whY+2tOoVcK5TH1J6jFTydshZ8OuRLCVOV4dy4vgfHiGNKS7UzYphyu0uVYhkVH5
# t2rIaxtwFBi+QlkpxE6/akBrTmBYwuh0HDAdTzo7OjtjpKXjZKS1U8zRaSUXLiMK
# dTgZN6B5I1tLF3KdESndz3C2tZHZECuHKmTuhnibsXL3xLp3yJUL9ka+DZehpiJ2
# c8JkdiNEw4Dd2n5bKrVhRy/SqllvLmX4cmv4iSYDSVNSg8SrE8jER1jdhVa8DjW9
# wome0QT2RXNE2c67k+eUUGeJ3/gFuxnJMLAHrc7vHpa9qEVPxQIwggWNMIIEdaAD
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
# q8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkw
# MzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANBG
# rC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMyqJnfFNZx+wvA69HFTBdwbHwB
# SOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4QKpVD7dvNZh6wW2R6kSu9RJt/
# 4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8SOhPUWlLnh00Cll8pjrUcCV3
# K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtUDVHRXdmncOOMA3CoB/iUSROU
# INDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCvpSduSwhwUmotuQhcg9tw2YD3
# w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1Hf2JNMVL4Q1OpbybpMe46Yce
# NA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORVbPR1VVnDuSeHVZlc4seAO+6d
# 2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWnqWU3dCCyFG1roSrgHjSHlq8x
# ymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyTlaCCfw7aSUROwnu7zER6EaJ+
# AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0yZIXe+giAwW00aHzrDchIc2b
# Qhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mnAgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfzkXFjGVBDz2GM6DAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQBlKq3xHCcEua5gQezRCESe
# Y0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fNaNmFj6Eh8/YmRDfxT7C0k8FU
# FqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim8/9yJmZSe2F8AQ/UdKFOtj7Y
# MTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4daIqToXFE/JQ/EABgfZXLWU0zi
# TN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX8VBRKe1uNnzQVTeLni2nHkX/
# QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1d0IbX6Wq8/gVutDojBIFeRlq
# AcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQfVjnzrvwiCZ85EE8LUkqRhoS3
# Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ35XTxfUlQ+8Hggt8l2Yv7roan
# cJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3CrWqZzBt1R9xJgKf47CdxVRd/
# ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlKV9jEnstrniLvUxxVZE/rptb7
# IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk+EMF/cWuiC7POGT75qaL6vdC
# vHlshtjdNXOCIUjsarfNZzGCBSQwggUgAgEBMEgwNDEyMDAGA1UEAwwpQXV0aGVu
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA1LjA2LjEzMjYCEBeduOWpZm+5T70A
# YwP8hwUwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQghXkEADvMq9aRs9NH9ky8ZciBg5cz
# eFXsN3S+A8+vq2IwDQYJKoZIhvcNAQEBBQAEggEAPQbZcv1PFqn9bXL4oeEbvkt2
# yS8TAdDyC8ge2GCQMocPH1G9dznxhel9qdFhWpXU1sr6b0im9zThk0eR7ElR4AwM
# NhivP7N8zn/Tc/uER1MRLKSRYQaXzxMTITL2FZBGallaIsKYPLSzRsM+MhR3BwYi
# 6wPj87dnZc9tJDtsd42hpSizsTvjLhIJKsD1AJpI58XuGHDuVMVqi02UF3TIh1nJ
# d0SGtLNn4DStViOfl0dWUku6pETo+KhJyshSMf5ASiuhzr1G/FO3eXnQKKsU+14l
# 5mBy/3q3+cmNkJu3RSmPlriL81djIh3E8bQgMGIZPMxXcoEn7jdxjkBxI9RyeaGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA1MTMwMzAxNTNaMC8GCSqGSIb3DQEJ
# BDEiBCC93ZsIGfOmCLMlf3yw1oZg8eCBVmm9pVJaZ6xPaoUGbTANBgkqhkiG9w0B
# AQEFAASCAgA1jtVqcQcCXcashj5CcYjxTLKyzNn52QaYYEirhvXubPyZ+b7PhazF
# HXJPKLMXBgX63cXaCDu+B0rmCU0jkyWjMlzOkUS/SZFv8DN9I7E3Yp40v/Pqtb3N
# IgB2Ifq6mi1SodYz0g2QanBIyNxKPWK2FBXd2i/eWm1LIQzHPRcwHVfFvJaq2bJx
# avp1TPQa0AEnF6YnTA1qGrlkL9Uo0JUS0DSea+fHeTYtRyIbvpBly7COU9F3nd3c
# sGg2VYLhTjSoGJRUlhsMYTJJI6l75OTqgpU5wkrkWWPgKpFdo5DZrWyGO1iIL50D
# 44N4taLal6LBqZ/gKPld1bW8htJ3RrzCJ7kGV2+/qtqge7aRV1wOs3Iwg4MI1YHa
# Bll+CvsrEF/gjg/A4VrjkgN97LUVx8eso3g0AjHpRCG1WT8DHyB9xhiG59y6E/5y
# uKYd9JsYwBjH98XXYvxjlTM0kID960UIrXxgWaadxSfL/EE8GHY96TrUNMRGMjPo
# Ns4MDSDlI644F4hCV2SFnqYITYe9RvwIttwQv42JIG9K9lgzMJ/B2pwslupdb00J
# tZV4fBmh0VgI8GFGo5kIJzUTmW+5XF2DkfVgOKtfAXoGzSLWm1+LWyrJohTIx/sW
# tPYpidMFxCbH9k2KOFX2Tzianw4MlqPY+cnlFl+QvYEaViiSgmybrw==
# SIG # End signature block
