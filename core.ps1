Import-Module -Name "$PSScriptRoot\classes.ps1" -Force
Import-Module -Name "$PSscriptRoot\GumEnv.ps1" -Force
Import-Module -Name  "$PSScriptRoot\visuals.ps1" -Force
Import-Module -Name  "$PSScriptRoot\Tools.ps1" -Force
$script:databaseName = "vierge"

$username = "SYSDBA"
$password = "masterkey"



[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# TODO: Test if Firebird is Installed and started
function isFirebirdStarted {
    return $true
}

function displayMenu {
    Clear-Host
    $result = 0
    $path = (Get-Location).Path
    while ($result -ne -1) {
        gum style "Commit PWSH Utils ($($path))" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
        $menu = [ordered]@{
            "Créer une DB"     = "createDB"
            "Fermer DB"        = "closeDB"
            "Créer une DB PHA" = "createPHA"
            "Quitter"          = "exit"
        }

        $options = @()
        $menu.keys | ForEach-Object {
            if ($menu[$_] -match 'closeDB') {
                if ($script:databaseName -ne "vierge") {
                    $options += $_
                }
            }
            else {
                $options += $_
            }    
        }
        
        $choice = $options -join "`n" | gum choose 
        Clear-Host
        # $index = $options.IndexOf($choice)
        switch ($menu[$choice]) {
            "createDB" { createDB }
            "closeDB" { closeDB }
            "createPHA" { createPHA }
            "exit" { $result = -1 }
            Default { $result = -1 }
        }
    }
}

function closeDB {
    $script:databaseName = "Vierge"
}

function createPHA {
    if (Test-Path -Path ".\Scripts\Commun") {
        $sql = @()
        Get-ChildItem -Path ".\Scripts\Commun" -Filter "*.sql" | ForEach-Object {
            $sql += $_.FullName
        }
        $pays = chooseCountry
        Get-ChildItem -Path ".\Scripts\Commun\$($pays)" -Filter "*.sql" | ForEach-Object {
            $sql += $_.FullName
        }   
        $module = chooseModule -pays $pays
        Get-ChildItem -Path ".\Scripts\Modules\Import" -Filter "$module*.sql" | ForEach-Object {
            $sql += $_.FullName
        }   
        # return $sql
        $title = gum style "Création de la DB PHA ($($module))" --foreground $($Theme["red"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
        $title | ForEach-Object {
            [System.Console]::WriteLine($_)
        }
        $Spinner = [spinner]::New("Dots")
        $fb = [Firebird]::New("$script:databaseName")
        $sql | ForEach-Object {
            if ($Spinner.running -eq $false) {
                $Spinner.Start("Exécution de $($_)")
            }
            else {
                $Spinner.SetLabel("Exécution de $($_)")
            }
            
            $fb.ExecuteSQL($_)
            
        }
        $Spinner.Stop()
    }
    else {
        return $null
    }
    
}

function chooseCountry {
    Clear-Host
    $dir = Get-ChildItem -Directory -Path ".\Scripts\Commun" | ForEach-Object { $_.BaseName }
    $title = gum style "Choisir un pays" --foreground $($Theme["cyan"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
    $title | ForEach-Object {
        [System.Console]::WriteLine($_)
    }
    $pays = ($dir -join "`n") | gum choose
    return $pays
    
}

function chooseModule {
    param(
        [string]$pays
    )
    Clear-Host  
    $title = gum style "Choisir un module $($pays)" --foreground $($Theme["cyan"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
    $title | ForEach-Object {
        [System.Console]::WriteLine($_)
    }
    $module = ($modules["$pays"] -join "`n") | gum choose
    return $module
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
        # Start-Sleep -Seconds 2
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
    if (Test-Path -Path ".\Scripts\Commun") {
        displayMenu
    }
    else {
        $buffer = gum style "Ce script doit être utilisé dans un répertoire Commit" --border "rounded" --width ($Host.UI.RawUI.BufferSize.Width - 2) --foreground $($Theme["red"])  
        $buffer | ForEach-Object {
            [System.Console]::write($_)
        }
    }
}
    
function installGum {
    $command = "winget install --id charmbracelet.gum -v 0.13.0"
    Invoke-Expression $command | Out-Null
    $env:path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
 
if (-not (isGumInstalled)) {
    installGum
}

# Set-Location 'C:\Commit 4.8'

# Start-CommitUtil