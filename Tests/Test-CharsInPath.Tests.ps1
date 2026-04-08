<#

    .SYNOPSIS
    Pester tests for function Test-CharsInPath

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, FileSystem, Pester

    CURRENT VERSION
    - 0.7.0 - 2017-10-16

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

#>



BeforeAll {
    $sut = 'Test-CharsInPath.ps1'
    $here = $PSScriptRoot
    [String]$PrivateFolderPath = Join-Path -Path $here -ChildPath '..\Private'
    [String]$SutPath = Join-Path -Path $PrivateFolderPath -ChildPath $sut
    . $SutPath
}

[Bool]$VerboseFunctionOutput = $false

Describe 'Test-CharsInPath' {

    Context 'Input is a file or a directory PSObject' {

        $TestFile = New-Item -Path 'TestDrive:' -Name 'TestFile1.txt' -ItemType File

        $TestDir = New-Item -Path 'TestDrive:' -Name 'TestDir1' -ItemType Container

        It 'Input is a directory, SkipCheckCharsInFolderPart' {

            Test-CharsInPath -path $TestDir -SkipCheckCharsInFolderPart | Should -Be 1

        }

        It 'Input is a file, SkipCheckCharsInFileNamePart' {

            Test-CharsInPath -path $TestFile -SkipCheckCharsInFileNamePart | Should -Be 1

        }

    }

    Context 'Input is a string' {


        BeforeAll {
            if ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $ISLinux) {

                #[char]58 = NULL

                [String]$CorrectPathString = '/Temp/Add-GroupsMember.ps1'

                [String]$InCorrectPathString = "/home/user/sett$([char]0)ings/Temp/Add-ADGroupMember.ps1"

                [String]$InCorrectFileNameString = "/home/user/Temp/Add-ADGrou$([char]0)Member.ps1"

                [String]$IncorrectFullPathString = "/usr/sha$([char]0)re/somewhere/Add-ADGroup$([char]0)Member.ps1"

                [String]$IncorrectDirectoryOnly = "/usr/share/loc$([char]0)al/"

                [String]$CorrectDirectoryOnly = '/etc/sysconfig/'

                [String]$IncorrectFileNameOnly = "Test-File-201606$([char]0)08-1315.txt"

                [String]$CorrectFileNameOnly = 'Test-File-20160608-1315.txt'

            } elseif ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $IsMacOS) {

                #[char]58 = ':'

                [String]$CorrectPathString = '/Temp/Add-GroupsMember.ps1'

                [String]$InCorrectPathString = "/home/user/sett$([char]58)ings/Temp/Add-ADGroupMember.ps1"

                [String]$InCorrectFileNameString = "/home/user/Temp/Add-ADGrou$([char]58)Member.ps1"

                [String]$IncorrectFullPathString = "/usr/sha$([char]58)re/somewhere/Add-ADGroup$([char]58)Member.ps1"

                [String]$IncorrectDirectoryOnly = "/usr/share/loc$([char]58)al/"

                [String]$CorrectDirectoryOnly = '/etc/sysconfig/'

                [String]$IncorrectFileNameOnly = "Test-File-201606$([char]58)08-1315.txt"

                [String]$CorrectFileNameOnly = 'Test-File-20160608-1315.txt'

            } elseif ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $IsWindows ) {

                #The differences between 'normal' PowerShell (based on PSEdition: Desktop, PSVersion 5.1.15063.483) and
                #PowerShell Core (based on PSEdition: Core, PSVersion: 6.0.0-beta) are
                #chars UTF8 34, 60, 62 for [System.IO.Path]::GetInvalidPathChars()

                [String]$CorrectPathString = 'C:\Windows\Temp\Add-GroupsMember.ps1'

                [String]$InCorrectPathString = 'C:\Win>dows\Te%mp\Add-ADGroupMember.ps1'

                [String]$InCorrectFileNameString = 'C:\Windows\Temp\Add-ADGrou|p<Member.ps1'

                [String]$IncorrectFullPathString = 'C:\Win>dows\Temp\Add-ADGrou|p<Member.ps1'

                [String]$IncorrectDirectoryOnly = 'C:\AppData\Loc|al\'

                [String]$CorrectDirectoryOnly = 'C:\AppData\Local\'

                [String]$IncorrectFileNameOnly = 'Test-File-201606*08-1315.txt'

                [String]$CorrectFileNameOnly = 'Test-File-20160608-1315.txt'

            }
            #Windows
            else {

                [String]$CorrectPathString = 'C:\Windows\Temp\Add-GroupsMember.ps1'

                [String]$InCorrectPathString = 'C:\Win>dows\Te%mp\Add-ADGroupMember.ps1'

                [String]$InCorrectFileNameString = 'C:\Windows\Temp\Add-ADGrou|p<Member.ps1'

                [String]$IncorrectFullPathString = 'C:\Win>dows\Temp\Add-ADGrou|p<Member.ps1'

                [String]$IncorrectDirectoryOnly = 'C:\AppData\Loc>al\'

                [String]$CorrectDirectoryOnly = 'C:\AppData\Local\'

                [String]$IncorrectFileNameOnly = 'Test-File-201606*08-1315.txt'

                [String]$CorrectFileNameOnly = 'Test-File-20160608-1315.txt'

            }
        }



        It 'Input is string, CorrectPathString' {

            Test-CharsInPath -Path $CorrectPathString -Verbose:$VerboseFunctionOutput | Should -Be 0


        }

        It 'Input is string, SkipCheckCharsInFolderPart, CorrectPathString' {

            Test-CharsInPath -Path $CorrectPathString -SkipCheckCharsInFolderPart -Verbose:$VerboseFunctionOutput | Should -Be 0

        }

        It 'Input is string, SkipCheckCharsInFileNamePart, CorrectPathString' {

            Test-CharsInPath -Path $CorrectPathString -SkipCheckCharsInFileNamePart -Verbose:$VerboseFunctionOutput | Should -Be 0

        }

        It 'Input is string, SkipCheckCharsInFolderPart, IncorrectDirectoryOnly' {

            Test-CharsInPath -Path $IncorrectDirectoryOnly -SkipCheckCharsInFolderPart -Verbose:$VerboseFunctionOutput | Should -Be 1

        }

        It 'Input is string, IncorrectDirectoryOnly' {

            Test-CharsInPath -Path $IncorrectDirectoryOnly -Verbose:$VerboseFunctionOutput | Should -Be 2

        }

        It 'Input is string, CorrectDirectoryOnly only' {

            Test-CharsInPath -Path $CorrectDirectoryOnly -Verbose:$VerboseFunctionOutput | Should -Be 0

        }

        It 'Input is string, SkipCheckCharsInFileNamePart, InCorrectFileNameString' {

            Test-CharsInPath -Path $InCorrectFileNameString -SkipCheckCharsInFileNamePart -Verbose:$VerboseFunctionOutput | Should -Be 0

        }

        It 'Input is string, InCorrectFileNameString' {

            Test-CharsInPath -Path $InCorrectFileNameString -Verbose:$VerboseFunctionOutput | Should -Be 3

        }

        It 'Input is string, SkipCheckCharsInFileNamePart, IncorrectFileNameOnly' {

            Test-CharsInPath -Path $IncorrectFileNameOnly -SkipCheckCharsInFileNamePart -Verbose:$VerboseFunctionOutput | Should -Be 1

        }

        It 'Input is string, IncorrectFileNameOnly only' {

            Test-CharsInPath -Path $IncorrectFileNameOnly -Verbose:$VerboseFunctionOutput | Should -Be 3

        }

        It 'Input is string, SkipCheckCharsInFileNamePart, CorrectFileNameOnly' {

            Test-CharsInPath -Path $CorrectFileNameOnly -SkipCheckCharsInFileNamePart -Verbose:$VerboseFunctionOutput | Should -Be 1

        }

        It 'Input is string, CorrectFileNameOnly only' {

            Test-CharsInPath -Path $CorrectFileNameOnly -Verbose:$VerboseFunctionOutput | Should -Be 0

        }

        It 'Input is string, SkipCheckCharsInFolderPart and SkipCheckCharsInFileNamePart, InCorrectPathString' {

            Test-CharsInPath -Path $CorrectPathString -SkipCheckCharsInFileNamePart -SkipCheckCharsInFolderPart -Verbose:$VerboseFunctionOutput | Should -Be 1

        }

    }

    Context 'Input is other than string or System.IO.X' {

        It 'Input is Int32' {

            [Int]$PathToTest = 23

            { Test-CharsInPath -Path $PathToTest -Verbose:$VerboseFunctionOutput } | Should -Throw

        }

        It 'Input is System.Diagnostics.Process' {

            $PathToTest = Get-Process | Select-Object -First 1

            { Test-CharsInPath -Path $PathToTest -Verbose:$VerboseFunctionOutput } | Should -Throw

        }

    }

}

