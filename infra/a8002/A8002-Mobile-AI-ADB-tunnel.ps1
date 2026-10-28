[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$adbPath = 'E:\tools\android\platform-tools\adb.exe'
$sshPath = 'C:\Windows\System32\OpenSSH\ssh.exe'
$sshTarget = 'A8002-sbw_mobile_ai_dev_a2'
$remotePort = 5038
$retrySeconds = 10
$logDirectory = Join-Path $env:USERPROFILE '.ssh\logs'
$logPath = Join-Path $logDirectory 'A8002-Mobile-AI-ADB-tunnel.log'

New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

function Write-TunnelLog {
    param([string]$Message)
    $line = '{0:o} {1}' -f (Get-Date), $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Get-ActiveAdbPort {
    foreach ($port in @(5038, 5037)) {
        $output = & $adbPath -P $port devices 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $output -match '(?m)^\S+\s+device(?:\s|$)') {
            return $port
        }
    }
    return $null
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\A8002MobileAIAdbTunnel', [ref]$createdNew)
if (-not $createdNew) {
    exit 0
}

$sshProcess = $null
$forwardedPort = $null
try {
    Write-TunnelLog 'watchdog started'
    while ($true) {
        $activePort = Get-ActiveAdbPort
        $running = $null -ne $sshProcess -and -not $sshProcess.HasExited
        if ($null -eq $activePort) {
            if ($running) {
                Stop-Process -Id $sshProcess.Id -Force
                $sshProcess.WaitForExit()
                Write-TunnelLog 'tunnel stopped because no authorized adb device was present'
            }
            $sshProcess = $null
            $forwardedPort = $null
            Start-Sleep -Seconds $retrySeconds
            continue
        }

        if ($running -and $forwardedPort -ne $activePort) {
            Stop-Process -Id $sshProcess.Id -Force
            $sshProcess.WaitForExit()
            Write-TunnelLog "tunnel restarted because adb moved from $forwardedPort to $activePort"
            $sshProcess = $null
        }

        if ($null -eq $sshProcess -or $sshProcess.HasExited) {
            $arguments = @(
                '-N', '-T',
                '-o', 'BatchMode=yes',
                '-o', 'ExitOnForwardFailure=yes',
                '-o', 'ServerAliveInterval=30',
                '-o', 'ServerAliveCountMax=3',
                '-R', "127.0.0.1:${remotePort}:127.0.0.1:${activePort}",
                $sshTarget
            )
            $sshProcess = Start-Process -FilePath $sshPath -ArgumentList $arguments -WindowStyle Hidden -PassThru
            $forwardedPort = $activePort
            Write-TunnelLog "tunnel process $($sshProcess.Id) started: Windows adb $activePort -> container loopback $remotePort"
            Start-Sleep -Seconds 3
            if ($sshProcess.HasExited) {
                Write-TunnelLog "tunnel process exited with code $($sshProcess.ExitCode); retrying"
            }
        }
        Start-Sleep -Seconds $retrySeconds
    }
}
finally {
    if ($null -ne $sshProcess -and -not $sshProcess.HasExited) {
        Stop-Process -Id $sshProcess.Id -Force
    }
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}


