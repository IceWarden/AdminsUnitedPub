Param (
    # Path Setup
    $path = "C:\servers\MoE",
    $rconPath = "C:\Scripts\mcrcon\mcrcon.exe", # Download MCRCON 
	[string]$option="", # Reboot/Start/Shutdown
    # Variable Setup CHANGE THESE!!
    $multiHome = "135.148.100.218", # PRIVATE IP ADDR ipconfig 
    $outAddress = "135.148.100.218", # PUBLIC IP ADDR ipchicken.com
    $serverUID = "123456789", # UID used in PrivateServerTool.exe
    $serverPort = "1337", # Used for Outside Connections
    $RCONPort = "1338", # LOCAL ONLY (for now)
    $serverID = "103", # For Clustering
    $clusterID = "1", # For Clustering
    $serverPassword = "", # Password for server. Put a # at the beginning of this line to not use a password
    $sessionName = "No Mans Land 12-Man [4x PVP]", # Server Name
    $serverDescript = "No Mans Land discord.gg/nomansland", # Description; small; dont overboard
    $maxPlayers = "100", # Max 100?
    $pvp = "0", # 1 = PvE; 0 = PvP
    $serverMOTD = "Welcome to No Mans Land... discord.gg/nomansland",
    $serverAdmin = "76561197990955588;76561198285959321;76561198054674528;76561198007856892;76561198138344054", # CSV
    $PlantMultiplier="4", # Plant Gather Rate
    $StoneMultiplier="4", # Stone Gather Rate
    $HunterMultiplier="4", # Hunter Gather Rate
    $expMultiplier="4", # Player XP 
    $gatherXPMultiplier="4", # Gathering XP
    $killXPMultiplier="4", # Kill XP
    $playerSpeed="", # Movement Speed
    $joinNotifications="False", # Join notifications True/False
    $mapDifficulty="1", # Difficulty.
	$startTask = "", # Name of Scheduled Task to Start Server
	$old = "", # Is it original install or dedi
	$craftTime="0.25", # Crafting Speed
	$moneyDropMulti = "4", # Money Drop Multiplier
	$maxGuildPoint = "4", # Max Guild Point per user per day
	$skillxpMulti = "4", # SKill XP Multiplier
	$structDmgMulti = "0.5", # Structure Damage Multiplier
    $domesticationCoef = "4", # Domestication Coeffcient
    $mountQuality = "",
    $warPlayLimit = "2", # Active NPCs PER PLAYER
    $warXPMulti = "4", # NPC Experience Multiplier
    $warSkillXPMulti = "4", # NPC Skill Experience Multiplier
    $breedingSpeed = "4", # Speed of Breeding
    $babyGrowthSpeed = "4", # Baby Animal Growth Speed
    $maxCollectMulti = "4", # Collection Multiplier
    $cropGrowthRate = "4", # Farm Growth
    $initRecipePoints = "20", # Initial Recipe Points
    $playerWeightRatio = "1.5", # PlayerLoadMultiplier
    $initCapitalCopper = "5000" # Starting Copper
)

if (!($option)) {
	Write-Host "No Option Passed"
	Exit 0
}
Set-Alias mcrcon $rconPath
if ($old -like "True") {
	$gamePath = Join-path $path "WindowsPrivateServer\MOE\Binaries\Win64\MOEServer.exe"
} Else {
	$gamePath = Join-path $path "MOE\Binaries\Win64\MOEServer.exe"
}



# DONT TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING!
# I hate really long lines!
$argumentLine = "LargeTerrain_Central2_Main " + `
"-game -server -DataLocalFile -log log=$serverUID.log " + `
"-LOCALLOGTIMES -PrivateServer -UseBattlEye " + `
"-MultiHome=$multiHome -OutAddress=$outAddress " + `
"-NotCheckServerSteamAuth " + `
"-pakdir=*..\WindowsPrivateServer\MOE\$($serverUID)Mods* " + `
"-SessionName=`"$sessionName`" " + `
"-Description=`"$serverDescript`" " + `
"-GameServerPVPType=$pvp -MaxPlayers=$maxPlayers " + `
"-NoticeSelfEnable=true -bEnableServerLevel=false " + `
"-NoticeSelfEnterServer=`"$serverMOTD`" " + `
"-MapDifficultyRate=$mapDifficulty -ServerId=$serverID -ClusterId=$clusterID " + `
"-Port=$serverPort -ShutDownServicePort=$RCONPort -ServerAdminAccounts=`"$serverAdmin`" -SaveGameIntervalMinute=60 -GuildMaxMember=12"

