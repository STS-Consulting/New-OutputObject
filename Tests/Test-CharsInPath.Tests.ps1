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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg3V+WxkhdFzq9TynsIv6FaAnCIRiV
# OKrReTqvw0T9gCkwDQYJKoZIhvcNAQEBBQAEggEAaXwdBKzHuzRqx3p2ypo790gv
# t9CU28OIMhHzWz7b+23DD5c3hHC26nqx44DoaGEr0jKNMrWa1XHmT5+ndg3q28FQ
# ZuzXGbqabXkkfCnGfxvk8IEQWML8UtwYcD96AGN7Fh9u22c+eY9fEpIJNIyg4XE6
# EV0Zn6Z7JNmDGio+5IpUpohYSSiwv4EY8JaPcNc259+C7Jfg0473rDmXEAiDaJWs
# ixHpPZzU2nGMaF4OXdDJy/q+BLXuk9zo4afwyHBTS6IdneG59mmRWy3q9qu2zIA1
# PriVRaOKey8slHK4ERRqQx5DdEA7g4l9gdgRwfEkc62IoCBGcaH02HHi7LqpdqGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAhP3DNP
# fkVO28MPj/mSGDUwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA5MTIwNDMwMzRaMC8GCSqGSIb3DQEJ
# BDEiBCBbr0T6El7idj35Ra5C6lIMQAJG3U/JXHWWdJ96JCK0BzANBgkqhkiG9w0B
# AQEFAASCAgArKgDC+2p3szLSkoDbl4g51VrP0SGP5zXJ0dchzGLDIk7fgs8Jvg5t
# jZU0KoqvCOX2kh4XQ6ppQDWAB6KeIHzKyN8hymaXxKnQwDAJ8jNP3u5Wuw6Y/tFe
# 420F+jsDlFnzgDqjxxRmXJi1zF5WWOyAi52SOtkPZ3gzdTKzNDH8EP4OQE3hibS1
# BW96UyL50X/QY4+L6wpJvFiZon/8QrJZOWL1+FpPiML7y4u9wfzLcAXvmnRzxo8G
# 8btK6qoU4aNNRl2hYRZRnMy4LxB5WaJd9HajNXsDHPbGxLoqLvvJOvYZ8FFhnHM/
# XPIZvoNM0dY6azn8QCstHrhJm9Zat7mVLP1VNqAoQ+A1OyBzZEdR5vUqYDwUnCh4
# CnypeGG6AP4ffIS+iAvAdHQa1qauH/Ef6jB9zkp7WBBGbAxd8F69GN2nWpaIWN2h
# 22k7oBxX+9GsUNeSf7e5zPqv0/UaewG8mVMFXo8gegNUsdVRNa4GTNL9pMISXgyW
# tZ2UTBplt4ZkHuqgOHl5Ex8ZZey+dA08mBOCYRsTKTTtbV3yFdUtuZ3lbnSB+d9n
# x3K5couYZABttmDwWJP4S17SQQ8r89z028pfEARtpVPdi4IWzZd4ksImg3HE84Os
# ZbxBRejBQaQmtT2uedlTcqeYKJvtVp2evf5ScdIg/OpVfNNlzl15kg==
# SIG # End signature block
