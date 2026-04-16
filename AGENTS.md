# Copilot Instructions

Use [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages and PR titles (e.g. `feat:`, `fix:`, `docs:`, `chore:`).

Prefer atomic commits: one logical change per commit. When addressing PR review comments, each comment should be resolved in its own commit.

This is a demo repository. Demo-oriented simplifications are acceptable only when they do not weaken safety or security. Always use safe defaults: never include secrets or PII, never disable or bypass authentication, authorization, validation, or encryption, and never suggest insecure configurations. Limit demo shortcuts to non-safety-critical simplifications (for example, simplified logic or clearly marked hardcoded sample values). When such a shortcut is taken, add a comment noting the shortcut and warn the user that it is not suitable for production use.

# PowerShell Coding Conventions

Follow these conventions when generating or modifying PowerShell code.

## Script-Level Structure

Scripts follow this top-down layout:

1. `[CmdletBinding()]` (if applicable)
2. Comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.LINK`)
3. `Param` block (if applicable, with `HelpMessage` on mandatory parameters, `ValidateSet`/`ValidateScript` for input validation)
4. Variables section — all configuration variables grouped by category with comment headers (e.g. `#Mail related variables`, `#vCenter related`), indented under their category
5. `DO NOT EDIT BELOW THIS LINE` — a hash-line barrier separating config from implementation
6. Stopwatch initialization — `$ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()`
7. Numbered parts — implementation split into labeled sections (Preparations, Part 1, Part 2, etc.)

## Observability Rule

Use `Write-Verbose` liberally: include a message before attempting an action and after successful completion. Add an inline comment if the intent isn't obvious. Use `Write-Progress` for loops and long-running operations where percentage completion is meaningful — not on every individual action line.

## Comment-Based Help

Use `<#` ... `#>` block comments with `.SYNOPSIS`, `.DESCRIPTION`, and `.LINK` as minimum fields. For functions, add `.PARAMETER` and `.EXAMPLE` entries. Place help at the top of scripts and at the beginning of function bodies (immediately after the opening brace).

## Section Headers

Use `########` hash-line dividers with centered titles and part numbering (e.g. `Part 1 - Gathering data`). Use `#region` / `#endregion` blocks for collapsible sections in longer scripts.

## Variable Naming and Declaration

- **PascalCase** for all variables: `$MailRecipient`, `$VeeamServer`, `$ElapsedTime`
- Declare all configuration variables at the top of the script, before the `DO NOT EDIT` barrier
- Group variables by category with inline comment headers

## Error Handling

- Wrap each critical operation in its own `try`/`catch` — do not group multiple operations in a single block. Each `try`/`catch` should target one logical action (e.g. one cmdlet call, one external tool invocation) so the `catch` message pinpoints exactly what failed
- Inside `catch` blocks, use `Write-Verbose` describing the failure context, then `throw` to re-throw the original exception. Do not use `$error[0]` inside `catch` — the caught exception is already in `$_`
- Prefer `throw` for errors in functions, modules, and dot-sourced scripts so callers can handle failures. Restrict `Write-Error` with `exit` to top-level script entrypoints only when an explicit process exit code is required
- Use `-ErrorAction Stop` on critical cmdlets so they produce terminating errors caught by `try`/`catch`
- Use `-ErrorAction SilentlyContinue` for non-blocking operations like `Write-Progress`

## Progress Tracking

- Use `Write-Progress` with `-Id` for hierarchical progress and `-ParentId` for nested loops
- Calculate percentage as `($Progress / $Total.Count * 100)` with a `$Progress` counter incremented at the end of each iteration
- Always add `-ErrorAction SilentlyContinue` to `Write-Progress` calls
- Complete progress bars with `-Completed` when done

## Function Conventions

- Use `[CmdletBinding()]` and typed `Param()` blocks
- Support pipeline input with `ValueFromPipeline` and `ValueFromPipelineByPropertyName`
- Structure with `BEGIN`, `PROCESS`, `END` blocks when supporting pipeline input
- Follow **Verb-Noun** naming with approved PowerShell verbs: `Enable-VeeamBackup`, `Get-EmailAddress`, `Invoke-SonusRestCall`

## Brace Style

Opening brace on the **same line** as the statement (K&R style). Closing brace on its own line at the indentation level of the parent statement. Use **4-space indentation**.

## Collections and Object Creation

Prefer capturing output directly from loops: `$Collection = foreach ($Item in $Items) { $Item }`. For imperative building, use `[System.Collections.Generic.List[object]]::new()` with `.Add()`. Avoid `$collection = @()` with `+= $object` as it creates a new array each iteration with O(n²) performance.

Create custom objects with `[PSCustomObject]@{ Name = Value }` syntax. Avoid the legacy `New-Object PSObject` / `Add-Member` pattern.

## Calculated Properties

Use `Select-Object` with `@{Name="PropertyName";Expression={...}}` hashtable syntax for computed properties.

## String Interpolation

Use `$()` subexpressions for property access and method calls inside double-quoted strings: `"Connected to $($Server.Name)"`.

## Pipeline and Filtering

- Use `foreach` statement for iterating known collections
- Use `ForEach-Object` when chaining from cmdlet output in a pipeline
- Use `Where-Object` for filtering

## Credential Handling

Prefer managed identities for Azure automation. Otherwise, prefer a proper secret store such as Azure Key Vault or PowerShell SecretManagement. If a persisted credential is unavoidable, document the exact pattern (`ConvertTo-SecureString` to create a `SecureString`, then `ConvertFrom-SecureString` or `Export-Clixml` to persist it) and note that the default protection is typically Windows/user-scoped and not portable across users or machines. Avoid plaintext passwords in production scripts.

## Rounding and Math

Use `[math]::Round()` with explicit decimal places.
