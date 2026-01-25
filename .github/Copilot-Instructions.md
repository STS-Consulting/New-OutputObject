---
applyTo: "**/*.ps1,**/*.psm1,**/*.psd1"
description: "Comprehensive PowerShell development guidance for AI-assisted authoring (Copilot). Combines Microsoft cmdlet guidelines and community best practices."
---

## version: "2601.24.2100"

# PowerShell Development Guidelines for GitHub Copilot

This document consolidates authoritative guidance for using GitHub Copilot to generate and review PowerShell code. It focuses on security, maintainability, idiomatic PowerShell patterns, and adherence to Microsoft cmdlet development standards.

## Quick Contract (What Copilot Should Produce)

- **Inputs:** Function name, parameters, purpose, and any constraints (platform, versions, secrets handling)
- **Outputs:** An advanced function or module file that follows PowerShell community standards, includes comprehensive comment-based help, validation, and returns structured objects
- **Error Modes:** Clear non-terminating and terminating error handling; avoid leaking secrets
- **Success Criteria:** Script passes static analysis (ScriptAnalyzer), has basic Pester tests, uses approved verbs and types

## High-Level Principles

## Internal Consistency and Documentation Standards

All documentation, examples, and setup scripts (including `SETUP.md` and README files) **must strictly follow the rules and best practices outlined in this document**. This ensures:

- Internal consistency across all instructional materials
- Examples always reflect the current standards
- Setup scripts and documentation do not introduce conflicting or legacy patterns

**If a rule is updated, all examples and setup scripts must be updated to match.**

### Write-Host Usage

- Never use `Write-Host`. Period.
- Never use `Read-Host`. Period.
- Use `ShouldProcess` or `ShouldContinue` for interactive, non-pipeline display (e.g., setup verification, user prompts)
- Prefer `Write-Information`, `Write-Verbose`, `Write-Warning`, or `Write-Error` for status, diagnostics, and error reporting
- All examples and setup scripts must not use `Write-Host`.
- Do not create messages with a colon immediately after a variable `$VARIABLE:` is not allowed; use `$VARIABLE` or `$PSItem` instead.

**Example (Setup Verification):**

```powershell
# DO use Messages
Write-Information -MessageData "INFORMATION:  $PSItem ($($module.Version))" -InformationAction Continue
```

```powershell
# Do Not Use $VARIABLE:
Write-Information -MessageData "INFORMATION:  $PSItem: ($($module.Version))" -InformationAction Continue
```

## Coding Best Practices

- **Security First:** Never hardcode secrets; use SecretManagement/SecretStore or [PSCredential] with secure strings
- **Predictable, Testable Functions:** Prefer small, single-responsibility advanced functions that accept parameters and emit objects
- **Pipeline-Friendly:** Support Begin/Process/End/Clean blocks when appropriate; enable ValueFromPipeline or ValueFromPipelineByPropertyName
- **Full Cmdlet Names:** Use approved verbs from Get-Verb; avoid aliases in scripts
- **Readability Over Cleverness:** Use `$PSItem` instead of `$_`; prefer maintainability over micro-optimizations; optimize only when profiling shows need
- **No Wrappers:** Do not create wrapper functions that replace built-in PowerShell cmdlets or language features; use native commands
- **Rich Vocabulary:** Use extensive, precise vocabulary (e.g., "repudiated" or "forsaken" over "superseded" when contextually appropriate)

## Code Signing and Authenticode

- **NEVER generate or fabricate Authenticode signature blocks** - cryptographic signatures must be created using legitimate signing tools (`Set-AuthenticodeSignature`) with valid certificates
- **All PowerShell files should be signed AFTER verification** - this prevents configuration drift and malicious changes
- **Sign all file types:** `.ps1` (scripts), `.psm1` (modules), `.psd1` (manifests and data files), and `.ps1xml` (format files)
- **Verify before signing:** Always validate syntax, run tests, and perform code review before applying signatures
- **Use proper tooling:** Use `Set-AuthenticodeSignature` cmdlet with valid code signing certificates from trusted CAs
- **Check signatures:** Use `Get-AuthenticodeSignature` to verify file signatures before execution
- **AllSigned execution policy:** Consider using `AllSigned` execution policy in production environments to require all scripts be signed

## Style and Formatting

- **Brace Style:** One True Brace Style (opening brace at end of the line, closing brace on new line)
- **Indentation:** Use 4-space indentation consistently
- **Casing:**
  - PascalCase for function and parameter names
  - camelCase for private/local variables
  - PascalCase for public variables
