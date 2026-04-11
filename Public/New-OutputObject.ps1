function New-OutputObject {
    <#

    .SYNOPSIS
    Function intended for preparing a PowerShell object for output files like reports or logs.

    .DESCRIPTION
    Function intended for preparing a PowerShell custom object what contains e.g. file name for output/create files like reports or log.
    The name is prepared based on prefix, middle name part, suffix, date, etc. with verification if provided path exist and is it writable.

    Returned object contains properties
    - OutputObjectPath - to use it please check examples - as a [System.IO.FileInfo]
    - ExitCode
    - ExitCodeDescription

    Exit codes and descriptions
    - 0 = "Everything is fine :-)"
    - 1 = "Provided parent path <PATH> doesn't exist"
    - 2 = "The name not created due to unaccepatable chars"
    - 3 = "Provided patch <PATH> is not writable"
    - 4 = "The file\folder <PATH>\\<FILE_OR_FOLDER_NAME> already exist  - can be overwritten"
    - 5 = "The file\folder <PATH>\\<FILE_OR_FOLDER_NAME> already exist  - can't be overwritten"

    .PARAMETER ObjectType
    Type of object to prepare - file or folder

    .PARAMETER ParentPath
    The folder path what will be used as the parent path for the new created object.
    When non existing path will be provided the error code will be returned.

    By default output files are stored in the current path.

    .PARAMETER OutputObjectNamePrefix
    Prefix used for creating output files name

    .PARAMETER OutputObjectNameStem
    Part of the name which will be used in midle of output file name

    .PARAMETER OutputObjectNameSuffix
    Part of the name which will be used at the end of output file name

    .PARAMETER IncludeDateTimePartInOutputObjectName
    Set to TRUE if report file name should contains part based on date and time - format yyyyMMdd-HHmm is used

    .PARAMETER DateTimePartInOutputObjectName
    Set to date and time which should be used in output file name, by default current date and time is used

    .PARAMETER DateTimePartFormat
    Format string used to format date and time in output object name.

    .PARAMETER OutputFileNameExtension
    Set to extension which need to be used for output file, by default ".txt" is used

    .PARAMETER NamePartsSeparator
    A char used to separate parts in the name, by default "-" is used

    .PARAMETER BreakIfError
    Break function execution if parameters provided for output file creation are not correct or destination file path is not writables

    .PARAMETER Force
    If used the function Doesn't ask for an overwrite decission, assumes that the file can be overwritten

    .EXAMPLE
    (Get-Item env:COMPUTERNAME).Value

    WXDX75

    PS > $FileNeeded = @{

        ParentPath = 'C:\USERS\UserName\';
        OutputObjectNamePrefix = 'Messages';
        OutputObjectNameStem = (Get-Item env:COMPUTERNAME).Value;
        IncludeDateTimePartInOutputObjectName = $true;
        IncludeDateTimePartInOutputObjectName = $true;

        BreakIfError = $true
    }

    PS > $PerServerReportFileMessages = New-OutputFile @FileNeeded


    PS > $PerServerReportFileMessages | Format-List


    OutputObjectPath      : C:\users\UserName\Messages-WXDX75-20151021-001205.txt
    ExitCode            : 0
    ExitCodeDescription : Everything is fine :-)

    PS > New-Item -Path $PerServerReportFileMessages.OutputObjectPath -ItemType file

    Directory: C:\USERS\UserName

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       21/10/2015     00:12              0 Messages-WXDX75-20151021-001205.txt

    The file created on provided parameters.
    Under preparation the file name is created, provided part of names are used, and availability of name (if the file exist now) is checked.

    .EXAMPLE
    $FileNeeded = @{

    ParentPath = 'C:\USERS\UserName\';
        OutputObjectNamePrefix = 'Messages';
        OutputObjectNameStem = 'COMPUTERNAME';
        IncludeDateTimePartInOutputObjectName = $false;
        OutputFileNameExtension = "csv";
        OutputObjectNameSuffix = "failed"
    }

    PS > $PerServerReportFileMessages = New-OutputFile @FileNeeded


    PS > $PerServerReportFileMessages.OutputObjectPath | Select-Object -Property Name,Extension,Directory | Format-List

    Name      : Messages-COMPUTERNAME-failed.csv
    Extension : .csv
    Directory : C:\USERS\UserName



    PS > ($PerServerReportFileMessages.OutputObjectPath).gettype()

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     FileInfo                                 System.IO.FileSystemInfo

    PS > Test-Path ($PerServerReportFileMessages.OutputObjectPath)

    False

    The funciton return object what contain the property named OutputObjectPath what is the object of type System.IO.FileSystemInfo.

    File is not created. Only the object in the memory is prepared.

    .OUTPUTS
    System.Object[]

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, File, Folder, FileSystem

    CURRENT VERSION
    - 0.9.8 - 2017-05-06

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

    LICENSE
    Copyright (c) 2016 Wojciech Sciesinski
    This function is licensed under The MIT License (MIT)
    Full license text: https://opensource.org/licenses/MIT

    #>

    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([System.Object[]])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('File', 'Folder')]
        [Alias('ItemType')]
        [String]$ObjectType,
        [parameter(Mandatory = $false)]
        [String]$ParentPath = '.',
        [parameter(Mandatory = $false)]
        [String]$OutputObjectNamePrefix = 'Output',
        [parameter(Mandatory = $false)]
        [String]$OutputObjectNameStem = $null,
        [parameter(Mandatory = $false)]
        [String]$OutputObjectNameSuffix = $null,
        [parameter(Mandatory = $false)]
        [Bool]$IncludeDateTimePartInOutputObjectName = $true,
        [parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DateTimePartInOutputObjectName = $null,
        [parameter(Mandatory = $false)]
        [String]$DateTimePartFormat,
        [parameter(Mandatory = $false)]
        [String]$OutputFileNameExtension,
        [parameter(Mandatory = $false)]
        [alias('Separator')]
        [String]$NamePartsSeparator = '-',
        [parameter(Mandatory = $false)]
        [Switch]$BreakIfError,
        [parameter(Mandatory = $false)]
        [Switch]$Force
    )

    #Declare variable

    [Int]$ExitCode = 0

    $ExitCodesDescriptions = @{ 0 = 'Everything is fine :-)'
        1                         = "Provided parent path {0} doesn't exist"; # $ParentPath
        2                         = 'The name not created due to unaccepatable chars'
        3                         = 'Provided path {0} is not writable'; # $ParentPath
        4                         = 'The {0} {1} already exist - can be overwritten' # $ItemTypeLowerCase, $OutputObjectPath.FullName
        5                         = "The {0} {1} already exist - can't be overwritten" # $ItemTypeLowerCase, $OutputObjectPath
        6                         = 'The {0} {1} already exist - can be overwritten due to used the Force switch' # $ItemTypeLowerCase, $OutputObjectPath
    }

    [String]$ExitCodeDescription = 'Everything is fine :-)'

    $FinalNameParts = [ordered]@{NamePrefix = $OutputObjectNamePrefix
        NameStem                            = $OutputObjectNameStem
        NameSuffix                          = $OutputObjectNameSuffix
        DateTimePartInName                  = ''
        FileNameExtension                   = ''
    }

    $Result = New-Object -TypeName PSObject

    if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and ($ISLinux -or $IsMacOS)) {

        $PathSeparator = '/'

    } else {

        $PathSeparator = '\'

    }

    if ($ObjectType -eq 'File') {

        $PathType = 'Leaf'

        $ItemTypeLowerCase = 'file'

        $SkipInFinalName = @()

        if ([String]::IsNullOrEmpty($DateTimePartFormat)) {

            $DateTimePartFormat = 'yyyyMMdd-HHmmss'

        } else {

            $TestCharsResult = Test-CharsInPath -Path $DateTimePartFormat -SkipCheckCharsInFolderPart -SkipDividingForParts

            if ( $TestCharsResult -eq 3) {

                if ( $BreakIfError.IsPresent ) {

                    $MessageText = 'Provided value for DateTimePartFormat contains char what is not allowed in a file name.'

                    throw $MessageText

                } else {

                    [Int]$ExitCode = 2

                    [String]$ExitCodeDescription = $ExitCodesDescriptions[$ExitCode]

                }

            }

        }

        if ( [String]::IsNullOrEmpty($OutputFileNameExtension)) {

            $OutputFileNameExtension = '.txt'

            $FinalNameParts['FileNameExtension'] = '.txt'

        } else {

            $FinalNameParts['FileNameExtension'] = '.{0}' -f $OutputFileNameExtension

        }

    } else {

        $PathType = 'Container'

        $ItemTypeLowerCase = 'folder'

        $SkipInFinalName = @('FileNameExtension')

        if ([String]::IsNullOrEmpty($DateTimePartFormat)) {

            $DateTimePartFormat = 'yyyyMMdd'

        } else {

            $TestCharsResult = Test-CharsInPath -Path $DateTimePartFormat -SkipCheckCharsInFileNamePart -SkipDividingForParts

            if ( $DateTimePartFormat.Contains($PathSeparator) ) {

                $TestCharsResult = 5

            }

            if ( $TestCharsResult -eq 2 ) {

                if ( $BreakIfError.IsPresent ) {

                    $MessageText = 'Provided value for DateTimePartFormat contains char what is not allowed in a folder name.'

                    throw $MessageText

                } else {

                    [Int]$ExitCode = 2

                    [String]$ExitCodeDescription = $ExitCodesDescriptions[$ExitCode]

                }

            } elseif ( $TestCharsResult -eq 5 ) {

                if ( $BreakIfError.IsPresent ) {

                    $MessageText = 'Provided value for DateTimePartFormat contains a char what is a path separator char.'

                    throw $MessageText

                } else {

                    [Int]$ExitCode = 2

                    [String]$ExitCodeDescription = $ExitCodesDescriptions[$ExitCode]

                }

            }

        }

        if (-not [String]::IsNullOrEmpty($OutputFileNameExtension)) {

            [String]$MessageText = 'The value assigned to the parameter OutputFileNameExtension for a folder OutputType is ignored.'

            Write-Warning -Message $MessageText

        }

    }

    #Convert relative path to absolute path
    [String]$ParentPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ParentPath)

    #Assign value to the variable $IncludeDateTimePartInOutputObjectName if is not initialized
    if ($IncludeDateTimePartInOutputObjectName -and ($null -eq $DateTimePartInOutputObjectName)) {

        [String]$DateTimePartInObjectNameString = $(Get-Date -Format $DateTimePartFormat)

        $FinalNameParts['DateTimePartInName'] = $DateTimePartInObjectNameString

    } elseif ($IncludeDateTimePartInOutputObjectName) {

        [String]$DateTimePartInObjectNameString = $(Get-Date -Date $DateTimePartInOutputObjectName -Format $DateTimePartFormat)

        $FinalNameParts['DateTimePartInName'] = $DateTimePartInObjectNameString

    }

    #Check if Output directory exist
    if (-not (Test-Path -Path $ParentPath -PathType Container)) {

        [Int]$ExitCode = 1

        [String]$MessageText = $ExitCodesDescriptions[$ExitCode] -f $ParentPath

        [String]$ExitCodeDescription = $MessageText

    }

    #Try if Output directory is writable - a temporary object is created for that
    if ($Force -or $PSCmdlet.ShouldProcess($ParentPath, 'Verify writability by creating temp file')) {
        #Try if Output directory is writable - a temporary file is created for that
        try {

            [String]$TempObjectName = [System.IO.Path]::GetRandomFileName() -replace '.*\\', ''

            [String]$TempObjectPath = Join-Path -Path $ParentPath -ChildPath $TempObjectName

            New-Item -Path $TempObjectPath -type File -ErrorAction Stop | Out-Null

        } catch {

            [Int]$ExitCode = 3

            [String]$MessageText = $ExitCodesDescriptions[$ExitCode] -f $ParentPath

            if ($BreakIfError.IsPresent) {

                throw $MessageText

            } else {

                [String]$ExitCodeDescription = $MessageText

            }

        }

        Remove-Item -Path $TempObjectPath -ErrorAction SilentlyContinue | Out-Null
    }

    $PartsToJoin = @("$ParentPath$PathSeparator")

    foreach ( $NamePart in $FinalNameParts.Keys) {

        if ( $SkipInFinalName -notcontains $NamePart -and (-not [String]::IsNullOrEmpty( $FinalNameParts[$NamePart]))) {

            $PartsToJoin += $FinalNameParts[$NamePart]

        }

    }

    [String]$FinalName = [string]::Join("$NamePartsSeparator", $PartsToJoin)

    $SequencesToReplace = @{'//'                 = '/'
        '\\'                                     = '\'
        '..'                                     = '.'
        "$NamePartsSeparator."                   = '.'
        "$NamePartsSeparator$NamePartsSeparator" = $NamePartsSeparator
        "$PathSeparator$NamePartsSeparator"      = $PathSeparator
    }

    foreach ( $SequenceKey in $SequencesToReplace.keys ) {

        $FinalName = '{0}{1}' -f $FinalName.Substring(0, 2), (($FinalName.substring(2, $FinalName.length - 2)).Replace($SequenceKey, $SequencesToReplace[$SequenceKey]))

    }

    if ( $ExitCode -eq 2 ) {

        if ($ObjectType -eq 'File') {

            [System.IO.FileInfo]$OutputObjectPath = $null

        } else {

            [System.IO.DirectoryInfo]$OutputObjectPath = $null

        }

    } else {

        if ($ObjectType -eq 'File') {

            [System.IO.FileInfo]$OutputObjectPath = $FinalName

        } else {

            [System.IO.DirectoryInfo]$OutputObjectPath = $FinalName

        }

        if (Test-Path -Path $OutputObjectPath -PathType $PathType) {

            if ( -not $Force.IsPresent) {

                $Answer = Get-OverwriteDecision -Path $OutputObjectPath -ItemType $ObjectType

                switch ($Answer) {

                    0 {

                        [Int]$ExitCode = 4

                        [String]$MessageText = $ExitCodesDescriptions[$ExitCode] -f $ItemTypeLowerCase, $OutputObjectPath.FullName

                        [String]$ExitCodeDescription = $MessageText

                    }

                    1 {

                        [Int]$ExitCode = 5

                        [String]$MessageText = $ExitCodesDescriptions[$ExitCode] -f $ItemTypeLowerCase, $OutputObjectPath

                        [String]$ExitCodeDescription = $MessageText

                    }

                    2 {

                        [String]$MessageText = 'The {0} {1} already exist  - operation canceled by user' -f $ItemTypeLowerCase, $OutputObjectPath

                        throw $MessageText

                    }

                }

            } else {

                [Int]$ExitCode = 6

                [String]$MessageText = $ExitCodesDescriptions[$ExitCode] -f $ItemTypeLowerCase, $OutputObjectPath

                [String]$ExitCodeDescription = $MessageText

            }

        }

    }

    $Result | Add-Member -MemberType NoteProperty -Name OutputObjectPath -Value $OutputObjectPath

    #$Result | Add-Member -MemberType AliasProperty -Name Path -Value OutputObjectPath

    if ($ObjectType -eq 'File') {

        $Result | Add-Member -MemberType AliasProperty -Name OutputFilePath -Value OutputObjectPath

    } else {

        $Result | Add-Member -MemberType AliasProperty -Name OutputFolderPath -Value OutputObjectPath

    }

    $Result | Add-Member -MemberType NoteProperty -Name ExitCode -Value $ExitCode

    $Result | Add-Member -MemberType NoteProperty -Name ExitCodeDescription -Value $ExitCodeDescription

    return $Result

}

