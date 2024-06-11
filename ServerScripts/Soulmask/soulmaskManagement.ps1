param (
    $serverRoot = "C:\servers\soulmask",
    $steamcmdPath = "C:\scripts\steamcmd",
    $csvFile = "C:\scripts\soulmask\soulmaskServers.csv",
    $appID = "3017310",
    $ipaddr = "192.168.0.16",
    $option = ""
)

$serverPath = Join-Path $serverRoot "WS\Binaries\Win64\WSServer-Win64-Shipping.exe"

if (!(Test-Path $serverPath)) {
    # Server isn't installed
    Write-Host "SETUP YOUR SERVER FIRST!!"
    exit 1
}

# Move DLLs if don't exist sigh
$win64Files = GCI "$serverRoot\WS\Binaries\Win64"
if (!($win64Files -like "*.dll")) {
    $dllToMove = gci $serverRoot | ? {$_.Name -like "*.dll"}
    Foreach ($dll in $dllToMove) {
        Copy-Item $dll.fullName -Destination "$serverRoot\WS\Binaries\Win64" -Force -Verbose
    }
}

# Make sure we have an IP to automate the MULTIHOME String. 
# You can override this by adding an ip into $ipaddr at the top parameters.
if (-not $ipaddr) {
    # Get the IP address of the first network connection
    $ipaddr = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetIPInterface -AddressFamily IPv4 | Sort-Object -Property InterfaceMetric | Select-Object -First 1 -ExpandProperty InterfaceAlias)).IPAddress
}

function Send-TelnetCommand {
    param (
        [string]$hostname = "localhost",
        [int]$port = 18888,
        [string]$command
    )

    if (-not $command) {
        Write-Error "No command provided. Please specify a command to send."
        return
    }

    try {
        # We have to create a TCP Client in order to connect into Telnet
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($hostname, $port)

        # Read the stream
        $networkStream = $tcpClient.GetStream()

        # Check if the network stream is writable
        if ($networkStream.CanWrite) {
            # Need to convert ocmmand to bytes
            $commandBytes = [System.Text.Encoding]::ASCII.GetBytes("$command`r`n")

            # This writes the bytes to the stream aka sends the command
            $networkStream.Write($commandBytes, 0, $commandBytes.Length)
            Write-Output "Sent command bytes: $([BitConverter]::ToString($commandBytes))"
            $networkStream.Flush()
            Write-Output "Command '$command' sent to $hostname on port $port"

            # While loop to read the TCP Stream. This is so we can make sure the command 
            # is executed and read outputs
            $buffer = New-Object byte[] 1024
            while ($true) {
                try {
                    $bytesRead = $networkStream.Read($buffer, 0, $buffer.Length)
                    if ($bytesRead -gt 0) {
                        $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
                        Write-Output "Received response: $response"
                    } else {
                        # Connection closed by the server
                        break
                    }
                } catch {
                    # Error here means the server closed the connection for some reason
                    break
                }
            }
        } else {
            Write-Error "Network stream is not writable."
        }
    } catch {
        Write-Error "Failed to send command '$command' to $hostname on port $port. Error: $_"
    } finally {
        # Cleanup
        if ($networkStream -ne $null) { $networkStream.Close() }
        if ($tcpClient -ne $null) { $tcpClient.Close() }
    }
}

