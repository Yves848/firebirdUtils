. "$PSScriptRoot\visuals.ps1"
. "$PSScriptRoot\classes.ps1"
. "$PSScriptRoot\tools.ps1"
. "$PSscriptRoot\GumEnv.ps1"

$databaseName = "$PSScriptRoot\Database.fdb"

$username = "SYSDBA"
$password = "masterkey"
$createDB = @"
    CREATE DATABASE '$($databaseName)'
    USER '$username' PASSWORD '$password'
    DEFAULT CHARACTER SET UTF8;

    COMMIT;
"@




# TODO: Test if Firebird is Installed and started
function isFirebirdStarted {
    return $true
}

# TODO: Display a menu with the different functions availables
function displayMenu {
    Clear-Host
    $result = 0
    while ($result -ne -1) {
        gum style "Commit PWSH Utils $script:version" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
        $options = @(
            "Créer une DB",
            "Initialiser un module",
            "Faire le café",
            "Exit"
        )
        $choice = $options -join "`n" | gum choose 
        Clear-Host
        $index = $options.IndexOf($choice)
        switch ($index) {
            
            Default { $result = -1 }
        }
    }
}

function createDB {
    $createDB | Out-File $PSScriptRoot\createDB.sql -Force

    $fbBin = [string](Get-Service FirebirdServerDefaultInstance | Select-Object -ExpandProperty BinaryPathName)
    $fbBin = $fbBin.Substring(0, $fbBin.LastIndexOf('\'))
    $isql = "$($fbBin)\isql.exe"

    $command = "$isql -i $("$PSScriptRoot\test.sql")"

    Invoke-Expression -Command $command
}

# TODO: Input the name of the DB to create / Use
function inputDBName {
    return $null
}

function isGumInstalled {
    $gum = Get-Command -CommandType Application -Name gum -ErrorAction SilentlyContinue
    if ($gum) {
        return $true
    }
    return $false
}
    
function installGum {
    $command = "winget install --id charmbracelet.gum -v 0.13.0"
    Invoke-Expression $command | Out-Null
    $env:path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
  
if (-not (isGumInstalled)) {
    installGum
}
  

displayMenu