- **Line Length:** Keep lines reasonably short (115-120 characters recommended)
- **No Linebreaks in Messages** Do not use linebreaks (e.g., `\n` or backtick-n) in `Write-Information`, `Write-Verbose`, `Write-Warning`, or `Write-Error` messages.
- **Pipeline Formatting:** Use line breaks after pipeline operators for readability
- **Whitespace:** Avoid unnecessary whitespace; use consistent spacing around operators
- **Quotes:** Always use straight quotes (' or ") in code and documentation (avoid smart quotes)
- **Dashes:** Use hyphens (-) only; avoid en/em dashes in code and documentation
- **Comment-Based Help:** Required for all public functions with:
  - `.VERSION` (format: YYMM.DD.HH00)
  - `.GUID` (unique identifier)
  - `.COMPATIBLEPSEDITIONS` (Core, Desktop, or both)
  - `.AUTHOR` (full name)
  - `.COMPANYNAME`
  - `.COPYRIGHT` (with license type)
  - `.TAGS` (comma-separated keywords)
  - `.PROJECTURI` (GitHub or project URL)
  - `.LICENSEURI` (license URL)
  - `.ICONURI` (icon URL if available)
  - `.EXTERNALMODULEDEPENDENCIES`
  - `.REQUIREDSCRIPTS`
  - `.EXTERNALSCRIPTDEPENDENCIES`
  - `.RELEASENOTES`
  - `.PRIVATEDATA`
  - `.SYNOPSIS` (brief description)
  - `.DESCRIPTION` (detailed explanation)
  - `.PARAMETER` (descriptions for each parameter)
  - `.EXAMPLE` (practical usage examples)
  - `.OUTPUTS` (type of output returned)
  - `.NOTES` (additional information)
    - Do not duplicate information from PSScriptInfo in .NOTES (e.g., .Version, .Author, .CompanyName, .Copyright, .CompatiblePSEditions, .GUID)

### Characters and Glyphs

- We work in a Unicode-first environment with NerdFonts installed
- Prefer extended Unicode glyphs over emoji in documentation, comments, and help
- Do not use glyphs in identifiers (function/parameter names); restrict to documentation, messages, and help text
- Ensure files are saved as UTF-8BOM; verify rendering on non-NerdFont systems or provide a plain-text fallback when necessary
- Often used glyphs:
  - Horizontal Ellipsis …
  - Interrobang ‽
  - Section Sign §

Example: specific copyright block for documentation

```markdown
---
mainfont: "Cascadia Mono NF"
---

.COPYRIGHT CC BY-NC-SA  2025 By STS
(Creative Commons Attribution-NonCommercial-ShareAlike)
[nf-fa-creative_commons nf-fa-creative_commons_by nf-fa-creative_commons_nc nf-fa-creative_commons_sa]
```

### Output Colors and Formatting

- **Remove Hardcoded Colors:** Ensure no hardcoded color settings are used in scripts.
- **Use $PSStyle:** Utilize `$PSStyle` properties that match the intended semantic display.

**Preferred Mappings:**

- `$PSStyle.FileInfo.Directory`
- `$PSStyle.FileInfo.SymbolicLink`
- `$PSStyle.FileInfo.Executable`
- `$PSStyle.FileInfo.Extension`
- `$PSStyle.Formatting.FormatAccent`
- `$PSStyle.Formatting.ErrorAccent`
- `$PSStyle.Formatting.Error`
- `$PSStyle.Formatting.Warning`
- `$PSStyle.Formatting.Verbose`
- `$PSStyle.Formatting.Debug`
- `$PSStyle.Formatting.TableHeader`
- `$PSStyle.Formatting.CustomTableHeaderLabel`
- `$PSStyle.Formatting.FeedbackName`
- `$PSStyle.Formatting.FeedbackText`
- `$PSStyle.Formatting.FeedbackAction`

**Fallback Mappings:**

_Use specific foreground/background colors only when semantic mappings are unavailable._

- `$PSStyle.Foreground.Black`
- `$PSStyle.Foreground.BrightBlack`
- `$PSStyle.Foreground.White`
- `$PSStyle.Foreground.BrightWhite`
- `$PSStyle.Foreground.Red`
- `$PSStyle.Foreground.BrightRed`
- `$PSStyle.Foreground.Magenta`
- `$PSStyle.Foreground.BrightMagenta`
- `$PSStyle.Foreground.Blue`
- `$PSStyle.Foreground.BrightBlue`
- `$PSStyle.Foreground.Cyan`
- `$PSStyle.Foreground.BrightCyan`
- `$PSStyle.Foreground.Green`
- `$PSStyle.Foreground.BrightGreen`
- `$PSStyle.Foreground.Yellow`
- `$PSStyle.Foreground.BrightYellow`
- `$PSStyle.Background.Black`
- `$PSStyle.Background.BrightBlack`
- `$PSStyle.Background.White`
- `$PSStyle.Background.BrightWhite`
- `$PSStyle.Background.Red`
- `$PSStyle.Background.BrightRed`
- `$PSStyle.Background.Magenta`
- `$PSStyle.Background.BrightMagenta`
- `$PSStyle.Background.Blue`
- `$PSStyle.Background.BrightBlue`
- `$PSStyle.Background.Cyan`
- `$PSStyle.Background.BrightCyan`
- `$PSStyle.Background.Green`
- `$PSStyle.Background.BrightGreen`
- `$PSStyle.Background.Yellow`
- `$PSStyle.Background.BrightYellow`

## Naming Conventions

### Function Names

- **Format:** Verb-Noun using approved PowerShell verbs from Get-Verb
- **Examples:** Get-UserProfile, Set-ResourceConfiguration, New-DatabaseConnection
- **Avoid:** Special characters, spaces, unapproved verbs
- **Consistency:** Use singular nouns unless the function inherently deals with multiple items

### Parameter Names

- **Casing:** PascalCase
- **Clarity:** Choose clear, descriptive names
- **Form:** Use singular form unless parameter always accepts multiple values
- **Standards:** Follow PowerShell standard parameter names (Path, Name, Force, ComputerName, etc.)
- **Common Parameters:**
  - `Path` for file system paths
  - `Name` for object identifiers
  - `Force` to require explicit confirmation bypassing or overwriting
  - `ComputerName` for remote computer targeting
  - `Credential` for authentication

### Variable Names

- **Public Variables:** PascalCase
- **Private Variables:** camelCase
- **Descriptiveness:** Use meaningful names; avoid abbreviations
- **Consistency:** Maintain naming patterns throughout codebase

### Alias Avoidance

- **Scripts:** Always use full cmdlet names (Get-ChildItem, not gci, ls, or dir)
- **Interactive:** Aliases acceptable for interactive shell use only
- **Common Replacements:**
  - Use `Where-Object` instead of `?` or `where`
  - Use `ForEach-Object` instead of `%` or `foreach`
  - Use `Get-ChildItem` instead of `ls`, `dir`, or `gci`
  - Use `New-Item` instead of `mkdir` or `md`
  - Use `Select-Object` instead of `select`

### Abbreviations

- Prefer full words over acronyms in function, parameter, and variable names
- Use the full term `Parameters` (not `Params`) except when required by external APIs/contracts
- Environment names: use `Development`, `Test`, and `Production` (not `Dev` or `Prod`)
- Loop/index variables: avoid single-letter names like `i` or `j`; prefer `item`, `index1`, `index2`, or `iteration`
- Exceptions: Only use acronyms when interoperating with external APIs or contracts that require them

## Project Structure and Organization

### Recommended Layout

```
ModuleName/
├── Public/           # Exported functions
├── Private/          # Internal helper functions
├── Classes/          # PowerShell classes
├── Tests/            # Pester tests
│   ├── Unit/        # Unit tests
│   ├── Integration/ # Integration tests
│   └── Performance/ # Performance tests
├── Troubleshooting/ # Logs and diagnostic documentation
├── Resources/       # Icons, images, data files
└── ModuleName.psd1  # Module manifest
```

### Module Organization

- Keep functions focused and single-purpose
- Place exported functions in Public/
- Place internal helpers in Private/
- Organize by feature or domain when appropriate
- Include README.md with usage examples

## Parameter Design and Validation

### Standard Parameters

- **Common Names:** Use standard parameter names consistently (Path, Name, Force, Credential, ComputerName)
- **Type Selection:** Use appropriate .NET types and PowerShell-specific types
- **Validation:** Implement proper validation attributes
- **Tab Completion:** Enable tab completion with ValidateSet where appropriate
- **Aliases:** Use Parameter aliases sparingly for backward compatibility
- **Explicit Parameters:** Prefer explicitly passing parameter names in calls (e.g., `-Path $Path`)
- **Splatting:** Use splatting for complex calls to improve readability (e.g., `& Command @parameters`)
- **Logical Operators:** Use `-not` instead of `!` for clarity
- **Wildcards:** Avoid `SupportsWildcards` for path parameters for security reasons

### Parameter Attributes

```powershell
[Parameter(
    Mandatory = $true,
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true,
    Position = 0,
    HelpMessage = "Enter the resource name"
)]
[ValidateNotNullOrEmpty()]
[ValidatePattern('^[a-zA-Z0-9-_]+$')]
[Alias('ResourceName')]
[string]$Name
```

### Validation Attributes

- `[ValidateNotNullOrEmpty()]` - Ensures parameter has a value
- `[ValidateSet('Value1','Value2')]` - Limits to specific values
- `[ValidatePattern('^regex$')]` - Validates against regex pattern
- `[ValidateRange(1, 100)]` - Validates numeric range
- `[ValidateLength(1, 50)]` - Validates string length
- `[ValidateCount(1, 5)]` - Validates array count
- `[ValidateScript({ Test-Path $PSItem })]` - Custom validation logic

### Type Selection

- Use `[string]` for text values
- Use `[int]`, `[long]`, `[double]` for numeric values
- Use `[switch]` for boolean flags (never use $true/$false parameters)
- Use `[datetime]` for date/time values
- Use `[System.IO.FileInfo]` for file paths
- Use `[System.IO.DirectoryInfo]` for directory paths
- Use `[PSCredential]` for credentials
- Use `[ValidateSet()]` with string for enumerated values

### Switch Parameters

- Use `[switch]` type for boolean flags
- Default to `$false` when omitted
- Use clear action names (Force, PassThru, Recurse, NoClobber)
- Avoid parameters that accept literal $true/$false values
- Example: `[Parameter()][switch]$Force` to bypass confirmation prompts

### Default Values and Configuration

- **Defaults File:** Store default values in PowerShell Data Files (.psd1)
  - Module-level defaults: `ModuleName.psd1`
  - Machine-specific overrides: `ModuleName.MachineName.psd1`
- **Loading Defaults:** Use `Import-PowerShellDataFile`
  ```powershell
  $defaults = Import-PowerShellDataFile -Path "$PSScriptRoot\Defaults.psd1"
  $machineDefaults = Import-PowerShellDataFile -Path "$PSScriptRoot\ModuleName.$env:COMPUTERNAME.psd1" -ErrorAction SilentlyContinue
  ```
- **Platform Requirements:** Document with `#Requires` statements
  ```powershell
  #Requires -Version 7.2
  #Requires -Modules Az.Accounts
  #Requires -PSEdition Core
  ```

## Pipeline and Output

### Pipeline Input

- **ValueFromPipeline:** Use for direct object input (processes entire object)
- **ValueFromPipelineByPropertyName:** Use for property mapping (processes specific properties)
- **Implementation:** Use Begin/Process/End/Clean blocks for proper pipeline handling
- **Documentation:** Document pipeline input requirements in comment-based help

```powershell
[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
[string]$Name
```

### Output Objects

- **Rich Objects:** Return structured objects (PSCustomObject), not formatted text
- **Type Names:** Use PSTypeName for custom type identification when beneficial
- **Consistency:** Ensure consistent output structure across all code paths
- **Avoid Write-Host:** Never use Write-Host for data output; reserve for interactive display only
- **Enable Processing:** Structure output to enable downstream cmdlet processing

```powershell
$result = [PSCustomObject]@{
    PSTypeName = 'CustomModule.ResourceInfo'
    Name = $Name
    Status = $Status
    Created = (Get-Date -Format 'yyMM.dd.HHmm')
}
```

### Pipeline Streaming

- **Stream Output:** Output one object at a time in the Process block
- **Avoid Accumulation:** Do not collect large arrays in memory unnecessarily
- **Immediate Processing:** Enable immediate downstream processing
- **Memory Efficiency:** Process items as they arrive rather than batching

```powershell
process {
    # Process and output each item immediately
    foreach ($item in $Collection) {
        $result = Process-Item -Item $item
        Write-Output -InputObject $result  # Stream immediately
    }
}
```

### PassThru Pattern

- **Default Behavior:** Action cmdlets (New-, Set-, Remove-) should produce no output by default
- **PassThru Switch:** Implement `-PassThru` parameter to return created/modified object
- **Status Updates:** Use `Write-Information` for status messages (not Write-Verbose/Warning)
- **Return Value:** Return the actual object that was created or modified
- **Consistency:** Use `$PSItem` (never `$_`) for current pipeline object

```powershell
function Update-ResourceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $timestamp = Get-Date
    }

    process {
        # Perform update operation
        $resource = Update-InternalResource -Name $Name

        # Status update (visible with -InformationAction Continue)
        Write-Information -MessageData "Information: [Update-ResourceStatus] Updated resource: $Name"

        # Only output if PassThru requested
        if ($PassThru) {
            Write-Output -InputObject $resource
        }
    }
    end {
        Write-Information -MessageData "Information: [Update-ResourceStatus] Updated resource: $Name"
    }
    clean {
        Remove-Variable -Name 'timestamp' -ErrorAction SilentlyContinue
        Remove-Variable -Name 'resource' -ErrorAction SilentlyContinue
    }
}
```

### CLEAN Block Guidelines

- Use a `clean` block to remove temporary, function-created variables (timestamps, loop counters, intermediate objects)
- Do not remove parameters or caller-supplied values; only clean up locals that this function created
- Close or dispose external resources in `finally` or `clean` (files, connections), ensuring operations are idempotent
- Keep `clean` fast and side-effect free beyond releasing resources and clearing locals

## Error Handling and Safety

### ShouldProcess Implementation

- **Enable Support:** Use `[CmdletBinding(SupportsShouldProcess = $true)]` for operations that modify system state
- **Confirm Impact:** Set appropriate `ConfirmImpact` level (Low, Medium, High)
- **ShouldProcess Call:** Call `$PSCmdlet.ShouldProcess($target, $action)` before making changes
- **ShouldContinue:** Use for additional confirmations beyond standard -WhatIf/-Confirm
- **Force Parameter Required:** Whenever `ShouldProcess` or `ShouldContinue` is used, always include a `[switch]$Force` parameter to allow bypassing confirmations. Check `$Force` before calling ShouldProcess/ShouldContinue: `if ($Force -or $PSCmdlet.ShouldProcess(...))`

```powershell
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter()]
    [switch]$Force
)

if ($Force -or $PSCmdlet.ShouldProcess($Name, "Remove resource")) {
    # Perform the operation
}
```

### Message Streams

- **Write-Information:** Status updates and informational messages (visible with `-InformationAction Continue`)
- **Write-Verbose:** Operational details for trouleshooting (visible with `-Verbose`)
- **Write-Warning:** Warning conditions that do not stop execution
- **Write-Error:** Non-terminating errors (execution continues)
- **throw:** Terminating errors (execution stops immediately)
- **Avoid Write-Host:** Never use for data output
- **Avoid Read-Host:** Never use for data input

```powershell
Write-Information -MessageData "INFORMATIONProcessing resource: $Name"
Write-Verbose -Message "Connection string: $connectionString"
Write-Warning -Message "Resource $Name is deprecated" -WarningAction Continue
Write-Error -Message "Failed to process $Name" -ErrorAction Continue
throw "Critical failure: Cannot continue"
```

### Error Handling Pattern

- **Try-Catch-Finally:** Use structured error handling for all risky operations
- **ErrorAction:** Set appropriate ErrorAction preferences (`Stop`, `Continue`, `SilentlyContinue`)
- **Meaningful Messages:** Provide clear, actionable error messages with context
- **ErrorVariable:** Use `-ErrorVariable` to capture errors for later analysis
- **Correlation IDs:** Include correlation IDs for distributed system troubleshooting
- **Structured Errors:** Use `$PSItem` to access the current exception object

```powershell
begin {
    $ErrorActionPreference = 'Stop'
    $correlationId = [guid]::NewGuid()
}

process {
    try {
        # Risky operation
        $result = Invoke-RiskyOperation -Name $Name
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "[Invoke-RiskyOperation] Access denied for resource '$Name'. CorrelationId: $correlationId" -ErrorAction Stop
    }
    catch {
        Write-Error "[Invoke-RiskyOperation] Unexpected error processing '$Name': $($PSItem.Exception.Message). CorrelationId: $correlationId"
        throw
    }
    finally {
        # Cleanup operations
        if ($connection) { $connection.Close() }
    }
}
```

### Non-Interactive Design

- **Parameter Input:** Accept all input via parameters (never use Read-Host in production scripts)
- **Automation Ready:** Design for unattended execution (scheduled tasks, CI/CD)
- **Progress Indication:** Use `Write-Progress` for long-running operations (loops > few seconds)
- **Documentation:** Document all required inputs in comment-based help
- **Default Values:** Provide sensible defaults where appropriate

````powershell
function Process-LargeDataset {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Items
    )

    begin {
        $totalItems = $Items.Count
        $currentItem = 0
    }

    process {
        foreach ($item in $Items) {
            $currentItem++
            Write-Progress -Activity "Processing dataset" -Status "Item $currentItem of $totalItems" -PercentComplete (($currentItem / $totalItems) * 100)

            # Process item
            Process-Item -Item $item
        }
    }

    end {
        Write-Progress -Activity "Processing dataset" -Completed
    }

    clean {
        Remove-Variable -Name 'totalItems' -ErrorAction SilentlyContinue
        Remove-Variable -Name 'currentItem' -ErrorAction SilentlyContinue
        Remove-Variable -Name 'item' -ErrorAction SilentlyContinue
    }
}

