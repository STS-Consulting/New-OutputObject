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
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5OGyJDRFSmBvk
# shq3a4cGJv6MjJshAk7EsXVrzOkIwKCCFnYwggM4MIICIKADAgECAhBq68etXxgs
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
# dGljb2RlIENvZGVTaWduaW5nQ2VydCAyNjA4LjMwLjIxMzkCEGrrx61fGCyXQjNS
# caeuJdgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg3V+WxkhdFzq9TynsIv6FaAnCIRiV
# OKrReTqvw0T9gCkwDQYJKoZIhvcNAQEBBQAEggEAaXwdBKzHuzRqx3p2ypo790gv
# t9CU28OIMhHzWz7b+23DD5c3hHC26nqx44DoaGEr0jKNMrWa1XHmT5+ndg3q28FQ
# ZuzXGbqabXkkfCnGfxvk8IEQWML8UtwYcD96AGN7Fh9u22c+eY9fEpIJNIyg4XE6
# EV0Zn6Z7JNmDGio+5IpUpohYSSiwv4EY8JaPcNc259+C7Jfg0473rDmXEAiDaJWs
# ixHpPZzU2nGMaF4OXdDJy/q+BLXuk9zo4afwyHBTS6IdneG59mmRWy3q9qu2zIA1
# PriVRaOKey8slHK4ERRqQx5DdEA7g4l9gdgRwfEkc62IoCBGcaH02HHi7LqpdqGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA5MDIwMTQ2MTFaMC8GCSqGSIb3DQEJ
# BDEiBCBbr0T6El7idj35Ra5C6lIMQAJG3U/JXHWWdJ96JCK0BzANBgkqhkiG9w0B
# AQEFAASCAgAx+y7jyw40v76bCVH5hlGe91zJdmnEn1bxyHoaOhjXp6oJrGvkkDo2
# 03fkDgx28h+Emmg02fnzWNnpKoYDE9FzDwsoDwnvcpKyGCeIBGFbKowz2kNzjXxM
# b3fzV6DUz6s54ubn2gRqAkKt0lk0bnC1M+EYlAGX2ZscOJni8l89BAkz/elbIm8B
# a8DDesAS0Lz1WrhHLcGIf4RoESlTFvUdp3ih/+TIgPDr6zuGp7b8KOFBe0M3x8rS
# 31lQDnDykI8Lmuy6t4UZNK8xFJjaaiZI17cdQpi2VMIxsYhJwBWQCHNfwqPaPMTo
# BuNyy1CJceChi67maDALo/y4wzq+V9jT+5BMPDiMauVyKj2ULCNg2E9+ag5axRo9
# vJsG5KxxMDVUQZOXLTD1GylMKIu2soAAcBfHSS9tiAlEGgo1yfptHvyPvp0pMUL4
# lTRJaJk+8YoLSeKTR1ZUeHs4ukHaQPFINM3MEk7FRDDshSOQvEkRgm31Qm7WFrC7
# aJa8OCv2Fi54JS4q7XLKoM+lMj5uguiEEkP7ojhjWF7/FpWeUeMLWvg3ijVBVESK
# tEAOR6eagICEU0DC29K5FOtf/wN26hgzStBsBieNq89X2wD0MtB8pBTtfntEUHN3
# wsXRmnEXRg8zaCRI+1IBcc7j0+NTeFGErkSBqW5E8h6M8oCEHJqscw==
# SIG # End signature block