# Function for checking update
# the first time you execute this function it will think there is
# an update. Moving forward however, you can use this to easily update your server
# it will consider the path that your script is in to be the install path
# since you should be sticking this script into the root of your game server anyway
function CheckUpdate {
    param ($serverPath,$steamcmdFolder,$serverInfo)
    $steamAppID=$appID
    # Without clearing cache app_info_update may return old informations!
    $clearCache=1
    if ($PSSCriptRoot -like "*servers\soulmask*") {
        $dataPath = join-path $PSScriptRoot "updatedata"
    } Else {
        $dataPath = Join-Path $serverPath "updatedata"
    }
    $steamcmdExec = $steamcmdFolder+"\steamcmd.exe"
    $steamcmdCache = $steamcmdFolder+"\appcache"
    $latestAppInfo = $dataPath+"\latestappinfo.json"
    $updateinprogress = $serverPath+"\updateinprogress.dat"
    $latestAvailableUpdate = $dataPath+"\latestavailableupdate.txt"
    $latestInstalledUpdate = $dataPath+"\latestinstalledupdate.txt"

    If (Test-Path $updateinprogress) {
    Write-Host Update is already in progress could be broke
    } Else {
        #Get-Date | Out-File $updateinprogress
        Write-Host "Creating data Directory"
        New-Item -Force -ItemType directory -Path $dataPath
        If ($clearCache) {
        Write-Host "Removing Cache Folder"
        Remove-Item $steamcmdCache -Force -Recurse
        }

        Write-Host "Checking for an update for $($serverPath)"
        & $steamcmdExec +login anonymous +app_info_update 1 +app_info_print $steamAppID +app_info_print $steamAppID +logoff +quit | Out-File $latestAppInfo
        Get-Content $latestAppInfo -RAW | Select-String -pattern '(?m)"public"\s*\{\s*"buildid"\s*"\d{6,}"' -AllMatches | %{$_.matches[0].value} | Select-String -pattern '\d{6,}' -AllMatches | %{$_.matches} | %{$_.value} | Out-File $latestAvailableUpdate

        If (Test-Path $latestInstalledUpdate) {
            $installedVersion = Get-Content $latestInstalledUpdate
        } Else {
            $installedVersion = 0
        }
        
        $availableVersion = Get-Content $latestAvailableUpdate
        if ($installedVersion -ne $availableVersion) {
            Write-Host "Update Available"
            Write-Host "Installed build: $installedVersion - available build: $availableVersion"
			
			# Save and Shutdown Server Commands here
			# Send RCON Announce to all servers
			Foreach ($server in $serverInfo) {
				$telnetPort = $server.telnetport
                Send-TelnetCommand -port $telnetPort -command "exit"
			}
            Start-sleep -s 600
            Write-host "Starting Update....This could take a few minutes..."
            & $steamcmdExec +login anonymous +force_install_dir $serverPath +app_update $steamAppID validate +quit | Out-File $latestAppInfo
            $availableVersion | Out-File $latestInstalledUpdate
            Write-Host "Update Done!"
            Foreach ($server in $serverInfo) {
                Start-Server -server $server
            }
            #Remove-Item $updateinprogress -Force
        } Else {
            Write-Host 'No Update Available!'
			if (Test-Path $updateinprogress) {
				#Remove-Item $updateinprogress -Force
			}
        }
    } 
} # End Check Update

function Start-Server {
    param ($server)
    $serverArguments = "Level01_Main -server %* -log -UTF8Output -MaxPlayers=100 -Multihome=$($ipaddr) -EchoPort=$($server.telnetport) -forcepassthrough -adminpsw=$($server.adminpass) " +
    "-backup=300 -initbackup -backupinterval=600 " +
    "-SteamServerName=`"$($server.name)`" -port=$($server.port) -queryport=$($server.queryport) -saveddirsuffix=$($server.savedir) -GonHuiMaxMember=$($server.clanmembers)"
    if ($server.type -like "1") {
        $serverArguments += " -pvp"
    } else {
        $serverArguments += " -pve"
    }
    if ($server.serverid) {
        $serverArguments += " -serverid=$($server.serverid)"
    }
    # Not exactly sure what this does yet
    if ($server.clusterid) {
        $serverArguments += " -cluster=$($server.clusterid)"
    }
    if ($ipaddr) {
        $serverArguments += " -Multihome=$($ipaddr)"
    } else {
        $serverArguments += " -Multihome=0.0.0.0"
    }
    $pidPath = Join-Path $serverRoot "WS\Saved_$($server.savedir)\server.pid"
    If (Test-Path $pidPath) {
        $processID = Get-Content $pidPath
        Try {
            $serverCheck = Get-Process -id $processID -ErrorAction Stop
        } Catch {
            $process = Start-Process $serverPath $serverArguments -PassThru -ErrorAction Stop
        }
    } Else {
        $process = Start-Process $serverPath $serverArguments -PassThru -ErrorAction Stop
    }
    $process.id | Out-File $pidPath -Force
}

$csv = Import-Csv $csvFile
Switch ($option) {
    "startServers" {
        foreach ($server in $csv) {
            Start-Server -server $server
        }
    }
    "stopServers" {
        Foreach ($server in $csv) {
            $telnetPort = $server.telnetport
            Send-TelnetCommand -port $telnetPort -command "exit"
        }
    }
    "updateServers" {
        checkUpdate -serverPath $serverRoot -steamCMDFolder $steamcmdPath -serverInfo $csv
    }
}