if($serverPassword) {
    $argumentLine += "-PrivateServerPassword=$serverPassword "
}
if ($joinNotification -like "*True*") {
    $argumentLine += "-NoticeAllEnable=true "
}
if ($playerSpeed) {
    $argumentLine += "-PlayerSpeedMultiplier=$playerSpeed "
}
if($killXPMultiplier) {
    $argumentLine += "-PlayerKillMonstersExpMultiplier=$killXPMultiplier "
}
if($gatherXPMultiplier) {
    $argumentLine += "-PlayerCollectionExpMultiplier=$gatherXPMultiplier "
}
if($expMultiplier) {
    $argumentLine += "-AddExpMultiplier=$expMultiplier "
}
if($HunterMultiplier) {
    if($pvp -like "0") {
        $argumentLine += "-CollectHunterMultiplier=$HunterMultiplier "
    } Elseif ($pvp -like "1") {
        $argumentLine += "-CollectHunterMultiplierPVE=$HunterMultiplier "
    }
}
if($StoneMultiplier) {
    if($pvp -like "0") {
        $argumentLine += "-CollectStoneMultiplier=$StoneMultiplier "
    } Elseif ($pvp -like "1") {
        $argumentLine += "-CollectStoneMultiplierPVE=$StoneMultiplier "
    }
}
if($PlantMultiplier) {
    if($pvp -like "0") {
        $argumentLine += "-CollectPlantMultiplier=$PlantMultiplier "
    } Elseif ($pvp -like "1") {
        $argumentLine += "-CollectPlantMultiplierPVE=$PlantMultiplier "
    }
}
if($craftTime) {
    $argumentLine += "-ItemCraftRepairTimeMulti=$craftTime "
}
if($moneyDropMulti) {
    if($pvp -like "0") {
        $argumentLine += "-CapitalDropRatioPVP=$moneyDropMulti "
    } Elseif ($pvp -like "1") {
        $argumentLine += "CapitalDropRatioPVE=$moneyDropMulti "
    }
}
if($maxGuildPoint) {
    $argumentLine += "-MaxGuildActivityPointMul=$maxGuildPoint "
}
if($skillxpMulti) {
    $argumentLine += "-SkillExpMultiplier=$skillxpMulti "
}
if ($structDmgMulti) {
	$argumentLine += "-StructureDamageMultiplier=$structDmgMulti "
}
if ($domesticationCoef) {
    $argumentLine += "-AddTameMulti=$domesticationCoef "
}
if ($warPlayLimit) {
    $argumentLine += "-NUM_WarGeneralMax=$warPlayLimit "
}
if ($warXPMulti) {
    $argumentLine += "-GeneralExpMultiplier=$warXPMulti "
}
if ($warSkillXPMulti) {
    $argumentLine += "-GeneralTalentExpMultiplier=$warSkillXPMulti "
}
if ($breedingSpeed) {
    $argumentLine += "-TameAnimalMatingSpeedMultiplier=$breedingSpeed "
}
if ($babyGrowthSpeed) {
    $argumentLine += "-BabyAnimalGrowthRateMultiplier=$babyGrowthSpeed "
}
if ($maxCollectMulti) {
    $argumentLine += "-CollectMaxMultiplier=$maxCollectMulti "
}
if ($cropGrowthRate) {
    $argumentLine += "-CropGrowthMultiplier=$cropGrowthRate "
}
if ($initRecipePoints) {
    $argumentLine += "-InitDefaultCraftPerkPoint=$initRecipePoints "
}
if ($playerWeightRatio) {
    $argumentLine += "-PlayerLoadMultiplier=$playerWeightRatio "
}
if ($initCapitalCopper) {
    $argumentLine += "-InitCapitalCopper=$initCapitalCopper "
}


function executeRCON {
	param($command)
	mcrcon -H 127.0.0.1 -P $RCONPort -p 123456 "$command"
}

function discordMsg {
	param($custmsg)
	node C:\scripts\DiscordBot\rebootMessage.js --custmsg=$custMsg --channels=live
}

function StartServer {
    param ($serverPath, $argumentLine, $pidPath)

    Try {
        $process = Start-Process $serverPath $argumentLIne -PassThru -ErrorAction Stop
        $process.Id | Out-File $pidPath
        Write-Host "Successfully Started $($serverPath) with PID: $($process.Id)"
    } Catch {
        Write-Error "Failed to Start the server: $_"
    }
}

function StopServer {
    param ($pidPath)
    executeRCON -command "SaveWorld"
	start-sleep -s 30
	executeRCON -command "ShutDownServer"
    Start-Sleep -s 15
    if (Test-Path $PIDPath) {
        $appID = Get-Content $pidPath
    }
    Get-Process -id $appID -ErrorAction SilentlyContinue | Stop-Process
}

# DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING!
$pidPath = Join-Path $gamePath "pids\server.pid"
Switch ($option) {
	"Reboot" {
		StopServer
        Start-Sleep -s 10
        StartServer $gamePath $argumentLine $pidPath
		break
	}
	"Start" {
        # Make sure server isn't already running
        if (Test-Path $PIDPath) {
            $appID = Get-Content $pidPath
        }
        Try {
            $serverCheck = Get-Process -id $appID -ErrorAction Stop
        } Catch {
            # Server isn't running
            StartServer $gamePath $argumentLine $pidPath
        }
        break 
	}
	"Shutdown" {
		StopServer $pidPath
		break
	}
	Default  {
		Write-Host "INVALID OPTION SELECTED $option"
		Break
	}
}
