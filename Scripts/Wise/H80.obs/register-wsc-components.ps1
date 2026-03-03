# register-wsc-components.ps1
# WSC Component Registration Manager for MAST Observatory
# Handles cleanup and registration of multiple .wsc files

param(
    [Parameter(Mandatory=$false)]
    [string]$WscDirectory = $PSScriptRoot,

    [Parameter(Mandatory=$false)]
    [switch]$Unregister,

    [Parameter(Mandatory=$false)]
    [string]$SingleFile
)

# Validate WscDirectory early
if ([string]::IsNullOrWhiteSpace($WscDirectory)) {
    Write-Host "ERROR: WscDirectory is empty or invalid!" -ForegroundColor Red
    Write-Host "Please specify -WscDirectory parameter or run from script location." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $WscDirectory)) {
    Write-Host "ERROR: WscDirectory does not exist: $WscDirectory" -ForegroundColor Red
    exit 1
}

# Check for administrator privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Re-launch as administrator if needed
if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Attempting to restart with elevation...`n" -ForegroundColor Yellow

    # Build argument string for re-launch
    $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($WscDirectory -ne $PSScriptRoot) {
        $arguments += " -WscDirectory `"$WscDirectory`""
    }
    if ($Unregister) {
        $arguments += " -Unregister"
    }
    if ($SingleFile) {
        $arguments += " -SingleFile `"$SingleFile`""
    }

    try {
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
        exit $LASTEXITCODE
    }
    catch {
        Write-Host "`nFailed to elevate privileges." -ForegroundColor Red
        Write-Host "Please run this script as Administrator manually." -ForegroundColor Yellow
        Write-Host "`nPress any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# List of WSC files to manage (ORDER MATTERS - dependencies first!)
# Format: Either filename (in $WscDirectory) or full path
$wscFiles = @(
    # Parent directory dependency
    (Join-Path (Split-Path $WscDirectory -Parent) "Wise.Util.wsc"),
    # Local files
    "Wise.H80.FlipMirror.wsc",
    "Wise.H80.wsc",
    "UserActions.wsc"
)

function Remove-ProgIdFromRegistry {
    param([string]$ProgId)

    Write-Host "  Cleaning ProgID: $ProgId" -ForegroundColor Yellow

    # Remove main ProgID entry
    $paths = @(
        "Registry::HKEY_CLASSES_ROOT\$ProgId",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\$ProgId",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\$ProgId"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    Removed: $path" -ForegroundColor DarkGray
        }
    }

    # Remove CLSIDs that reference this ProgID (32-bit)
    $clsidPaths = @(
        "Registry::HKEY_CLASSES_ROOT\CLSID",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID"
    )

    foreach ($clsidPath in $clsidPaths) {
        if (Test-Path $clsidPath) {
            Get-ChildItem -Path $clsidPath -ErrorAction SilentlyContinue | ForEach-Object {
                $progIdValue = Get-ItemProperty -Path $_.PSPath -Name "ProgID" -ErrorAction SilentlyContinue
                if ($progIdValue.ProgID -eq $ProgId) {
                    Write-Host "    Removing CLSID: $($_.PSChildName)" -ForegroundColor DarkGray
                    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    # Remove CLSIDs from Wow6432Node (64-bit system, 32-bit apps)
    $wow64Paths = @(
        "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID"
    )

    foreach ($wow64Path in $wow64Paths) {
        if (Test-Path $wow64Path) {
            Get-ChildItem -Path $wow64Path -ErrorAction SilentlyContinue | ForEach-Object {
                $progIdValue = Get-ItemProperty -Path $_.PSPath -Name "ProgID" -ErrorAction SilentlyContinue
                if ($progIdValue.ProgID -eq $ProgId) {
                    Write-Host "    Removing Wow6432Node CLSID: $($_.PSChildName)" -ForegroundColor DarkGray
                    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function Register-WscComponent {
    param(
        [string]$FilePath,
        [string]$ProgId
    )

    # Validate inputs
    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        Write-Host "  ERROR: FilePath parameter is empty!" -ForegroundColor Red
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($ProgId)) {
        Write-Host "  ERROR: ProgId parameter is empty!" -ForegroundColor Red
        return $false
    }

    Write-Host "`nProcessing: $ProgId" -ForegroundColor Cyan
    Write-Host "  File: $FilePath" -ForegroundColor Gray

    if (-not (Test-Path $FilePath)) {
        Write-Host "  ERROR: File not found!" -ForegroundColor Red
        return $false
    }

    # Determine correct regsvr32 path (32-bit for WSC files)
    $regsvr32Path = "$env:SystemRoot\SysWoW64\regsvr32.exe"
    if (-not (Test-Path $regsvr32Path)) {
        $regsvr32Path = "$env:SystemRoot\System32\regsvr32.exe"
    }

    # Unregister first (suppress errors)
    Write-Host "  Unregistering..." -ForegroundColor Yellow
    $unregProcess = Start-Process -FilePath $regsvr32Path -ArgumentList @("/u", "/s", $FilePath) -Wait -PassThru -NoNewWindow
    
    # Clean registry
    Remove-ProgIdFromRegistry -ProgId $ProgId

    if (-not $Unregister) {
        # Register
        Write-Host "  Registering..." -ForegroundColor Green
        $regProcess = Start-Process -FilePath $regsvr32Path -ArgumentList @("/s", $FilePath) -Wait -PassThru -NoNewWindow

        if ($regProcess.ExitCode -eq 0) {
            Write-Host "  SUCCESS: Registered $ProgId" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ERROR: Registration failed (Exit code: $($regProcess.ExitCode))" -ForegroundColor Red
            
            # Try without /s to see actual error
            Write-Host "  Attempting registration without silent mode for error details..." -ForegroundColor Yellow
            $regProcessVerbose = Start-Process -FilePath $regsvr32Path -ArgumentList @($FilePath) -Wait -PassThru
            
            return $false
        }
    } else {
        Write-Host "  SUCCESS: Unregistered $ProgId" -ForegroundColor Green
        return $true
    }
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WSC Component Registration Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running as Administrator: YES" -ForegroundColor Green
Write-Host "Directory: $WscDirectory`n" -ForegroundColor Gray

$success = 0
$failed = 0

if ($SingleFile) {
    # Process single file
    $progId = [System.IO.Path]::GetFileNameWithoutExtension($SingleFile)
    $filePath = Join-Path $WscDirectory $SingleFile

    if (Register-WscComponent -FilePath $filePath -ProgId $progId) {
        $success++
    } else {
        $failed++
    }
} else {
    # Process all files
    foreach ($wscFile in $wscFiles) {
        # Handle both relative and absolute paths
        if ([System.IO.Path]::IsPathRooted($wscFile)) {
            $filePath = $wscFile
        } else {
            $filePath = Join-Path $WscDirectory $wscFile
        }
        
        $progId = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

        if (Register-WscComponent -FilePath $filePath -ProgId $progId) {
            $success++
        } else {
            $failed++
        }
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successful: $success" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Gray" })

if ($failed -gt 0) {
    exit 1
}
exit 0