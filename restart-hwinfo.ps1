param (
    [switch]$InstallTask
)

# Determine the script directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = Split-Path -Path $scriptPath -Parent

# Define log file path
$logDirectory = Join-Path -Path $scriptDirectory -ChildPath "logs"
$logFilePath = Join-Path -Path $logDirectory -ChildPath "$($MyInvocation.MyCommand.Name)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Function to write log messages
function Write-Log {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-content -Path $logFilePath -Value "[$timestamp] $Message"
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
        Write-Log -Message "Task '$taskName' already exists. Deleting and recreating."
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    $action = New-ScheduledTaskAction -Execute $executablePath -Argument  $arguments

    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 1)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

    try {
        Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName $taskName -Description $taskDescription -Force
        Write-Log -Message "Scheduled task '$taskName' has been created."
    } catch {
        Write-Log -Message "Failed to register task '$taskName': $_"
    }
}

# Function to start the scheduled task by name
function Start-ScheduledTaskByName {
    param(
        [string]$taskName
    )
    Write-Log -Message "Starting scheduled task: $taskName"
    Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
}

# Create logs directory if it doesn't exist
if (-not (Test-Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

# Install or update the scheduled tasks if the InstallTask switch is provided
if ($InstallTask) {
    Install-ScheduledTask -taskName "restart-hwinfo" -taskDescription "Restart HWiNFO via scheduled task" -executablePath "powershell.exe" -arguments "-ExecutionPolicy Bypass -File `"$scriptPath`" -NoProfile"
    Write-Output "Scheduled tasks 'restart-hwinfo' and 'hwinfo' have been created."
} else {
    # Start the scheduled task "hwinfo"
    Start-ScheduledTaskByName -taskName "hwinfo"
}