## Security Guidance

### Credential Management

- **Never Hardcode:** Never hardcode credentials, API keys, or secrets in scripts
- **SecretManagement:** Use `Microsoft.PowerShell.SecretManagement` and `Microsoft.PowerShell.SecretStore` modules for credential storage
- **Platform Vaults:** Leverage platform-specific secure storage (Windows Credential Manager, Azure Key Vault)
- **PSCredential:** Use `[PSCredential]` type for credential parameters
- **Secure Strings:** Create credentials with `[PSCredential]::new($username, $securePassword)`

```powershell
# Retrieve from SecretManagement
$credential = Get-Secret -Name 'ServiceAccount' -AsPlainText:$false

# Accept as parameter
[Parameter(Mandatory)]
[PSCredential]$Credential

```

### Input Validation and Sanitization

- **Path Validation:** Always validate and canonicalize file paths with `Resolve-Path` or `Test-Path`
- **Pattern Matching:** Use `ValidatePattern` for structured input (emails, IDs, resource names)
- **Injection Prevention:** Avoid `Invoke-Expression` with untrusted input
- **Call Operator:** Use call operator `&` or `Start-Process` with validated arguments
- **Type Validation:** Leverage strong typing to prevent type confusion attacks

```powershell
# Validate paths
[Parameter(Mandatory)]
[ValidateScript({ Test-Path $PSItem -PathType Container })]
[string]$Path

# Sanitize input
$safePath = Resolve-Path -Path $Path -ErrorAction Stop

# Avoid Invoke-Expression
# BAD: Invoke-Expression $userInput
# GOOD: & $validatedCommand $sanitizedArguments
```