# SIG # Begin signature block
# MIIcLAYJKoZIhvcNAQcCoIIcHTCCHBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCG9lGnmM6R8i1s
# aVpvx0roe5tejdLjuLHDlXryN68l56CCFmYwggMoMIICEKADAgECAhBSDm+iYBGr
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
# IgQgPkliweTwRtI3D1t/icO7lJrNKjyM82EmNqH7ntFGSzYwDQYJKoZIhvcNAQEB
# BQAEggEAarTiw/d/FvhPkm7wzq7TxWZnQG/370WazN/JQ0DKJ9iIaAL4EGedXvqh
# /SIkcpKWjOz0xbwJtnRhCQ1OfY0XTKPbwkE3/hJRtmLLPe5O+5KCFi+yt+yMqDWz
# sR2Z1lXcsMIr0eG/VAtiTfy0F+op3bmoAYfOab9lXteZSBsabE/bqWrh5s9l3A1z
# DdERIeTB3Sl1h0NlC16ZPmDlI30UgOmqwP1agb5GQhyC2AxW4Y6V9ugQceDKRwuR
# wS0mxUzLnFqU24OdEMTGWm3u24M78w0Ok3vipSIpkvLZ4CwVuXMvE6uKrRzyeeTJ
# s8rfwAmACyFNnGBRblfC/amQy8qkAqGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIID
# DwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0y
# NjA0MDgxODM2NTVaMC8GCSqGSIb3DQEJBDEiBCAt02obnRXY/K+Yopn1PhRIC2yd
# CxB+zgNvVi1OKAJvDDANBgkqhkiG9w0BAQEFAASCAgBDZwygQCTVRWPR7VV+yrwr
# +uSIHcspI8RsPNDyCHKY9TdGS8Fv8NAkEExNIWIDfWLOZF41L6v+m5e/FFJKTaHL
# azrpK+ipqkoRKmRK2CSddMu0hLtPQY9CInt9B4XN54jVuKS8Qc50XZGB7TdanH+0
# epscWVQh2YzJUseIFcRO04kKrHxvpx90wylvhwonnwgqkN3XCGLTKRdVZrAVKGQ9
# kFUg6q6zf8y+G2alKiopXdDlRp6dCIQn3K96scQh3epLOX85CFBVkovrizo5Rigg
# vetHi84kN/aK+gaXq1vPi5OCQxBL+gEklHP+e7unEdUEk1VLi+frU1vXvA7Y1MzZ
# bBWmZQpea2v/C0PmfUcbeQ5woGihvd0F4QtPvUDEGXkAqdcZ80BsGyD7nNc3sx3u
# BCzLP42AGEOD9QSOPt+uOQVXZrqaPDu5FcXmkEqkB2iad8GD4e8D11yWfJ0uigmv
# JQ5W6d8LbNfzlVP3Clc4fmefkYL6je84fddQtTKzXEV/0jlWnpVrWyrl9flOJat3
# tkOmjSh26pCzoWg1AgBRw4JkVf5Vi0sXvXtc11KtjRekP5gO7Lf/XXPEVbTn4Fz3
# e+sh0iU3rw23E9GtVSLQ8l2BkhElrz4QJHVYdxNDkq1SG/iB4uNFiN3c+pTxOd9U
# iyLhVFW5D67e3UtS9C883Q==
# SIG # End signature block
