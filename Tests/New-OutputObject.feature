Feature: New-OutputObject
    As a PowerShell user
    I want to easily generate standardized output file and folder paths
    So that I can maintain consistent naming conventions for reports and logs

    Background:
        Given the module "New-OutputObject" is imported

    Scenario: Create a default output file object
        When I call New-OutputFile
        Then the result should contain a property "OutputFilePath"
        And the result property "ExitCode" should be 0
        And the result property "ExitCodeDescription" should be "Everything is fine :-)"

    Scenario: Create an output file with specific name parts
        When I call New-OutputFile with keys:
            | Key                  | Value        |
            | OutputFileNamePrefix | Messages     |
            | OutputFileNameStem   | MyServer     |
            | OutputFileNameSuffix | Log          |
        Then the "OutputFilePath" name should start with "Messages-MyServer"
        And the "OutputFilePath" name should end with "-Log.txt"
        And the result property "ExitCode" should be 0

    Scenario: Create an output folder
        When I call New-OutputFolder with keys:
            | Key                         | Value      |
            | OutputFolderNamePrefix      | Reports    |
            | OutputFolderNameStem        | Weekly     |
        Then the result should contain a property "OutputFolderPath"
        And the "OutputFolderPath" name should start with "Reports-Weekly"
        And the result property "ExitCode" should be 0

    Scenario: Handle non-existent parent path
        Given a path "C:\NonExistentPath\XYZ" that does not exist
        When I call New-OutputFile with keys:
            | Key        | Value                  |
            | ParentPath | C:\NonExistentPath\XYZ |
        Then the result property "ExitCode" should be 1
        And the result property "ExitCodeDescription" should match "Provided parent path .* doesn't exist"

    Scenario: Handle duplicate file decision - Overwrite
        Given a file exists at "TestDrive:\Duplicate.txt"
        When I call New-OutputFile with keys:
            | Key                  | Value         |
            | OutputFileNamePrefix | Duplicate     |
            | IncludeDateTimePartInOutputFileName | false |
            | ParentPath           | TestDrive:\   |
            | OutputFileNameExtension | txt        |
        # Assuming mock user input or force strategy for overwriting
        Then the result should be valid

    Scenario: Validate date time formatting
        When I call New-OutputFile with keys:
            | Key                | Value           |
            | DateTimePartFormat | yyyyMMdd-HHmmss |
        Then the "OutputFilePath" name should match pattern "\d{8}-\d{6}"