### Secure Communication

- **TLS/SSL:** Always use HTTPS for network communications
- **Certificate Validation:** Validate SSL certificates (do not bypass warnings in production)
- **Authentication:** Use modern authentication (OAuth, managed identities) over basic auth
- **Logging:** Never log sensitive data (passwords, tokens, PII)

### Module Imports

- **Explicit Imports:** Module imports must be specified by file name and never a wildcard, for security reasons.
- **Avoid Wildcards:** Do not use `Import-Module *` or `Get-ChildItem -Recurse | Where-Object { $_.Extension -eq '.ps1' } | Dot-Source`. Explicitly list files to be imported or sourced.

## Performance Optimization

### General Guidelines

- **Measure First:** Always profile before optimizing; use `Measure-Command` for timing
- **Optimize Hot Paths:** Focus optimization efforts on frequently-executed code
- **Built-in Cmdlets:** Prefer built-in cmdlets and operators over custom implementations
- **Pipeline Efficiency:** Leverage the pipeline for filtering and transformation

### String Operations

- **Small Operations:** Simple concatenation (`+`) is acceptable for < 100 operations
- **Large Operations:** Use `StringBuilder` for extensive string manipulation or loops
- **String Formatting:** Use `-f` operator or string interpolation for readability

```powershell
# Small: OK
$result = "Hello, " + $name + "!"

# Large: Use StringBuilder
$sb = [System.Text.StringBuilder]::new()
foreach ($item in $largeCollection) {
    [void]$sb.AppendLine($item)
}
$result = $sb.ToString()
```

