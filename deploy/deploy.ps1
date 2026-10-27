<#
.SYNOPSIS
    Put this repository's ACP files onto this machine's live ACP folders, as the deploy manifests say.

.DESCRIPTION
    Reads deploy\manifest-common.txt plus deploy\manifest-<observatory>.txt (format: deploy\README.txt).

    It acts ONLY on live files that are missing or differ from the repository's (compared by SHA256 of
    the bytes).  Files that are already identical are not copied, not backed up and not re-registered.
    Without -Apply it is a dry run: it reports and changes nothing.

    With -Apply, in this order:
      1. refuses if ACP, wscript or cscript is running (override: -ForceRunning), if it is not elevated,
         or if a file it would deploy has uncommitted changes in the repository (override: -AllowDirty);
      2. backs up each live file it is about to overwrite, under -BackupRoot\<date-time>\;
      3. copies the missing/different files;
      4. writes WiseDeployed.txt in the ACP folder: the commit and the files changed;
      5. registers (32-bit regsvr32) each .wsc that was copied and that a manifest says to register, and
         reads the registry back to confirm it.

    It never removes anything.  Files that should no longer be there (FS2_Sync.vbs, the Wise40 *.vbs on
    dome-pc) are left for a person to delete.

    Exit code: 0 done or nothing to do, 1 an error, 2 refused.

.PARAMETER Observatory
    wise40, c28 or h80.  Default: from the hostname (dome-pc, c28-pc, h80-pc).  wo-neo (c18) is not
    managed and is refused.

.PARAMETER AcpRoot
.PARAMETER SchedulerRoot
    Where {acp} and {scheduler} point.  Changing either makes the run a rehearsal: nothing is registered
    and the running-ACP and elevation checks are skipped, so it can be tried against a scratch folder.
