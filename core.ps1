. "$PSScriptRoot\visuals.ps1"
. "$PSScriptRoot\classes.ps1"
. "$PSscriptRoot\GumEnv.ps1"

$script:databaseName = "vierge"

$username = "SYSDBA"
$password = "masterkey"



[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# TODO: Test if Firebird is Installed and started
function isFirebirdStarted {
    return $true
}

# TODO: Display a menu with the different functions availables
function displayMenu {
    # Clear-Host
    $result = 0
    $path = (Get-Location).Path
    while ($result -ne -1) {
        gum style "Commit PWSH Utils ($($path))" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
        $options = @(
            "Créer une DB PHA ($($script:databaseName))",
            "Initialiser un module",
            "Quitter"
        )
        $choice = $options -join "`n" | gum choose 
        Clear-Host
        $index = $options.IndexOf($choice)
        switch ($index) {
            0 { createDB }
            1 { createPHA }
            Default { $result = -1 }
        }
    }
}

function createPHA {
    chooseCountry
}

function chooseCountry {
    if (Test-Path -Path ".\Scripts\Commun")
    {
        $dir = get-Childitem -Directory -Path ".\Scripts\Commun" | ForEach-Object {$_.BaseName}
        $sql = @()
        Get-ChildItem -Path ".\Scripts\Commun" -Filter "*.sql" | ForEach-Object {
            $sql += $_.FullName
        }
        gum style "Choisir un pays" --foreground $($Theme["cyan"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
        $pays = ($dir -join "`n") | gum choose
        if ($pays) {
            Get-ChildItem -Path ".\Scripts\Commun\$($pays)" -Filter "*.sql" | ForEach-Object {
                $sql += $_.FullName
            }   
            return $sql
        }
        else {
            return $null
        }
    } else {
        return $null
    }
}

function createEmptyDB {
    param(
        [string]$DatabaseName
    )
    $fb = [Firebird]::New($DatabaseName)
    $fb.CreateDB()
}

function createDB {
    $buffer = gum style "Nom de la DB à créer" --border "rounded" --width ($Host.UI.RawUI.BufferSize.Width - 2)
    $buffer | ForEach-Object {
        [System.Console]::write($_)
    }
    $databaseName = gum input --placeholder "database.fdb"
    if ($databaseName) {
        $script:databaseName = $databaseName
        if (Test-Path -Path "$PSScriptRoot\$databaseName") {
            $replace = gum confirm "La DB existe déjà, voulez-vous la remplacer ?" --affirmative "Oui" --negative "Non" && $true || $false
            if ($replace -eq $true) {
                Remove-Item -Path "$PSScriptRoot\$databaseName"
            }
            else {
                Clear-Host
                return $null
            }
        }
        Clear-Host
        $Spinner = [spinner]::New("Dots")
        $Spinner.Start("Création de la DB");
        createEmptyDB($databaseName)
        Start-Sleep -Seconds 2
        $Spinner.Stop()
    }
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

function Start-CommitUtil {
    displayMenu
}
    
function installGum {
    $command = "winget install --id charmbracelet.gum -v 0.13.0"
    Invoke-Expression $command | Out-Null
    $env:path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
 
if (-not (isGumInstalled)) {
    installGum
}