# SIG # Begin signature block
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCSX6WmqrreUZVO
# NUfqSsgCHUp5/K88eMPlJ9M+vtgEgKCCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
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
# IgQgeztnHA705thbJlPm97tXrVtThxW0wYGWVHkQwkSUYyswDQYJKoZIhvcNAQEB
# BQAEggEAtXAN5di7Skalb/yqfaUfphWRRqFACMQXlu78AVrzm1WD4xkEUeB9lBjB
# KUPj5kvtcitD8Eje+lgaurV4nqB/czW8Fi5lPr13Kcs2knPRbwINKYVF7gvflg4u
# iwuztHjThtEZAScpbYx3zRvhRbzv8QAo4j2462sILDne1qMYg4M+vzOJM4nP6pNA
# 3Uto/0A0LctYRGpzI/Spb0vD1p78hYqP1zGIZyhLdYI4txqsHwQ8YBTXsnyzXdN1
# OuF0m/dU9S4nC4DHPpNAkyi+mEvIStahxgGzJzuMKJN8BkUsMimgxkSEGHAtxfsK
# fS7wediF6+t/2YTLCGEJzkD/X1Krv6GCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjA0MTEwNjE5MDNaMC8GCSqGSIb3DQEJBDEiBCAqi28mmqUPRdrYbDqGQBdLTVuQ
# oWRa+NRLaulo8GYoiTANBgkqhkiG9w0BAQEFAASCAgBFhCKaltL/2LrGWoiV0+yO
# l46dHvdO7RkWPlt/DptVCxKOrnIpHb8jyy3ZV62r+oMnzbpLaTIPCnpsAHI14SAD
# +tmuUD5LRCambL5HJnMzL+2uszm2lSwB0n7zpAzPqf6y4J8W4fSkfz9Xw4j/hU4v
# 8l0ilwQnhdQe4VuUuIfZ3E7zGTXiBmLw8ZrTebi7QbFKqwn8xrp6MBWt4muJ7eNv
# CIovuN/VZGHqhimbSf1lLZeUyY1SwO7hRPPd7xsP+Lk9fLuJmwjfPNVQr65g69Zd
# P11UEzp+AwHGYVXkTuOD50rpvD5+EL2yYl4gDObbfM4o4ygblScQckfCQjuHzN/O
# +d6Ke27sCeCeRKuWmk0dEZ5aB/3czavr61BrtVPBGsb2BaOdImYcD/jGAz59PhKc
# SyIrhygjsd9SxHugoWCDSnxS4JVOOdS3evR4C+qf5Df2xNnTa4eB2WrFwnS6vvXN
# 6R4TIP/4NdSdTmimBmNPLHWpqUtzI5/R+9rSo/wl5Ns2siu4kc3jjY9Dfw4M1JLJ
# 7HOmD1qNfmuFhnNi8BoeI26wF4uDuITdJwR42seEGL47VL3ob6E1UL5EVitspY42
# Qc89d5fsjGwu5OFQIRPsPDyHUJ6HoUqP2AiFhk9bfj3UGewU8kzOICraOYZNVAhG
# ccPUEvgHRR7e64iarr95Ag==
# SIG # End signature block
