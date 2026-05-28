Function Test-CharsInPath {

<#

    .SYNOPSIS
    PowerShell function intended to verify if in the string what is the path to file or folder are incorrect chars.

    .DESCRIPTION
    PowerShell function intended to verify if in the string what is the path to file or folder are incorrect chars.

    Exit codes

    - 0 - everything OK
    - 1 - nothing to check
    - 2 - an incorrect char found in the path part
    - 3 - an incorrect char found in the file name part
    - 4 - incorrect chars found in the path part and in the file name part

    .PARAMETER Path
    Specifies the path to an item for what path (location on the disk) need to be checked.

    The Path can be an existing file or a folder on a disk provided as a PowerShell object or a string e.g. prepared to be used in file/folder creation.

    .PARAMETER SkipCheckCharsInFolderPart
    Skip checking in the folder part of path.

    .PARAMETER SkipCheckCharsInFileNamePart
    Skip checking in the file name part of path.

    .PARAMETER SkipDividingForParts
    Skip dividing provided path to a directory and a file name.

    Used usually in conjuction with SkipCheckCharsInFolderPart or SkipCheckCharsInFileNamePart.

    .EXAMPLE

    [PS] > Test-CharsInPath -Path $(Get-Item C:\Windows\Temp\new.csv') -Verbose

    VERBOSE: The path provided as a string was devided to, directory part: C:\Windows\Temp ; file name part: new.csv
    0

    Testing existing file. Returned code means that all chars are acceptable in the name of folder and file.

    .EXAMPLE

    [PS] > Test-CharsInPath -Path "C:\newfolder:2\nowy|.csv" -Verbose

    VERBOSE: The path provided as a string was devided to, directory part: C:\newfolder:2\ ; file name part: nowy|.csv
    VERBOSE: The incorrect char | with the UTF code [124] found in FileName part
    3

    Testing the string if can be used as a file name. The returned value means that can't do to an unsupported char in the file name.

    .OUTPUTS
    Exit code as an integer number. See description section to find the exit codes descriptions.

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, FileSystem

    REMARKS:
    # For Windows - based on the Power Tips
    # Finding Invalid File and Path Characters
    # http://community.idera.com/powershell/powertips/b/tips/posts/finding-invalid-file-and-path-characters
    # For PowerShell Core
    # https://docs.microsoft.com/en-us/dotnet/api/system.io.path.getinvalidpathchars?view=netcore-2.0
    # https://www.dwheeler.com/essays/fixing-unix-linux-filenames.html
    # [char]0 = NULL

    CURRENT VERSION
    - 0.7.0 - 2017-10-16

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md


#>

    [cmdletbinding()]
    [OutputType([System.Int32])]
    param (

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Path,
        [parameter(Mandatory = $false)]
        [switch]$SkipCheckCharsInFolderPart,
        [parameter(Mandatory = $false)]
        [switch]$SkipCheckCharsInFileNamePart,
        [parameter(Mandatory = $false)]
        [switch]$SkipDividingForParts

    )

    BEGIN {

        If ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core') -and $ISLinux) {

            #[char]0 = NULL
            $PathInvalidChars = [char]0

            $FileNameInvalidChars = @([char]0, '/')

            $PathSeparators = @('/')

        }
        Elseif ( ($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -EQ 'Core') -and $IsMacOS) {

            #[char]58 = ':'
            $PathInvalidChars = [char]58

            $FileNameInvalidChars = [char]58

            $PathSeparators = @('/')

        }
        #Windows
        Else {

            $PathInvalidChars = [System.IO.Path]::GetInvalidPathChars() #36 chars

            $FileNameInvalidChars = [System.IO.Path]::GetInvalidFileNameChars() #41 chars

            #$FileOnlyInvalidChars = @(':', '*', '?', '\', '/') #5 chars - as a difference

            $PathSeparators = @('/','\')

        }

        $IncorectCharFundInPath = $false

        $IncorectCharFundInFileName = $false

        $NothingToCheck = $true

    }

    END {

        [String]$DirectoryPath = ""

        [String]$FileName = ""

        $PathType = ($Path.GetType()).Name

        If (@('DirectoryInfo', 'FileInfo') -contains $PathType) {

            If (($SkipCheckCharsInFolderPart.IsPresent -and $PathType -eq 'DirectoryInfo') -or ($SkipCheckCharsInFileNamePart.IsPresent -and $PathType -eq 'FileInfo')) {

                Return 1

            }
            ElseIf ($PathType -eq 'DirectoryInfo') {

                [String]$DirectoryPath = $Path.FullName

            }

            elseif ($PathType -eq 'FileInfo') {

                [String]$DirectoryPath = $Path.DirectoryName

                [String]$FileName = $Path.Name

            }

        }

        ElseIf ($PathType -eq 'String') {

            If ( $SkipDividingForParts.IsPresent -and $SkipCheckCharsInFolderPart.IsPresent ) {

                $FileName = $Path

            }
            ElseIf ( $SkipDividingForParts.IsPresent -and $SkipCheckCharsInFileNamePart.IsPresent  ) {

                $DirectoryPath = $Path

            }
            Else {

                #Convert String to Array of chars
                $PathArray = $Path.ToCharArray()

                $PathLength = $PathArray.Length

                For ($i = ($PathLength-1); $i -ge 0; $i--) {

                    If ($PathSeparators -contains $PathArray[$i]) {

                        [String]$DirectoryPath = [String]$Path.Substring(0, $i +1)

                        break

                    }

                }

                If ([String]::IsNullOrEmpty($DirectoryPath)) {

                    [String]$FileName = [String]$Path

                }
                Else {

                    [String]$FileName = $Path.Replace($DirectoryPath, "")

                }

            }

        }
        Else {

            [String]$MessageText = "Input object {0} can't be tested" -f ($Path.GetType()).Name

            Throw $MessageText

        }

        [String]$MessageText = "The path provided as a string was divided to: directory part: {0} ; file name part: {1} ." -f $DirectoryPath, $FileName

        Write-Verbose -Message $MessageText

        If ($SkipCheckCharsInFolderPart.IsPresent -and $SkipCheckCharsInFileNamePart.IsPresent) {

            Return 1

        }

        If (-not ($SkipCheckCharsInFolderPart.IsPresent) -and -not [String]::IsNullOrEmpty($DirectoryPath)) {

            $NothingToCheck = $false

            foreach ($Char in $PathInvalidChars) {

                If ($DirectoryPath.ToCharArray() -contains $Char) {

                    $IncorectCharFundInPath = $true

                    [String]$MessageText = "The incorrect char {0} with the UTF code [{1}] found in the Path part." -f $Char, $([int][char]$Char)

                    Write-Verbose -Message $MessageText

                }

            }

        }

        If (-not ($SkipCheckCharsInFileNamePart.IsPresent) -and -not [String]::IsNullOrEmpty($FileName)) {

            $NothingToCheck = $false

            foreach ($Char in $FileNameInvalidChars) {

                If ($FileName.ToCharArray() -contains $Char) {

                    $IncorectCharFundInFileName = $true

                    [String]$MessageText = "The incorrect char {0} with the UTF code [{1}] found in FileName part." -f $Char, $([int][char]$Char)

                    Write-Verbose -Message $MessageText

                }

            }

        }

        If ($IncorectCharFundInPath -and $IncorectCharFundInFileName) {

            Return 4

        }
        elseif ($NothingToCheck) {

            Return 1

        }

        elseif ($IncorectCharFundInPath) {

            Return 2

        }

        elseif ($IncorectCharFundInFileName) {

            Return 3

        }
        Else {

            Return 0

        }

    }

}

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1XVEphT2HdOm6
# lkWqH7ly7Zc7EUBLD8xj2nxctFIwBqCCFnYwggM4MIICIKADAgECAhAXnbjlqWZv
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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgBsFI3D7QaRpccOjQHJXiILX4KO0h
# 2cf1DMLeVr+u/2wwDQYJKoZIhvcNAQEBBQAEggEAMVovAK0dsXgeZv3Tw1njzSEh
# oxxSL+KHnr3FDYClCq5ksf6msDWcjAJB735x+s3pkJO7ejSjmxZS4xLZYQEz+vDR
# Io73lSnz6k+d7AeAGB0jUAQnLg9z+QdBNNKxa984xfec0WWxVLQCjMsZ1T/a6K2S
# L5bfU71zbzRdmMdx9pqDloNg33bzEQ7cJqaMGVTVb9lW4s75HIoJ5UlKggeXNa72
# 1AiEP5QtkawiNwWAiJHiR2tXO0CcI9nnEaS1rZfH9viy8uKIKev0wuEIHqE2y78z
# B4fVvBInra9bpW32TYgmXXkAJcwYMMOswVOZNOtuQb3LtWyQI8iCkNao0PTwNqGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA1MjgwNjEyMjRaMC8GCSqGSIb3DQEJ
# BDEiBCBlqhUGaZeVIq8Clo5X84W6EOz8zy51Yg1A8G2iSffCPDANBgkqhkiG9w0B
# AQEFAASCAgCTPu/wPFCzcNNIRJsPF5NJoBKmkVQrEah9zTQjgMi22fuoDB52TYWw
# yB/OapBAT3edMniN8xlwIul60NSGR95zlTD6CudgM2XdXY9kZkUnAbzqhsNN9+5I
# iZHzcHZ5FRDp6/4DvUC9tUA0D1ne2VI1wmZIJnbYsJilaZL6fDn2rSFrYU9AJKLb
# rJaVlQcu80NMSzeIxRYrOyGqxSyTV8iblr/qmC60JmgTIMgOiGvIKVCYAxUizhX/
# d1CZNgPTCpaDfFIOVPjx+4fbREEQtB3nvq+ZUmd7YOy8qgre09DZsFjBRVF1YwsB
# VeIy9HQ/DncqJ3pqxQsOreQCJqI85QSpX1H6C27a3hM/4q3btxyB1dburuTJCpaJ
# W4qlrYg8iFPE+vn8QV2mb57OFreimyy4yzOezoWdicQqQBySiHV7Q2xW5VX+V+kV
# 7pK3WCvN2oE2pzR71P/rmCCAvNmcxA6PKusg7onQdiB7Gjy7BF75b4axmfA93QnL
# 0Q6w4LjPCNftZdJScCDB6PYqOQ+dNnldrr598I5NN8X1J4YG9EZqVYkv4PUIsI6J
# fl9zQIgPxvOQkguqmnWXmxgUwrVsxwakT6zcbSRGknNEwrv4NON5KCTUJEsikppo
# H+/oCZf6cYnTyyS12qR40ELYwj3iaolc4umL0UPXCGKnap5yk6a8ZA==
# SIG # End signature block
