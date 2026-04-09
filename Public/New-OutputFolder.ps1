function New-OutputFolder {
    <#
    .SYNOPSIS
    Function intended for preparing a PowerShell object for output/create folders for e.g. eports or logs.

    .DESCRIPTION
    Function intended for preparing a PowerShell custom object what contains e.g. folder name for output/create folders.
    The name is prepared based on prefix, middle name part, suffix, date, etc. with verification if provided path exist and is it writable.

    Returned object contains properties
    - ParentPath - to use it please check an examples - as a [System.IO.DirectoryInfo]
    - ExitCode
    - ExitCodeDescription

    Exit codes and descriptions
    - 0 = "Everything is fine :-)"
    - 1 = "Provided parent path <PATH> doesn't exist"
    - 2 = "The result name contains unacceptable chars"
    - 3 = "Provided patch <PATH> is not writable"
    - 4 = "The folder <PATH>\<FOLDER_NAME> already exist  - can be overwritten"
    - 5 = "The folder <PATH>\<FOLDER_NAME> already exist  - can't be overwritten"

    .PARAMETER ParentPath
    The folder path what will be used as the parent path for the new created object.
    When non existing path will be provided the error code will be returned.

    By default output files are stored in the current path.

    .PARAMETER OutputFolderNamePrefix
    Prefix used for creating output folders name

    .PARAMETER OutputFolderNameStem
    Part of the name which will be used in midle of output folder name

    .PARAMETER OutputFolderNameSuffix
    Part of the name which will be used at the end of output folder name

    .PARAMETER IncludeDateTimePartInOutputFolderName
    Set to TRUE if report folder name should contains part based on date and time - format yyyyMMdd is used

    .PARAMETER DateTimePartInOutputFolderName
    Set to date and time which should be used in output folder name, by default current date and time is used

    .PARAMETER DateTimePartFormat
    Format string used to format date and time in output folder name.

    .PARAMETER NamePartsSeparator
    A char used to separate parts in the name, by default "-" is used

    .PARAMETER BreakIfError
    Break function execution if parameters provided for output folder creation are not correct or destination folder path is not writables

    .PARAMETER Force
    If used the function Doesn't ask for an overwrite decission, assumes that the file can be overwritten

    .EXAMPLE
    (Get-Item env:COMPUTERNAME).Value

    WXDX75

    PS > $FolderNeeded= @{
        ParentPath = 'C:\USERS\UserName\';
        OutputFolderNamePrefix = 'Messages';
        OutputFolderNameStem = (Get-Item env:COMPUTERNAME).Value
        IncludeDateTimePartInOutputFolderName = $false;
        BreakIfError = $true
    }

    PS > $PerServerReportFolderMessages = New-OutputFolder @FolderNeeded

    PS > $PerServerReportFolderMessages | Format-List

    OutputFilePath      : C:\users\UserName\Messages-WXDX75
    ExitCode            : 0
    ExitCodeDescription : Everything is fine :-)

    PS > New-Item -Path $PerServerReportFolderMessages.OutputFolderPath -ItemType Directory

    Directory: C:\USERS\UserName

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       21/10/2015     00:12              0 Messages-WXDX75

    The file created on provided parameters.
    Under preparation the file name is created, provided part of names are used, and availability of name (if the file exist now) is checked.

    .EXAMPLE
    $FolderNeeded= @{

    ParentPath = 'C:\USERS\UserName\';
        OutputFolderNamePrefix = 'Messages';
        OutputFolderNameStem = 'COMPUTERNAME';
        OutputFolderNameSuffix = "failed"
    }

    PS > $PerServerReportFolderMessages = New-OutputFolder @FolderNeeded

    PS > $PerServerReportFolderMessages.OutputFolderPath | Select-Object -Property Name,Parent,exists | Format-List

    Name   : Messages-COMPUTERNAME-20161112-failed
    Parent : UserName
    Exists : False

    PS > ($PerServerReportFolderMessages.OutputFolderPath).gettype()

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     DirectoryInfo                            System.IO.FileSystemInfo

    PS > Test-Path ($PerServerReportFolderMessages.OutputFilePath)
    False

    The function return object what contain the property named OutputFilePath what is the object of type [System.IO.DirectoryInfo].

    Folder is not created.
    Only the object in the memory is prepared.

    .OUTPUTS
    System.Object[]

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, Folder, FileSystem

    CURRENT VERSION
    - 0.9.8 - 2017-05-06

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

    LICENSE
    Copyright (c) 2016 Wojciech Sciesinski
    This function is licensed under The MIT License (MIT)
    Full license text: https://opensource.org/licenses/MIT
