enum alignment {
  Left = 0
  Right
  Center  # TODO : Implement
}

$modules = @{ FR = @("actipharm", "CaducielV6", "CIP", "CSVClient", "DynaCaisse", "esculapev6", "importlgpi", "Infosoft", "Leo1", "Leo2", "Lgo2", "NEV", "Opus", "periphar", "Pharmalandv7", "PharmaVitale", "SmartRX", "Vindilis", "VisioPharm", "Winpharma", "XLSoft")
  BE             = @("FarmadTWin", "Goed", "Greenock", "ImportUltimate", "IPharma", "MultiPharma", "NextPharm", "Officinall", "Pharmony")
}

class Spinner {
  [hashtable]$Spinner
  [System.Collections.Hashtable]$statedata
  $runspace
  [powershell]$session
  [Int32]$X = $Host.UI.RawUI.CursorPosition.X
  [Int32]$Y = $Host.UI.RawUI.CursorPosition.Y
  [bool]$running = $false
  [Int32]$width = $Host.UI.RawUI.BufferSize.Width

  $Spinners = @{
    "Circle" = @{
      "Frames" = @("◜", "◠", "◝", "◞", "◡", "◟")
      "Sleep"  = 50
    }
    "Dots"   = @{
      "Frames" = @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷", "⣿")
      "Sleep"  = 50
    }
    "Line"   = @{
      "Frames" = @("▰▱▱▱▱▱▱", "▰▰▱▱▱▱▱", "▰▰▰▱▱▱▱", "▰▰▰▰▱▱▱", "▰▰▰▰▰▱▱", "▰▰▰▰▰▰▱", "▰▰▰▰▰▰▰", "▰▱▱▱▱▱▱")
      "Sleep"  = 50
    }
    "Square" = @{
      "Frames" = @("⣾⣿", "⣽⣿", "⣻⣿", "⢿⣿", "⡿⣿", "⣟⣿", "⣯⣿", "⣷⣿", "⣿⣾", "⣿⣽", "⣿⣻", "⣿⢿", "⣿⡿", "⣿⣟", "⣿⣯", "⣿⣷")
      "Sleep"  = 50
    }
    "Bubble" = @{
      "Frames" = @("......", "o.....", "Oo....", "oOo...", ".oOo..", "..oOo.", "...oOo", "....oO", ".....o", "....oO", "...oOo", "..oOo.", ".oOo..", "oOo...", "Oo....", "o.....", "......")
      "Sleep"  = 50
    }
    "Arrow"  = @{
      "Frames" = @("≻    ", " ≻   ", "  ≻  ", "   ≻ ", "    ≻", "    ≺", "   ≺ ", "  ≺  ", " ≺   ", "≺    ")
      "Sleep"  = 50
    }
    "Pulse"  = @{
      "Frames" = @("◾", "◾", "◼️", "◼️", "⬛", "⬛", "◼️", "◼️")
      "Sleep"  = 50
    }
  }

  Spinner(
    [string]$type = "Dots"
  ) {
    
    $this.Spinner = $this.Spinners[$type]
  }

  Spinner(
    [string]$type = "Dots",
    [int]$X,
    [int]$Y
  ) {
    $this.Spinner = $this.Spinners[$type]
    $this.X = $X
    $this.Y = $Y
  }

  [void] Start(
    [string]$label = "Loading..."
  ) {
    $this.running = $true
    $this.statedata = [System.Collections.Hashtable]::Synchronized([System.Collections.Hashtable]::new())
    $this.runspace = [runspacefactory]::CreateRunspace()
    $this.statedata.offset = ($this.Spinner.Frames | Measure-Object -Property Length -Maximum).Maximum
    $ThemedFrames = @()
    $this.Spinner.Frames | ForEach-Object {
      $ThemedFrames += gum style $_ --foreground $($Theme["brightPurple"]) 
    }
    $this.statedata.Frames = $ThemedFrames
    $this.statedata.Sleep = $this.Spinner.Sleep
    $this.statedata.label = $label 
    $this.statedata.X = $this.X
    $this.statedata.Y = $this.Y
    $this.runspace.Open()
    $this.Runspace.SessionStateProxy.SetVariable("StateData", $this.StateData)
    $sb = {
      [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
      [system.Console]::CursorVisible = $false
      $X = $StateData.X
      $Y = $StateData.Y
    
      $Frames = $statedata.Frames
      $i = 0
      while ($true) {
        [System.Console]::setcursorposition($X, $Y)
        $text = $Frames[$i]    
        [system.console]::write($text)
        [System.Console]::setcursorposition(($X + $statedata.offset) + 1, $Y)
        [system.console]::write($statedata.label)
        $i = ($i + 1) % $Frames.Length
        Start-Sleep -Milliseconds $Statedata.Sleep
      }
    }
    $this.session = [powershell]::create()
    $null = $this.session.AddScript($sb)
    $this.session.Runspace = $this.runspace
    $null = $this.session.BeginInvoke()
  }

  [void] SetLabel(
    [string]$label
  ) {
    [System.Console]::setcursorposition(($this.X + $this.statedata.offset) + 1, $this.Y)
    [system.console]::write("".PadLeft($this.statedata.label.Length, " "))
    $this.statedata.label = $label
    # Redraw the label to avoid flickering
    [System.Console]::setcursorposition(($this.X + $this.statedata.offset) + 1, $this.Y)
    [system.console]::write($label)
  }

  [void] Stop() {
    if ($this.running -eq $true) {
      [System.Console]::setcursorposition(0, $this.Y)
      [system.console]::write("".PadLeft($this.Width, " "))
      $this.running = $false
      $this.session.Stop()
      $this.runspace.Close()
      $this.runspace.Dispose()
      [System.Console]::setcursorposition($this.X, $this.Y)
      [system.Console]::CursorVisible = $true
    } 
  }
}

class Firebird {
  $databaseName = ""
  [System.Collections.Hashtable]$statedata
  $runspace
  [powershell]$session
  [Int32]$X = $Host.UI.RawUI.CursorPosition.X
  [Int32]$Y = $Host.UI.RawUI.CursorPosition.Y
  [bool]$running = $false
  [Int32]$width = $Host.UI.RawUI.BufferSize.Width
  [string]$username = "sysdba"
  [string]$password = "masterkey"
  [string]$fbin = ""
  [string]$isql = ""
  [string]$createDBScript