### Collection Operations

- **Avoid Array Appends:** Do not use `+=` in hot loops (creates new array each time)
- **ArrayList:** Use `[System.Collections.ArrayList]` for dynamic collections
- **Generic Lists:** Use `[System.Collections.Generic.List[type]]` when type is known
- **Pipeline Processing:** Stream items through pipeline instead of accumulating

```powershell
# BAD: Quadratic performance
$results = @()
foreach ($item in $largeCollection) {
    $results += Process-Item $item  # Creates new array each time
}

# GOOD: Linear performance
$results = [System.Collections.Generic.List[object]]::new()
foreach ($item in $largeCollection) {
    $results.Add((Process-Item $item))
}

# BEST: Pipeline streaming (no accumulation)
$largeCollection | ForEach-Object { Process-Item $PSItem }
```

### Filtering and Projection

- **Where-Object:** Use for filtering collections
- **Select-Object:** Use for projection and property selection
- **ForEach-Object:** Use for transformation in pipeline
- **Script Blocks:** Keep script blocks simple for better performance

## Testing and Validation

### Required PowerShell Modules

Install the following modules for validation, testing, and documentation:

```powershell
# Testing and validation modules
Install-Module -Repository PSGallery -Scope AllUsers -Name 'Pester'
Install-Module -Repository PSGallery -Scope AllUsers -Name 'PSScriptAnalyzer'

# Documentation modules
Install-Module -Repository PSGallery -Scope AllUsers -Name 'Microsoft.PowerShell.PlatyPS'
Install-Module -Repository PSGallery -Scope AllUsers -Name 'PSDocs'

# Secret management modules
Install-Module -Repository PSGallery -Scope AllUsers -Name 'Microsoft.PowerShell.SecretManagement'
Install-Module -Repository PSGallery -Scope AllUsers -Name 'Microsoft.PowerShell.SecretStore'

# Dependency management
Install-Module -Repository PSGallery -Scope AllUsers -Name 'PSDepend'

# Build automation
Install-Module -Repository PSGallery -Scope AllUsers -Name 'psake'
```

### Pester Testing

- **Coverage:** Include tests for happy path and error/edge cases
- **Organization:** Place tests under `Tests/Unit/`, `Tests/Integration/`, `Tests/Performance/`
- **Naming:** Test file names should match function names with `.Tests.ps1` suffix
- **Structure:** Use `Describe`, `Context`, and `It` blocks for organized test cases
- **Mocking:** Use `Mock` for external dependencies and cmdlets

```powershell
Describe 'Get-UserProfile' {
    Context 'When user exists' {
        It 'Returns user profile object' {
            $result = Get-UserProfile -Username 'testuser'
            $result | Should -Not -BeNullOrEmpty
            $result.Username | Should -Be 'testuser'
        }
    }

    Context 'When user does not exist' {
        It 'Throws error' {
            { Get-UserProfile -Username 'nonexistent' } | Should -Throw
        }
    }
}
```

### Pester 5 Authoring Directive (Mandatory)