#>
[CmdletBinding()]
param(
    [string]$Observatory,
    [switch]$Apply,
    [switch]$AllowDirty,
    [switch]$ForceRunning,
    [string]$AcpRoot       = 'C:\Program Files (x86)\ACP Obs Control',
    [string]$SchedulerRoot = 'C:\Users\Public\Documents\ACP Config\Scheduler',
    [string]$BackupRoot    = 'C:\ProgramData\AcpDeploy\backups'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$Regsvr32  = Join-Path $env:SystemRoot 'SysWOW64\regsvr32.exe'
$IsLive    = ($AcpRoot -eq 'C:\Program Files (x86)\ACP Obs Control') -and
             ($SchedulerRoot -eq 'C:\Users\Public\Documents\ACP Config\Scheduler')

function Stop-Refused([string]$Message) {
    Write-Host "REFUSED: $Message" -ForegroundColor Yellow
    exit 2
}

function Stop-Failed([string]$Message) {
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

# ---- which observatory ------------------------------------------------------------------------

$ByHost = @{ 'dome-pc' = 'wise40'; 'c28-pc' = 'c28'; 'h80-pc' = 'h80' }

if (-not $Observatory) {
    $h = $env:COMPUTERNAME.ToLower()
    if ($h -eq 'wo-neo') { Stop-Refused 'wo-neo (c18) is not managed; it stays as it is (see deploy\README.txt).' }
    if (-not $ByHost.ContainsKey($h)) { Stop-Refused "no observatory is known for host '$h'; pass -Observatory." }
    $Observatory = $ByHost[$h]
}
$Observatory = $Observatory.ToLower()
if ($Observatory -eq 'c18') { Stop-Refused 'c18 (wo-neo) is not managed; it stays as it is (see deploy\README.txt).' }
if (@('wise40', 'c28', 'h80') -notcontains $Observatory) { Stop-Refused "unknown observatory '$Observatory'." }

# ---- manifests --------------------------------------------------------------------------------

function Expand-Root([string]$Path) {
    $p = $Path.Replace('{acp}', $AcpRoot.TrimEnd('\')).Replace('{scheduler}', $SchedulerRoot.TrimEnd('\'))
    if ($p -match '\{[^}]*\}') { throw "unknown root token in '$Path'" }
    return $p
}

function Read-Manifest([string]$File) {
    $n = 0
    foreach ($line in (Get-Content -LiteralPath $File)) {
        $n++
        $text = $line.Trim()
        if ($text -eq '' -or $text.StartsWith('#')) { continue }
        $tokens = @([regex]::Matches($text, '"([^"]*)"|(\S+)') | ForEach-Object {
            if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Groups[2].Value }
        })
        New-Object PSObject -Property @{
            Verb = $tokens[0].ToLower(); Args = @($tokens | Select-Object -Skip 1); Where = "$(Split-Path -Leaf $File):$n"
        }
    }
}

$manifests = @(Join-Path $PSScriptRoot 'manifest-common.txt'; Join-Path $PSScriptRoot "manifest-$Observatory.txt")
foreach ($m in $manifests) { if (-not (Test-Path -LiteralPath $m)) { Stop-Failed "no manifest: $m" } }

$items = New-Object System.Collections.ArrayList     # files to place
$regs  = New-Object System.Collections.ArrayList     # .wsc to register, in manifest order

function Add-Item([string]$SrcFull, [string]$Dest, [string]$Where) {
    $rel = $SrcFull.Substring($RepoRoot.Length + 1).Replace('\', '/')
    [void]$items.Add((New-Object PSObject -Property @{ Src = $SrcFull; Rel = $rel; Dest = $Dest; Status = ''; Where = $Where }))
}

try {
    foreach ($m in $manifests) {
        foreach ($e in (Read-Manifest $m)) {
            switch ($e.Verb) {
                'file' {
                    if ($e.Args.Count -ne 2) { throw "$($e.Where): file needs <source> <dest>" }
                    $src  = Join-Path $RepoRoot $e.Args[0].Replace('/', '\')
                    $dest = Expand-Root $e.Args[1]
                    if ($dest.EndsWith('\')) { $dest += [IO.Path]::GetFileName($src) }
                    Add-Item $src $dest $e.Where
                }
                'tree' {
                    if ($e.Args.Count -ne 2) { throw "$($e.Where): tree needs <source> <dest>" }
                    $dir  = Join-Path $RepoRoot $e.Args[0].Replace('/', '\')
                    $dest = (Expand-Root $e.Args[1]).TrimEnd('\')
                    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { throw "$($e.Where): no folder $dir" }
                    foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -File)) {
                        Add-Item $f.FullName ($dest + '\' + $f.FullName.Substring($dir.Length).TrimStart('\')) $e.Where
                    }
                }
                'register' {
                    if ($e.Args.Count -ne 1) { throw "$($e.Where): register needs <dest>" }
                    [void]$regs.Add((New-Object PSObject -Property @{ Dest = (Expand-Root $e.Args[0]); Where = $e.Where }))
                }
                'external' { throw "$($e.Where): 'external' is not supported by this script" }
                default    { throw "$($e.Where): unknown entry '$($e.Verb)'" }
            }
        }
    }
} catch {
    Stop-Failed $_.Exception.Message
}

# ---- compare ----------------------------------------------------------------------------------

foreach ($i in $items) {
    if (-not (Test-Path -LiteralPath $i.Src -PathType Leaf)) {
        $i.Status = 'NO-SOURCE'
    } elseif (-not (Test-Path -LiteralPath $i.Dest -PathType Leaf)) {
        $i.Status = 'MISSING'
    } elseif ((Get-FileHash -LiteralPath $i.Src -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $i.Dest -Algorithm SHA256).Hash) {
        $i.Status = 'DIFFERS'
    } else {
        $i.Status = 'SAME'
    }
}

$noSource = @($items | Where-Object { $_.Status -eq 'NO-SOURCE' })
$todo     = @($items | Where-Object { $_.Status -eq 'MISSING' -or $_.Status -eq 'DIFFERS' })

$changed = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($i in $todo) { [void]$changed.Add($i.Dest) }
$allDests = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($i in $items) { [void]$allDests.Add($i.Dest) }

$toRegister = @($regs | Where-Object { $changed.Contains($_.Dest) })
$orphanRegs = @($regs | Where-Object { -not $allDests.Contains($_.Dest) })

# ---- git state of what would be deployed ------------------------------------------------------

$commit = '(not a git checkout)'; $branch = ''; $dirty = @()
try {
    $commit = (& git -C $RepoRoot rev-parse --short HEAD).Trim()
    $branch = (& git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim()
    if ($todo.Count -gt 0) {
        $dirty = @(& git -C $RepoRoot status --porcelain --untracked-files=all -- @($todo | ForEach-Object { $_.Rel }))
    }
} catch {
    Write-Host "WARNING: could not read git state ($($_.Exception.Message))" -ForegroundColor Yellow
}

# ---- report -----------------------------------------------------------------------------------

Write-Host ''
Write-Host ("Observatory {0} on {1}   repo {2} @ {3}" -f $Observatory, $env:COMPUTERNAME, $branch, $commit)
if (-not $IsLive) { Write-Host 'REHEARSAL: ACP/Scheduler roots are not the live ones; nothing will be registered.' -ForegroundColor Cyan }
Write-Host ''

foreach ($i in $items) {
    $colour = switch ($i.Status) { 'SAME' { 'DarkGray' } 'NO-SOURCE' { 'Red' } default { 'Green' } }
    Write-Host ('  {0,-9} {1}' -f $i.Status, $i.Dest) -ForegroundColor $colour
}
foreach ($r in $toRegister) { Write-Host ('  REGISTER  {0}' -f $r.Dest) -ForegroundColor Green }
foreach ($r in $orphanRegs) { Write-Host ("  WARNING   {0}: registers {1}, which no entry deploys" -f $r.Where, $r.Dest) -ForegroundColor Yellow }

$same = @($items | Where-Object { $_.Status -eq 'SAME' }).Count
Write-Host ''
Write-Host ("{0} to copy ({1} missing, {2} differ), {3} already identical, {4} to register." -f `
    $todo.Count, @($todo | Where-Object { $_.Status -eq 'MISSING' }).Count,
    @($todo | Where-Object { $_.Status -eq 'DIFFERS' }).Count, $same, $toRegister.Count)

if ($noSource.Count -gt 0) { Stop-Failed "$($noSource.Count) manifest source file(s) are not in the repository (marked NO-SOURCE)." }
if ($dirty.Count -gt 0) {
    Write-Host ''
    Write-Host 'These files to be deployed have uncommitted changes in the repository:' -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
}

if (-not $Apply) {
    Write-Host ''
    Write-Host 'DRY RUN - nothing was changed.  Re-run with -Apply to deploy.'
    exit 0
}

# ---- preconditions for -Apply -----------------------------------------------------------------

if ($todo.Count -eq 0) { Write-Host 'Nothing to do.'; exit 0 }

if ($dirty.Count -gt 0 -and -not $AllowDirty) {
    Stop-Refused 'commit (or discard) those changes first, or pass -AllowDirty.'
}

if ($IsLive) {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Stop-Refused 'run this from an elevated shell (Program Files and regsvr32 need it).'
    }
    $busy = @(Get-Process -Name acp, wscript, cscript -ErrorAction SilentlyContinue)
    if ($busy.Count -gt 0 -and -not $ForceRunning) {
        $names = ($busy | ForEach-Object { "$($_.Name) ($($_.Id))" }) -join ', '
        Stop-Refused "running: $names.  A script process cannot be told from an idle ACP, so stop ACP first, or pass -ForceRunning if you know it is idle."
    }
    if ($toRegister.Count -gt 0 -and -not (Test-Path -LiteralPath $Regsvr32)) { Stop-Failed "no $Regsvr32" }
}

# ---- do it ------------------------------------------------------------------------------------

$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $BackupRoot $stamp
$copied    = New-Object System.Collections.ArrayList

try {
    foreach ($i in ($todo | Where-Object { $_.Status -eq 'DIFFERS' })) {
        $to = Join-Path $backupDir ($i.Dest -replace '^([A-Za-z]):', '$1')
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $to) | Out-Null
        Copy-Item -LiteralPath $i.Dest -Destination $to
    }
    if (Test-Path -LiteralPath $backupDir) { Write-Host "Backed up the files being replaced to $backupDir" }

    foreach ($i in $todo) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $i.Dest) | Out-Null
        Copy-Item -LiteralPath $i.Src -Destination $i.Dest -Force
        [void]$copied.Add($i)
        Write-Host ("  copied    {0}" -f $i.Dest)
    }
} catch {
    Write-Host ("ERROR while copying: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ("{0} file(s) were copied before the error; the originals of replaced files are in {1}" -f $copied.Count, $backupDir) -ForegroundColor Red
    exit 1
}

# The marker says what is on disk, so write it as soon as the copying is done and before registering:
# a registration problem must not leave a marker that still describes the previous deploy.
$marker = Join-Path $AcpRoot 'WiseDeployed.txt'
$lines  = @(
    "commit:      $commit",
    "branch:      $branch",
    "observatory: $Observatory",
    "host:        $env:COMPUTERNAME",
    "when:        $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "backup:      $(if (Test-Path -LiteralPath $backupDir) { $backupDir } else { '(nothing was replaced)' })",
    'changed:'
) + @($copied | ForEach-Object { "  $($_.Dest)" })
Set-Content -LiteralPath $marker -Value $lines -Encoding ASCII

# regsvr32 /s is silent even when it does nothing, so read the registry back.  A CLSID's ScriptletURL is a
# subkey whose default value is the file's URL, with spaces escaped (%20), in the 32-bit view.
function Get-RegisteredPath([string]$Wsc) {
    $clsid = ([regex]::Match((Get-Content -LiteralPath $Wsc -Raw), 'classid\s*=\s*"(\{[0-9A-Fa-f-]+\})"')).Groups[1].Value
    if (-not $clsid) { return '(no classid in the file)' }
    $key = "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\$clsid\ScriptletURL"
    if (-not (Test-Path $key)) { return '(not registered)' }
    $url = [string](Get-Item $key).GetValue('')
    return [Uri]::UnescapeDataString(($url -replace '^file:///', '')).Replace('/', '\')
}

$failed = 0
if ($IsLive) {
    try {
        foreach ($r in $toRegister) {
            $p   = Start-Process -FilePath $Regsvr32 -ArgumentList '/s', ('"{0}"' -f $r.Dest) -Wait -PassThru
            $reg = Get-RegisteredPath $r.Dest
            if ($p.ExitCode -eq 0 -and $reg -ieq $r.Dest) {
                Write-Host ("  registered {0}" -f $r.Dest)
            } else {
                $failed++
                Write-Host ("  NOT CONFIRMED {0}  (regsvr32 exit {1}, registry says '{2}')" -f $r.Dest, $p.ExitCode, $reg) -ForegroundColor Red
            }
        }
    } catch {
        Write-Host ("ERROR while registering: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ("The files are copied and {0} is written, but registration did not finish." -f $marker) -ForegroundColor Red
        exit 1
    }
}

Write-Host ''
if ($failed -gt 0) {
    Write-Host ("Copied {0} file(s), but {1} registration(s) were not confirmed." -f $copied.Count, $failed) -ForegroundColor Red
    exit 1
}
Write-Host ("Deployed {0} file(s); marker written to {1}" -f $copied.Count, $marker)
exit 0
