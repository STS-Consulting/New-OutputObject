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
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCSX6WmqrreUZVO
# NUfqSsgCHUp5/K88eMPlJ9M+vtgEgKCCFnYwggM4MIICIKADAgECAhAXnbjlqWZv
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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgeztnHA705thbJlPm97tXrVtThxW0
# wYGWVHkQwkSUYyswDQYJKoZIhvcNAQEBBQAEggEA0BjHuVGzqLk/vFp8Dh3ipuWJ
# jPH7iYEXuIjDww6PXqfyF2dLER4UQAPDL/m+R8Tv/6zU/qgtaKNMy2blh0JWgyM5
# BnrMLY8BA2yc/+6qEo2KCCxRfCdRYirTfnWLOf3sXY1EFz6dygQ+Wrpvf0asYmHK
# CB9B5avlqKLLOpacgho0HXqsMwQJy7NvJcqMwp2wX10WQXN8h22s5t4hQP+Q2by9
# VhDO08DwYhWMG8in05eNrbaMnbbqSoocMrYNK/bS44HQR/Cj92YRdXuDHKCcGT1p
# PAJ65fDvCU9L5FR7wypArnZxGA+trQSY0eFyKt9BRnsVdoMOes91lljfgAf4ZaGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA1MzEwNjAxNDFaMC8GCSqGSIb3DQEJ
# BDEiBCB+BNwbbhHerdKVIFl32tdtkyLvSXPObgih6D7+YdlxkzANBgkqhkiG9w0B
# AQEFAASCAgBwx6vrcKdMmTTgBIa7NjFSNokQhUTgVD3LQpHVRfQhb2nM/JpkVRFr
# Mcir3ZvzsWqBdwqQxN+y8pmviDRGn+TB826s862N204TeQGDMSABMMOVffX1VWPu
# 0FfiCB4G2MT81FMNTT8k6psdLvhyfNhNYZPQEGJCixUvkCLOoSvsRuiY+yyedgfC
# h3fcfc+mO0ywBncXu70vUoS2dvXnwSj+oGe4zACd3sbqLmKMNLCNb+gaT8+QCHWX
# a0Mdkqgeofb+oZBG691rB15iomwfbwYz9rGtnT95m4ay2SDL2lcXZV5mzqDMMQfp
# K+Mg0HcI7ApRe50EeFQZOgjjYcMetvlTrV0PJoCZftW7ysn3SbxUYTMbtXqHzbyS
# QCOF9k+rJOQI80isN74Q+MEh0C3McHmpc31Tv9A79wtYNmE3fp75g7/w7ZM6vxFg
# 5B/U+oYe5PynpIWQJ3I1siCKxaqk5HEP7msvrEip8LKw23IW23/ytsI1nLUT0rZH
# EMSkbjg/HW+grgZUkeQX+4gjMiCIe+BRSKWan+Tkqvr8t6+66NzxCJddJUxSdmJK
# KU0X7b7M0fX3cEX/octdsTzi/6hG+6PHoMYjdQ+KDsiMOF2AuV7YQGjnBXmjLCq0
# gONKNyGcP6ByI4ziK5GmHMcppl+kaE4p86yWyaQHJUOLJV8Z49L2fQ==
# SIG # End signature block