- **Dot-sourcing:** Resolve paths explicitly; avoid fragile relatives. Use `Resolve-Path` and `Join-Path` to dot-source targets and helpers.
  - Example:
    ```powershell
    $repoRoot   = (Resolve-Path -Path (Join-Path $PSScriptRoot '..\..')).Path
    $scriptPath = Resolve-Path -Path (Join-Path $repoRoot 'Scripts\Copy-MediaBatch.ps1')
    . $scriptPath
    . (Join-Path $PSScriptRoot '..\Support\TestHelpers.ps1')
    Initialize-StandardTest
    ```
- **Typed mocks:** When mocking CIM/WMI or external APIs, return objects with correct numeric types and property names. Prefer `PSCustomObject` with explicit properties.
  - Example (CIM logical disk):
    ```powershell
    Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_LogicalDisk' } -MockWith {
        [PSCustomObject]@{
            DeviceID     = 'E:'
            Size         = [long]100GB
            FreeSpace    = [long]80GB
            FileSystem   = 'NTFS'
            DriveType    = 3
            VolumeSerialNumber = 'TEST0001'
        }
    }
    ```
- **Property assertions:** Prefer `Should -HaveProperty` and value checks over hashtables or `-ContainKey` on PSCustomObject.
- **-WhatIf flows:** Wrap in try/catch and assert no throw; validate summary object shape with `-HaveProperty` checks.
- **$PSItem usage:** Use `$PSItem` in script blocks and catch blocks (avoid `$_`).
- **Idempotence:** Create and clean temporary resources in `BeforeAll`/`AfterAll`. Ensure tests are safe to rerun.
- **Strictness:** Start tests with `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` via `Initialize-StandardTest` from `tests/Support/TestHelpers.ps1`.
- **Linting (optional but encouraged):** Use `Invoke-LintCheck` (from helpers) to lint changed files within tests when beneficial.

Template header for new test files:

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\Support\TestHelpers.ps1')
    Initialize-StandardTest

    $repoRoot    = (Resolve-Path -Path (Join-Path $PSScriptRoot '..\..')).Path
    $targetPath  = Resolve-Path -Path (Join-Path $repoRoot 'Scripts\Your-ScriptOrModule.ps1')
    . $targetPath
}

Describe 'Your-Thing' -Tag 'unit','critical' {
    It 'Has expected properties' {
        $obj = [PSCustomObject]@{ Name = 'Example'; Count = 1 }
        $obj | Should -HaveProperty 'Name'
        $obj.Name | Should -Be 'Example'
    }
}
```

### Static Analysis

- **ScriptAnalyzer:** Run `Invoke-ScriptAnalyzer` on all scripts before commit
- **Zero Critical:** Aim for zero critical violations before merging
- **Custom Rules:** Define project-specific rules in PSScriptAnalyzerSettings.psd1
- **CI Integration:** Include ScriptAnalyzer in continuous integration pipeline

```powershell
# Run ScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\MyScript.ps1 -Severity Error, Warning

# With settings file
Invoke-ScriptAnalyzer -Path .\MyScript.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
```

### Validation Checklist

- [ ] Function follows Verb-Noun naming with approved verb
- [ ] Comment-based help is complete and accurate
- [ ] Parameters have proper validation attributes
- [ ] Error handling covers expected failure scenarios
- [ ] Pipeline support implemented where appropriate
- [ ] PassThru pattern used correctly for action cmdlets
- [ ] No hardcoded secrets or credentials
- [ ] Pester tests cover main scenarios
- [ ] ScriptAnalyzer shows no critical issues

## PowerShell Scopes: Usage Guidelines

When generating or modifying PowerShell, apply scope rules deliberately so variables, functions, and aliases behave predictably across functions, scripts, modules, and sessions.

### Scope Overview

- **Global:** Entire session scope. Avoid unless explicitly required for cross-session behavior.
- **Script:** The whole script/module file. Use for module-level state or helpers shared internally.
- **Local:** Default inside a function/script block. Prefer for temporary variables.
- **Private:** Restrict visibility to current scope only for internal helpers/secrets.
- **Module:** Module context. Export only intended members; avoid polluting global scope.

See: about_Scopes (Microsoft Docs)

### Best Practices

- Default to local scope; avoid unnecessary scope prefixes
- Use `script:` for shared module state and internal helpers
- Avoid `global:` unless explicitly requested; warn if setting global preferences
- Use `private:` for encapsulating internal helpers and sensitive values
- Respect module boundaries; use `Export-ModuleMember` intentionally

### Scoped Patterns

```powershell
function Get-Timestamp {
    $timeStamp = Get-Date -Format 'yyMM.dd.HH00'
    return $timeStamp
}

function Set-GlobalPreference {
    param ([ValidateSet('SilentlyContinue','Stop','Continue','Inquire','Break')][string]$Level)
    $global:InformationPreference = $Level
    Write-Information -MessageData "INFORMATION: Set global InformationPreference to $Level"
}
```

## Behavior-Driven Development (BDD) with Gherkin

Use Cucumber-style BDD to describe behavior in `.feature` files and implement PowerShell step definitions for testable automation.

### Folder Structure

```
project/
├── source/         # Scripts and modules
├── features/       # Gherkin .feature files
├── steps/          # Step definitions (PowerShell)
├── results/        # Test output and logs
└── README.md       # Project overview
```

### Feature Example

```gherkin
Feature: Disk Provisioning

  Scenario: Provision a new volume
    Given a disk is available and uninitialized
    When I assign the label "DataVolume" and drive letter "R"
    Then the volume should be formatted and mounted as R:\ with label "DataVolume"
```

### Step Definition Pattern

```powershell
function Given-A-Disk-Is-Available-And-Uninitialized { }

function When-I-Assign-The-Label-And-DriveLetter {
    param (
        [string]$Label,
        [string]$DriveLetter
    )
}

