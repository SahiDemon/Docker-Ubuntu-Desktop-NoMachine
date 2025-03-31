$ErrorActionPreference = 'Stop'

# Configuration
$ngrokToken = "2UnatP7VbgJIoyS3gtu50XxVOoe_48TKQZ4J5aKKcZWT4iu3T"
$ngrokRegion = "ap"
$noMachineUrl = "https://download.nomachine.com/download/8.9/Windows/nomachine_8.9.1_4_x64.exe"
$nxsPath = "$env:USERPROFILE\Documents\vm.nxs"

# Function to check if NoMachine is installed
function Test-NoMachineInstalled {
    return Test-Path "C:\Program Files\NoMachine\bin\nxplayer.exe"
}

# Function to download and install NoMachine
function Install-NoMachine {
    Write-Host "Downloading NoMachine..."
    $installer = "$env:TEMP\nomachine_installer.exe"
    Invoke-WebRequest -Uri $noMachineUrl -OutFile $installer
    
    Write-Host "Installing NoMachine..."
    Start-Process -FilePath $installer -ArgumentList "/verysilent" -Wait
    Remove-Item $installer
}

# Function to update NXS file with new connection details
function Update-NxsFile {
    param (
        [string]$ngrokUrl,
        [string]$username,
        [string]$password
    )
    
    [xml]$nxsContent = Get-Content $nxsPath
    $nxsContent.NXClientSettings.group | Where-Object { $_.name -eq "General" } | ForEach-Object {
        $_.option | Where-Object { $_.key -eq "Server host" } | ForEach-Object {
            $_.value = $ngrokUrl
        }
    }
    
    $nxsContent.NXClientSettings.group | Where-Object { $_.name -eq "Login" } | ForEach-Object {
        $_.option | Where-Object { $_.key -eq "User" } | ForEach-Object {
            $_.value = $username
        }
        $_.option | Where-Object { $_.key -eq "Auth" } | ForEach-Object {
            $_.value = $password
        }
    }
    
    $nxsContent.Save($nxsPath)
}

# Main execution
try {
    # Check and install NoMachine if needed
    if (-not (Test-NoMachineInstalled)) {
        Write-Host "NoMachine not found. Installing..."
        Install-NoMachine
    }

    # Run gcloud command and capture output
    Write-Host "Connecting to Cloud Shell..."
    $cloudShellOutput = gcloud alpha cloud-shell ssh --authorize-session --command "curl -sLk https://your-script-url.sh | bash"
    
    # Extract connection details from output (you'll need to adjust this based on your script output)
    $connectionDetails = $cloudShellOutput | ConvertFrom-Json
    
    # Update NXS file with new connection details
    Update-NxsFile -ngrokUrl $connectionDetails.host -username $connectionDetails.username -password $connectionDetails.password
    
    # Launch NoMachine with the updated configuration
    Start-Process "C:\Program Files\NoMachine\bin\nxplayer.exe" -ArgumentList $nxsPath
    
    Write-Host "Setup complete! NoMachine should now connect automatically."
} catch {
    Write-Host "An error occurred: $_"
    exit 1
} 