#>

    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([System.Object[]])]
    param (
        [parameter(Mandatory = $false)]
        [String]$ParentPath = '.',
        [parameter(Mandatory = $false)]
        [String]$OutputFolderNamePrefix = 'Output',
        [parameter(Mandatory = $false)]
        [String]$OutputFolderNameStem = $null,
        [parameter(Mandatory = $false)]
        [String]$OutputFolderNameSuffix = $null,
        [parameter(Mandatory = $false)]
        [Bool]$IncludeDateTimePartInOutputFolderName = $true,
        [parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DateTimePartInOutputFolderName = $null,
        [Parameter(Mandatory = $false)]
        [String]$DateTimePartFormat = 'yyyyMMdd',
        [parameter(Mandatory = $false)]
        [alias('Separator')]
        [String]$NamePartsSeparator = '-',
        [parameter(Mandatory = $false)]
        [Switch]$BreakIfError,
        [parameter(Mandatory = $false)]
        [Switch]$Force
    )

    $params = @{

        ObjectType                            = 'Folder'

        ParentPath                            = $ParentPath

        OutputObjectNamePrefix                = $OutputFolderNamePrefix

        OutputObjectNameStem                  = $OutputFolderNameStem

        OutputObjectNameSuffix                = $OutputFolderNameSuffix

        IncludeDateTimePartInOutputObjectName = $IncludeDateTimePartInOutputFolderName

        DateTimePartInOutputObjectName        = $DateTimePartInOutputFolderName

        DateTimePartFormat                    = $DateTimePartFormat

        NamePartsSeparator                    = $NamePartsSeparator

        BreakIfError                          = $BreakIfError

        Force                                 = $Force

    }

    $Result = New-OutputObject @params

    return $Result
}

# SIG # Begin signature block
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBUHzND1NOEI1u9
# 1yiRGeIya1grla9nqa/wUeX882mHIKCCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
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
# IgQgYLsUVGWR0wULVyELMR+c4+l8xdU4R9G0A+KE8/L+qhkwDQYJKoZIhvcNAQEB
# BQAEggEABnwO7feUKm79ieQGMGGBk82p41SueouWtFJh6Q2LqI6k5a6ZEq36RHCI
# MwY3tnFNyf3nsocmzDdT2yvL76WxhNDtFD17Mog/xsy6oLCWtetzxecFisyHTsbf
# ZlJ+OYe7yXD44kMl/smfWScdWUk33ODvsKZ2YNizxVOiTg4nYnGJfD0xNwci9nhw
# ULVHFagwVbZtetMAoRj+IbdZrCIh91fMSO3YcbvjNxUpvLl1oCxMzWTsfd41zPtB
# ySUzyJaynWJXPSm/ZY31jXJwXvqodvNitIjczD0REw/BgtA6s8hrpR6f/luYNQJ4
# o/3t2SPmWf++X2D6D19t70wtEIUYvaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjA0MDkwMjExNDFaMC8GCSqGSIb3DQEJBDEiBCA/WnFUsRh3s5fo6ivtmRC21aJX
# q6Qa42CCVw35MjXJUDANBgkqhkiG9w0BAQEFAASCAgCbInbnG58r7Nai9980FFk7
# QgI2psjFzhjnDGCsckm1FEUkYWaNsrd8sa7qLh896v2lMsvXuXwP8fZ45X4LXf9P
# U0mUV0sfYII70J0ydGnQxcga1vYc7jEuu4xOSLUtnCx8FUImYUCrrbgdZOZv0nDv
# CBAZ0zKOYaHKMypi3zfXGbQwLyV2ihkCsOPrUm4Z4baWIouIApD7ez8Zk0alMelh
# 5cijBBMsNo99+kedyPGBNJIoWNjg3knofg1pYfImxRsUb7czkKZMG+LVQYtRGeho
# ceHKyngNPbXjt61aF/YqbcJfqOKgEhKYCVLqyaFAKr0nbNKmU5GvnW+G1gZPThN0
# C/wAxzxYa8cq4hzWgvhoGSZtg0y+ktUyH1eWiMry2nINgkajgbIG13DOp20f+Bev
# EDluOgTB0yvu4/rE1I/nxrWj8qrklJ7mdSw/IIE2avaUOjlFI2ROM3eoBsu30hJO
# JFpgbciMpis1wHKtj2dzLftOZSMEQG/Wl05cDwyU1W4ZwqzeVGrGHev5YRnQehwu
# li89CToZgpFJ1HkMSDbmI2tJ9dTjjU4U9fhUrbISNcFPp5MAjPHX2M0pp6EBGgT2
# cLwDIBgeF5Bc2eXe20rayIfFZg1CY7Yax4CQheE1TZRk6bYXeKj5tBuyBKahVcJ3
# 2jV42SFZl6gxqR6IU3j8Vw==
# SIG # End signature block