function Then-The-Volume-Should-Be-Formatted-And-Mounted {
    param (
        [string]$DriveLetter,
        [string]$Label
    )
}
```

## Pester 5 Best Practices

- Use `Describe` for logical grouping; `Context` for scenarios
- Isolate setup/teardown with `BeforeEach` and `AfterEach`
- Mock external dependencies to isolate unit logic
- Parameterize with `TestCases` for wider coverage
- Log results to `results/` for CI integration
- Tag tests for selective runs (e.g., `Invoke-Pester -Tag 'critical'`)

## Documentation with PSDocs and Microsoft.PowerShell.PlatyPS

- Use Microsoft.PowerShell.PlatyPS for cmdlet/module help; PSDocs for project-level documentation
- Keep generated help in `documentation/` and version in source control
- Documentation shall be in Markdown format
- YAML headers are supported and encouraged for metadata
- Diagrams shall be created using Mermaid syntax

### VS Code Extensions for Documentation

Required VS Code extensions for enhanced Markdown and Mermaid support:

```powershell
code --install-extension 'bierner.markdown-preview-github-styles'
code --install-extension 'bierner.markdown-emoji'
code --install-extension 'bierner.markdown-checkbox'
code --install-extension 'bierner.markdown-yaml-preamble'
code --install-extension 'bierner.markdown-footnotes'
code --install-extension 'vstirbu.vscode-mermaid-preview'
```

### VS Code Extensions for Testing

Required VS Code extensions for Pester and Gherkin/Cucumber support:

```powershell
code --install-extension 'pspester.pester-test'
code --install-extension 'alexkrechik.cucumberautocomplete'
```

### VS Code Extensions for Git

Required VS Code extensions for Git file management:

```powershell
code --install-extension 'codezombiech.gitignore'
code --install-extension 'EditorConfig.EditorConfig'
```
code --install-extension 'bierner.markdown-footnotes'
code --install-extension 'vstirbu.vscode-mermaid-preview'
```

### Documentation Workflows

```powershell
# Microsoft.PowerShell.PlatyPS
New-MarkdownHelp -Module MyModule -OutputFolder ./documentation/PlatyPS
Update-MarkdownHelp -Path ./documentation/PlatyPS
ConvertFrom-MarkdownHelp -Path ./documentation/PlatyPS -Module MyModule

# PSDocs
Invoke-PSDocs -Path ./source -OutputPath ./documentation/PSDocs
```

## Full Example: End-to-End Cmdlet

```powershell
function New-Resource {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateSet('Development', 'Production')]
        [string]$Environment = 'Development',

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-Verbose -Message "Starting resource creation process"
    }

    process {
        try {
            if ($Force -or $PSCmdlet.ShouldProcess($Name, "Create new resource")) {
                $resource = [PSCustomObject]@{
                    Name = $Name
                    Environment = $Environment
                    Created = Get-Date
                }
                Write-Output $resource
            }
        }
        catch {
            Write-Error -Message "Failed to create resource: $($PSItem)"
        }
    }

    end {
        Write-Verbose -Message "Completed resource creation process"
    }
    clean {
        Remove-Variable -Name 'resource' -ErrorAction SilentlyContinue
    }
}
```

## Copilot-Specific Guidance (Prompting and Review)

### Effective Prompting

- **Clear Context:** Provide function-level comments describing goal, inputs, and constraints before asking Copilot to generate code
- **Comprehensive Request:** Ask Copilot to include comment-based help, parameter validation, and minimal Pester test
- **Specific Requirements:** Be explicit about platform requirements, version constraints, and security needs
- **Iterative Refinement:** When requesting changes, be specific (e.g., "Make this function support ValueFromPipelineByPropertyName and add -PassThru")

### Review Guidelines

- **Always Review:** Never blindly accept Copilot output; verify all suggestions
- **Security Check:** Verify no secrets are embedded and proper credential handling is used
- **Standards Compliance:** Confirm use of approved verbs, proper naming conventions, and validation
- **Testing:** Ensure generated tests actually test the intended behavior
- **Documentation:** Verify comment-based help is accurate and complete

### Windows/PowerShell Environment

This is a Windows environment with PowerShell - use proper PowerShell cmdlets and commands, not Linux/bash equivalents:

- Use `Get-Content` instead of `cat`
- Use `Get-ChildItem` instead of `ls -la`
- Use `New-Item -ItemType Directory -Force` instead of `mkdir -p`
- Use `Remove-Item -Recurse -Force` instead of `rm -rf`
- Use `Set-Content` instead of output redirection for file writing
- Use `Copy-Item` instead of `cp`
- Use `Move-Item` instead of `mv`
- Use `Test-Path` instead of checking file existence with brackets

### Common Pitfalls to Avoid

- **Aliases in Scripts:** Never use aliases (gci, ?, %, select, etc.) in script files
- **Write-Host Abuse:** Do not use Write-Host for data output or pipeline operations
- **Array Concatenation:** Avoid `+=` in loops with large datasets
- **Hardcoded Paths:** Use `$PSScriptRoot` for relative paths
- **Missing Validation:** Always validate user input, especially paths and credentials
- **Invoke-Expression:** Never use with untrusted input
- **Unstructured Output:** Return objects, not formatted strings

## Examples (Minimal Patterns)

### 1. Advanced Function Template

