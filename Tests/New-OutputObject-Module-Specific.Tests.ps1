<#

    .SYNOPSIS
    Pester tests to general validation of the New-OutputObject module - e.g. help, PSScriptAnalyzer results, style rules

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, Pester, psd1, New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    CURRENT VERSION
    - 0.9.11 - 2017.10.16

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

#>

$ModuleName = 'New-OutputObject'

$RelativePathToModuleRoot = '{0}{1}..' -f $PSScriptRoot, [System.IO.Path]::DirectorySeparatorChar

$RelativePathToModuleManifest = '{0}{1}{2}.psd1' -f $RelativePathToModuleRoot, [System.IO.Path]::DirectorySeparatorChar, $ModuleName

Describe "General tests for the $ModuleName module" {

    BeforeAll {

        # If BeforeAll fails, Skip everything
        $Global:PSDefaultParameterValues['It:Skip'] = $true

        #Remove module if it's currently loaded
        Get-Module -Name $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force

        It "$ModuleName should load without error" -Skip:$false {

            { Import-Module -FullyQualifiedName $RelativePathToModuleManifest -Force -Scope Global } | Should -Not -Throw

            Get-Module -Name $ModuleName | Should -Not -Be null

            # Since BeforeAll has passed, set skip to false
            $Global:PSDefaultParameterValues['It:Skip'] = $false

        }

    }

}

#Section mostly based on the blog post http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html
#Author: Fran"ois-Xavier Cat fxcat[at]lazywinadmin[dot]com
#Corrected by Wojciech Sciesinski wojciech[at]sciesinski[dot]net

Describe "Module $ModuleName functions help" -Tags 'Help' {

    $FunctionsList = (Get-Command -Module $ModuleName | Where-Object -FilterScript { $_.CommandType -eq 'Function' } ).Name

    foreach ($Function in $FunctionsList) {

        # Retrieve the Help of the function
        $Help = Get-Help -Name $Function -Full

        #Parsing Notes can be added also
        #$Notes = ($Help.alertSet.alert.text -split '\n')

        # Parse the function using AST
        $AST = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content function:$Function), [ref]$null, [ref]$null)

        Context "$Function - Help" {

            It 'Synopsis' { $help.Synopsis | Should -Not -BeNullOrEmpty }

            It 'Description' { $help.Description | Should -Not -BeNullOrEmpty }

            # Get the parameters declared in the Comment Based Help
            $RiskMitigationParameters = 'Whatif', 'Confirm'
            [String[]]$HelpParameters = $help.parameters.parameter | Where-Object name -NotIn $RiskMitigationParameters

            # Get the parameters declared in the AST PARAM() Block
            [String[]]$ASTParameters = $AST.ParamBlock.Parameters.Name.variablepath.userpath

            It 'Parameter - Compare amount of parameters Help vs AST' {

                $HelpParameters.count -eq $ASTParameters.count | Should -Be $true

            }

            # Parameter Description
            $help.parameters.parameter | ForEach-Object {

                It "Parameter $($_.Name) - Should contains description" {

                    if ($_.description) {
                        $_.description | Should -Not -BeNullOrEmpty
                    }

                }

            }

            # Examples
            It 'Example - Count should be greater than 0' {

                $Help.examples.example.code.count | Should -BeGreaterThan 0

            }

            # Examples - Remarks (small description that comes with the example)
            foreach ($Example in $Help.examples.example) {

                It "Example - Remarks on $($Example.Title)" {

                    if ($null -ne $Example.remarks) {
                        $Example.remarks | Should -Not -BeNullOrEmpty
                    }

                }

            }

        }

    }

}


#Section mostly based on the blog post https://blog.kilasuit.org/2016/03/29/invoking-psscriptanalyzer-in-pester-tests-for-each-rule/
#Author: Ryan Yates ryan[dot]yates[at]kilasuit[dot]org
#Corrected by Wojciech Sciesinski wojciech[at]sciesinski[dot]net

$Here = $PSScriptRoot

$Scripts = Get-ChildItem $(Join-Path -Path $here -ChildPath '..') -Filter '*.ps1' -Recurse | Where-Object { $_.name -notmatch 'Tests.ps1' }

$Modules = Get-ChildItem $(Join-Path -Path $here -ChildPath '..') -Filter '*.psm1' -Recurse

Import-Module -Name PSScriptAnalyzer -ErrorAction Stop

Describe 'PSScriptAnalyzer Compliance' -Tag 'PSScriptAnalyzer' {

    if ($Modules.Count -gt 0) {
        $ModuleTestCases = $Modules | ForEach-Object { @{ Path = $_.FullName; Name = $_.Name } }
        Context 'Modules' {
            It '<Name> should pass PSScriptAnalyzer' -TestCases $ModuleTestCases {
                param($Path, $Name)
                Invoke-ScriptAnalyzer -Path $Path | Should -BeNullOrEmpty
            }
        }
    }

    if ($Scripts.Count -gt 0) {
        $ScriptTestCases = $Scripts | ForEach-Object { @{ Path = $_.FullName; Name = $_.Name } }
        Context 'Scripts' {
            It '<Name> should pass PSScriptAnalyzer' -TestCases $ScriptTestCases {
                param($Path, $Name)
                Invoke-ScriptAnalyzer -Path $Path | Should -BeNullOrEmpty
            }
        }
    }
}