  Firebird(
    [string]$DatabaseName
  ) {
    $this.databaseName = "$PSScriptRoot\$($DatabaseName)"
    $fbBin = [string](Get-Service FirebirdServerDefaultInstance | Select-Object -ExpandProperty BinaryPathName)
    $fbBin = $fbBin.Substring(0, $fbBin.LastIndexOf('\'))
    $this.isql = "$($fbBin)\isql.exe"
  }

  [void] CreateDB() {
    $this.createDBScript = @"
    SET TERM ^ ;
  CREATE DATABASE '$($this.databaseName)'
  USER '$($this.username)' PASSWORD '$($this.password)'
  PAGE_SIZE 16384 DEFAULT CHARACTER SET UTF8^
  COMMIT^
  SET TERM ; ^
"@ 
    $this.createDBScript | Out-File -FilePath "$PSScriptRoot\createDB.sql"
    $this.runspace = [runspacefactory]::CreateRunspace()
    $this.statedata = [System.Collections.Hashtable]::Synchronized([System.Collections.Hashtable]::new())
    $this.statedata.command = "$($this.isql) -i $("$PSScriptRoot\createDB.sql")"
    $this.runspace.Open()
    $this.Runspace.SessionStateProxy.SetVariable("StateData", $this.StateData)
    $sb = {
      Invoke-Expression -Command $Statedata.command | Out-Null
    }
    $this.session = [powershell]::create()
    $null = $this.session.AddScript($sb)
    $this.session.Runspace = $this.runspace
    $this.session.Invoke()
    
    $this.session.Stop()
    $this.runspace.Close()
    $this.runspace.Dispose()
    # Remove-Item -Path "$PSScriptRoot\createDB.sql"
  }

  [void] ExecuteSQL(
    [string]$sql
  ) {
    loadSql -file $sql | Out-File -FilePath "$PSScriptRoot\execute.sql"
    # Invoke-Expression -Command $command
    $this.runspace = [runspacefactory]::CreateRunspace()
    $this.statedata = [System.Collections.Hashtable]::Synchronized([System.Collections.Hashtable]::new())
    $this.statedata.command = "$($this.isql) $($this.databaseName) -i '$("$PSScriptRoot\execute.sql")' -u sysdba -p masterkey"
    $this.runspace.Open()
    $this.Runspace.SessionStateProxy.SetVariable("StateData", $this.StateData)
    $sb = {
      Invoke-Expression -Command $Statedata.command | Out-Null
    }
    $this.session = [powershell]::create()
    $null = $this.session.AddScript($sb)
    $this.session.Runspace = $this.runspace
    $this.session.Invoke()
    
    $this.session.Stop()
    $this.runspace.Close()
    $this.runspace.Dispose()
  }

}

$Theme = @{
  "background"   = "#272935"
  "black"        = "#272935"
  "blue"         = "#BD93F9"
  "brightBlack"  = "#555555"
  "brightBlue"   = "#BD93F9"
  "brightCyan"   = "#8BE9FD"
  "brightGreen"  = "#50FA7B"
  "brightPurple" = "#FF79C6"
  "brightRed"    = "#FF5555"
  "brightWhite"  = "#FFFFFF"
  "brightYellow" = "#F1FA8C"
  "cyan"         = "#6272A4"
  "foreground"   = "#F8F8F2"
  "green"        = "#50FA7B"
  "purple"       = "#6272A4"
  "red"          = "#FF5555"
  "white"        = "#F8F8F2"
  "yellow"       = "#FFB86C"
}