```powershell
function Get-ExampleData {
    <#
    .SYNOPSIS
        Get example data demonstrating approved patterns

    .DESCRIPTION
        Retrieves example data with proper parameter validation,
        pipeline support, and ShouldProcess implementation.

    .PARAMETER Name
        The name of the resource to retrieve

    .PARAMETER Environment
        The environment context (Development, Test, or Production)

    .PARAMETER PassThru
        Return the retrieved object

    .PARAMETER Force
        Bypass confirmation prompts

    .EXAMPLE
        Get-ExampleData -Name 'Resource1' -Environment 'Development'
        Retrieves example data for Resource1 in Development environment

    .EXAMPLE
        'Resource1', 'Resource2' | Get-ExampleData -PassThru -Force
        Retrieves data for multiple resources via pipeline without confirmation

    .OUTPUTS
        PSCustomObject with Name, Environment, and RetrievedAt properties

    .NOTES
        Something relavent that is NOT included in PSScriptInfo
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateSet('Development','Test','Production')]
        [string]$Environment = 'Development',

        [Parameter()]
        [switch]$PassThru,

        [Parameter()]
        [switch]$Force
    )    begin {
        Write-Verbose -Message "Starting example data retrieval"
        $timestamp = Get-Date -Format 'yyMMdd_HHmm'
    }

    process {
        if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Retrieve example data')) {
            $result = [PSCustomObject]@{
                PSTypeName = 'CustomModule.ExampleData'
                Name = $Name
                Environment = $Environment
                RetrievedAt = $timestamp
            }

            Write-Information -MessageData "Retrieved data for: $Name"

            if ($PassThru) {
                Write-Output $result
            }
        }
    }    end {
        Write-Verbose -Message "Completed example data retrieval"
    }
    clean {
        Remove-Variable -Name 'timestamp' -ErrorAction SilentlyContinue
        Remove-Variable -Name 'result' -ErrorAction SilentlyContinue
    }
}
```

### 2. Action Cmdlet with Error Handling

```powershell
function Set-ResourceConfiguration {
    <#
    .SYNOPSIS
        Configure a resource with validation and error handling

    .DESCRIPTION
        Updates resource configuration with comprehensive error handling,
        validation, and proper use of ShouldProcess.

    .PARAMETER Name
        The resource name to configure

    .PARAMETER ConfigValue
        The configuration value to set

    .PARAMETER Force
        Bypass confirmation prompts

    .PARAMETER PassThru
        Return the configured resource object

    .EXAMPLE
        Set-ResourceConfiguration -Name 'MyResource' -ConfigurationValue 'NewValue' -PassThru

    .NOTES
        Something relavent that is NOT included in PSScriptInfo
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z0-9-_]+$')]
        [string]$ConfigurationValue,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $correlationId = [guid]::NewGuid()
        Write-Verbose -Message "[Set-ResourceConfiguration] Starting configuration update (CorrelationId: $correlationId)"
    }

    process {
        try {
            if ($Force -or $PSCmdlet.ShouldProcess($Name, "Set configuration to '$ConfigurationValue'")) {
                Write-Verbose -Message "[Set-ResourceConfiguration] Configuring resource: $Name"

                # Perform configuration operation
                $resource = [PSCustomObject]@{
                    Name = $Name
                    ConfigurationValue = $ConfigurationValue
                    LastModified = Get-Date
                    CorrelationId = $correlationId
                }

                Write-Information -MessageData "[Set-ResourceConfiguration] Configured resource: $Name"

                if ($PassThru) {
                    Write-Output -InputObject $resource
                }
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Error "[Set-ResourceConfiguration] Access denied for '$Name'. CorrelationId: $correlationId" -ErrorAction Stop
        }
        catch {
            Write-Error "[Set-ResourceConfiguration] Failed to configure '$Name': $($PSItem.Exception.Message). CorrelationId: $correlationId"
            throw
        }
    }

    end {
        Write-Verbose -Message "[Set-ResourceConfiguration] Configuration update completed"
    }
    clean {
        Remove-Variable -Name 'correlationId' -ErrorAction SilentlyContinue
        Remove-Variable -Name 'resource' -ErrorAction SilentlyContinue
    }
}
```

### 3. Query Cmdlet with Pipeline Support

```powershell
function Get-UserProfile {
    <#
    .SYNOPSIS
        Retrieve user profile information

    .DESCRIPTION
        Gets detailed user profile information with support for
        multiple profile types and pipeline input.

    .PARAMETER Username
        The username to retrieve profile for

    .PARAMETER ProfileType
        The type of profile information to retrieve

    .EXAMPLE
        Get-UserProfile -Username 'jdoe' -ProfileType 'Detailed'

    .EXAMPLE
        'jdoe', 'asmith' | Get-UserProfile

    .OUTPUTS
        PSCustomObject with user profile information

    .NOTES
        Something relavent that is NOT included in PSScriptInfo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter()]
        [ValidateSet('Basic', 'Detailed', 'Full')]
        [string]$ProfileType = 'Basic'
    )

    begin {
        Write-Verbose -Message "[Get-UserProfile] Starting user profile retrieval"
    }

    process {
        Write-Verbose -Message "[Get-UserProfile] Processing user: $Username"
        try {
            # Retrieve profile data
            $profile = [PSCustomObject]@{
                PSTypeName = 'UserManagement.UserProfile'
                Username = $Username
                ProfileType = $ProfileType
                RetrievedAt = Get-Date
                Domain = $env:USERDOMAIN
            }

            Write-Output $profile
        }
        catch {
            Write-Error "[Get-UserProfile] Failed to retrieve profile for '$Username': $($PSItem.Exception.Message)"
        }
    }

    end {
        Write-Verbose -Message "[Get-UserProfile] User profile retrieval completed"
    }
    clean {
        Remove-Variable -Name 'profile' -ErrorAction SilentlyContinue
    }
}
```

## Deliverables and verification checklist

- Generated functions include comment-based help, validation, and follow naming conventions.
- A minimal Pester test accompanies each new public function.
- Scripts pass Invoke-ScriptAnalyzer and basic smoke tests.
- Documentation and Specification files are updated accordingly.

## Additional notes

- Keep guidance concise and pragmatic. Prefer concrete code examples over abstract rules when possible.
- Regularly review and update this guidance as PowerShell best practices evolve.
````