#Style rules based on Pester v. 4.0.2-rc2
Describe 'Style rules' -Tags 'Style' {

    $files = @(
        Get-ChildItem $RelativePathToModuleRoot\* -Include *.ps1, *.psm1
        Get-ChildItem (Join-Path $RelativePathToModuleRoot 'Public') -Include *.ps1, *.psm1 -Recurse
        Get-ChildItem (Join-Path $RelativePathToModuleRoot 'Private') -Include *.ps1, *.psm1 -Recurse
        Get-ChildItem (Join-Path $RelativePathToModuleRoot 'Tests') -Include *.ps1, *.psm1 -Recurse
    )

    It "$ModuleName source files contain no trailing whitespace" {

        $badLines = @(
            foreach ($file in $files) {

                $lines = [System.IO.File]::ReadAllLines($file.FullName)

                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++) {

                    if ($lines[$i] -match '\s+$') {

                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)

                    }

                }

            }

        )

        if ($badLines.Count -gt 0) {

            throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"

        }

    }

    It "$ModuleName source files lines start with a tab character" {

        $badLines = @(

            foreach ($file in $files) {

                $lines = [System.IO.File]::ReadAllLines($file.FullName)

                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++) {

                    if ($lines[$i] -match '^[  ]*\t|^\t|^\t[  ]*') {

                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)

                    }

                }

            }

        )

        if ($badLines.Count -gt 0) {

            throw "The following $($badLines.Count) lines start with a tab character: `r`n`r`n$($badLines -join "`r`n")"

        }

    }

    It "$ModuleName source files all end with a newline" {

        $badFiles = @(

            foreach ($file in $files) {

                $string = [System.IO.File]::ReadAllText($file.FullName)

                if ($string.Length -gt 0 -and $string[-1] -ne "`n") {

                    $file.FullName

                }

            }

        )

        if ($badFiles.Count -gt 0) {

            throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"

        }

    }

}

# SIG # Begin signature block
# MIIcRAYJKoZIhvcNAQcCoIIcNTCCHDECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBC4lsu2Qx4qfGf
# mw9JYjCETh49IF3txvYjmMhbUFcHr6CCFnYwggM4MIICIKADAgECAhBq68etXxgs
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
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgRsk49n/WSQZAOdbg6hgv3aumLR1U
# tH7pAxYXC9/GriUwDQYJKoZIhvcNAQEBBQAEggEAjfJinSlEQsajnFWZqN7Mw2r0
# WS2hpbN/TqKQxgIpkT2E3Uo5n3YDheE3fVCMK47cboXMKxv2aKmtRm0w1z1nUWX8
# SgxDGXM8pbBgqSWdqBK22seG32/7NMl2lI4fzHedPiR/Tcj6AKrZNizljsvRvrIL
# 0uUfWENILLoF2QG8WVLNo+paQFM5AgftNEQLmeO/OqZE39SLUPulOFj+VLDrsgp0
# Z7gVd9cD2lP4kko6bY9JGpdKB3mPp1qRPMdmpss1YDLLwYN7JDesVH9zqBR5JGXq
# 3kRSI4ftqJXXPqzLjCTxHR2ysmAa9PPmelK2/Prof6AjJyW8bb66QU5Cuu5V0KGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAhP3DNP
# fkVO28MPj/mSGDUwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjA5MTIwNzE5NDJaMC8GCSqGSIb3DQEJ
# BDEiBCAbqCYCVfAiau5HjmMJYQq7Z8yJQE8vOnzJidUrmbJBsTANBgkqhkiG9w0B
# AQEFAASCAgBWO6xfQoWApA+FV7iMKBma+55KewBGjoYTRfb4EEN951jKn4Yv3ohd
# uaRz4ZzphnOOIz0gTwTevImI/69XjrX5APM8cW0aUJKwfjoPah7ck4fs3LvRjnEU
# Xio7kV6QHLZuBURGHpP1r1R9F8N0Hq8lE+gKw9LlLDzzA6o3NQf91IpeyM+0sH31
# WMBtPcW0DpVRldkziBp4SBIl68G04qEii88Ypo3acxKdv4WWs8pmeRXhUzC6Iv9j
# YokGrLStFT3J0LCYXLQqILFprMSAiYZeD5c4G0VRsSOSDNXRLC7ym1KAQ00deqbl
# p/swI1oaMcHVLymP10c0EZTl0EU0W/alBoJOzlt47RE9Md7zPxP9Y4driKokqesm
# hadzpf8ClokGY3yq/laghv4CzUu5SqJ5O8mIVyDqOlNsayvgHpQclJze9+gAkoVc
# CfjFUJOpUXRdi2BiNTsRzhpayNQFpZQdruLbL2Y833+oAIEBMx+yy7KIcsdkU/X3
# h+LKBv0OFG1kNsL2bIh/9kPD1aKAZ/53pdej9qV53lDXca960T0U1Dv+7Ki18HT6
# i0jNVNhU4ZjRGMoNof6RVQFHV+kfgliDUn6EL064+CWZPg83YN7YVp9jyRm4D9Iq
# mAizgE1wcefsQ8n1oKWOyz79OrC/Lm+4/7mqkWD8djuGTC0mbkaMxw==
# SIG # End signature block
