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
