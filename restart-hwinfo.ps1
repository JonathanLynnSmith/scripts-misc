param (
    [switch]$InstallTask
)

# Determine the script directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = Split-Path -Path $scriptPath -Parent

# Function to kill the process by name
function Kill-ProcessByName {
    param(
        [string]$processName
    )
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Output "Stopping process: $($process.Name) (PID: $($process.Id))"
        $process | Stop-Process -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "Process $processName is not running."
    }
}

# Function to create or update the scheduled task
function Install-ScheduledTask {
    param(
        [string]$taskName,
        [string]$taskDescription,
        [string]$executablePath,
        [string]$arguments = ""
    )

    # Check if the task already exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    $action = New-ScheduledTaskAction -Execute $executablePath -Argument $arguments

    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 1)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

    try {
        Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName $taskName -Description $taskDescription -Force
        Write-Output "Scheduled task '$taskName' has been created."
    } catch {
        Write-Output "Failed to register task '$taskName': $_"
    }
}

# Function to start the scheduled task by name
function Start-ScheduledTaskByName {
    param(
        [string]$taskName
    )
    Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
}

# Install or update the scheduled tasks if the InstallTask switch is provided
if ($InstallTask) {
    # Kill the process before installing the task
    Kill-ProcessByName -processName "hwinfo64.exe"

    # Install the scheduled task
    Install-ScheduledTask -taskName "restart-hwinfo" -taskDescription "Restart HWiNFO via scheduled task" -executablePath "powershell.exe" -arguments "-ExecutionPolicy Bypass -File `"$scriptPath`" -NoProfile"
    Write-Output "Scheduled task 'restart-hwinfo' has been created."
} else {
    # Kill the process before starting the task
    Kill-ProcessByName -processName "hwinfo64"
    # Start-Sleep 3
    # Start the scheduled task "hwinfo"
    Start-ScheduledTaskByName -taskName "hwinfo"
}
