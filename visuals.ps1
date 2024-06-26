function color {
  param (
    $Text,
    $ForegroundColor = 'default',
    $BackgroundColor = 'default'
  )
  # Terminal Colors
  $Colors = @{
    "default"    = @(40, 50)
    "black"      = @(30, 0)
    "lightgrey"  = @(33, 43)
    "grey"       = @(37, 47)
    "darkgrey"   = @(90, 100)
    "red"        = @(91, 101)
    "darkred"    = @(31, 41)
    "green"      = @(92, 102)
    "darkgreen"  = @(32, 42)
    "yellow"     = @(93, 103)
    "white"      = @(97, 107)
    "brightblue" = @(94, 104)
    "darkblue"   = @(34, 44)
    "indigo"     = @(35, 45)
    "cyan"       = @(96, 106)
    "darkcyan"   = @(36, 46)
  }
  
  if ( $ForegroundColor -notin $Colors.Keys -or $BackgroundColor -notin $Colors.Keys) {
    Write-Error "Invalid color choice!" -ErrorAction Stop
  }
  
  "$([char]27)[$($colors[$ForegroundColor][0])m$([char]27)[$($colors[$BackgroundColor][1])m$($Text)$([char]27)[0m"    
}

class Frame {
  [char]$UL
  [char]$UR
  [char]$TOP
  [char]$LEFT
  [char]$RIGHT
  [char]$BL
  [char]$BR
  [char]$BOTTOM
  [char]$LEFTSPLIT
  [char]$RIGHTSPLIT
  

  $FrameStyles = @{
    "Single"  = @{
      "UL"         = "┌"
      "UR"         = "┐"
      "TOP"        = "─"
      "LEFT"       = "│"
      "RIGHT"      = "│"
      "BL"         = "└"
      "BR"         = "┘"
      "BOTTOM"     = "─"
      "LEFTSPLIT"  = "├"
      "RIGHTSPLIT" = "┤"
    }
    "Double"  = @{
      "UL"         = "╔"
      "UR"         = "╗"
      "TOP"        = "═"
      "LEFT"       = "║"
      "RIGHT"      = "║"
      "BL"         = "╚"
      "BR"         = "╝"
      "BOTTOM"     = "═"
      "LEFTSPLIT"  = "╠"
      "RIGHTSPLIT" = "╣"
    }
    "Rounded" = @{
      "UL"         = "╭"
      "UR"         = "╮"
      "TOP"        = "─"
      "LEFT"       = "│"
      "RIGHT"      = "│"
      "BL"         = "╰"
      "BR"         = "╯"
      "BOTTOM"     = "─"
      "LEFTSPLIT"  = "├"
      "RIGHTSPLIT" = "┤"
    }
  }
  Frame (
    [string]$FrameStyle
  ) {
    $this.UL = $this.FrameStyles[$FrameStyle].UL
    $this.UR = $this.FrameStyles[$FrameStyle].UR
    $this.TOP = $this.FrameStyles[$FrameStyle].TOP
    $this.LEFT = $this.FrameStyles[$FrameStyle].LEFT
    $this.RIGHT = $this.FrameStyles[$FrameStyle].RIGHT
    $this.BL = $this.FrameStyles[$FrameStyle].BL
    $this.BR = $this.FrameStyles[$FrameStyle].BR
    $this.BOTTOM = $this.FrameStyles[$FrameStyle].BOTTOM
    $this.LEFTSPLIT = $this.FrameStyles[$FrameStyle].LEFTSPLIT
    $this.RIGHTSPLIT = $this.FrameStyles[$FrameStyle].RIGHTSPLIT
  }
}

class window {
  [int]$X
  [int]$Y
  [int]$W
  [int]$H
  [Frame]$frameStyle
  [System.ConsoleColor]$frameColor
  [string]$title = ""
  [System.ConsoleColor]$titleColor
  [string]$footer = ""
  [int]$page = 1
  [int]$nbPages = 1
  
  window(
    [int]$X,
    [int]$y,
    [int]$w,
    [int]$h,
    [string]$FrameStyle = "Single",
    [System.ConsoleColor]$color = "White"
  ) {
    $this.X = $X
    $this.Y = $y
    $this.W = $W
    $this.H = $H
    $this.frameStyle = [Frame]::new($FrameStyle)
    $this.frameColor = $color
      
  }
  
  window(
    [int]$X,
    [int]$y,
    [int]$w,
    [int]$h,
    [string]$FrameStyle = "Single",
    [System.ConsoleColor]$color = "White",
    [string]$title = "",
    [System.ConsoleColor]$titlecolor = "Blue"
  ) {
    $this.X = $X
    $this.Y = $y
    $this.W = $W
    $this.H = $H
    $this.frameStyle = [Frame]::new($FrameStyle)
    $this.frameColor = $color
    $this.title = $title
    $this.titleColor = $titlecolor
  }
  
  [void] setPosition(
    [int]$X,
    [int]$Y
  ) {
    [System.Console]::SetCursorPosition($X, $Y)
  }
  
  [void] drawWindow() {
    # $esc = $([char]0x1b)

    [System.Console]::CursorVisible = $false
    $this.setPosition($this.X, $this.Y)
    $bloc1 = $this.frameStyle.UL, "".PadLeft($this.W - 2, $this.frameStyle.TOP), $this.frameStyle.UR -join ""
    $blank = $this.frameStyle.LEFT, "".PadLeft($this.W - 2, " "), $this.frameStyle.RIGHT -join ""
    Write-Host $bloc1 -ForegroundColor $this.frameColor -NoNewline
    for ($i = 1; $i -lt $this.H; $i++) {
      $Y2 = $this.Y + $i
      $X3 = $this.X 
      $this.setPosition($X3, $Y2)
      Write-Host $blank -ForegroundColor $this.frameColor    
    }
    $Y2 = $this.Y + $this.H
    $this.setPosition( $this.X, $Y2)
    $bloc1 = $this.frameStyle.BL, "".PadLeft($this.W - 2, $this.frameStyle.BOTTOM), $this.frameStyle.BR -join ""
    Write-Host $bloc1 -ForegroundColor $this.frameColor -NoNewline
    $this.drawTitle()
    $this.drawFooter()
  }
    
  
  [void] drawVersion() {
    $v = Get-WGPVersion -param WGP
    $version = $this.frameStyle.LEFTSPLIT, $v, $this.frameStyle.RIGHTSPLIT -join ""
    $isempty = [string]::IsNullOrEmpty($v)
    if ($isempty -eq $true) {
      $version = $this.frameStyle.LEFTSPLIT, "Debug", $this.frameStyle.RIGHTSPLIT -join ""
    }
    [System.Console]::setcursorposition($this.W - ($version.Length + 6), $this.Y )
    [console]::write($version)
  }
  
  [void] drawTitle() {
    if ($this.title -ne "") {
      $local:X = $this.x + 2
      $this.setPosition($local:X, $this.Y)
      Write-Host ($this.frameStyle.RIGHTSPLIT, " " -join "") -NoNewline -ForegroundColor $this.frameColor
      $local:X = $local:X + 2
      $this.setPosition($local:X, $this.Y)
      Write-Host $this.title -NoNewline -ForegroundColor $this.titleColor
      $local:X = $local:X + $this.title.Length
      $this.setPosition($local:X, $this.Y)
      Write-Host (" ", $this.frameStyle.LEFTSPLIT -join "") -NoNewline -ForegroundColor $this.frameColor
    }
  }
  
  [void] drawFooter() {
    $Y2 = $this.Y + $this.H
    $this.setPosition( $this.X, $Y2)
    $bloc1 = $this.frameStyle.BL, "".PadLeft($this.W - 2, $this.frameStyle.BOTTOM), $this.frameStyle.BR -join ""
    Write-Host $bloc1 -ForegroundColor $this.frameColor -NoNewline
    if ($this.footer -ne "") {
      $local:x = $this.x + 2
      $local:Y = $this.Y + $this.h
      $this.setPosition($local:X, $local:Y)
      $foot = $this.frameStyle.RIGHTSPLIT, " ", $this.footer, " ", $this.frameStyle.LEFTSPLIT -join ""
      [console]::write($foot)
    }
  }
  
  [void] drawPagination() {
    $sPages = ('Page {0}/{1}' -f ($this.page, $this.nbPages))
    [System.Console]::setcursorposition($this.W - ($sPages.Length + 6), $this.Y + $this.H)
    [console]::write($sPages)
  }
  
  [void] clearWindow() {
    $local:blank = "".PadLeft($this.W, " ") 
    for ($i = 1; $i -lt $this.H; $i++) {
      $this.setPosition(($this.X), ($this.Y + $i))
      Write-Host $blank 
    } 
  }
}

function makeLines {
  param(
    [column[]]$columns,
    [package[]]$items
  )

  $index = 0
  [string]$line = ""
  while ($index -lt $items.Count) {
    $item = $items[$index]
    [string]$temp = ""
    if ($item.IsUpdateAvailable) {
      $temp = [string]::Concat($temp, "↺ ")
    }
    else {
      $temp = [string]::Concat($temp, "  ")
    }
    $columns | ForEach-Object {
      $fieldname = $_.FieldName
      $width = [int32]$_.Width
      $buffer = TruncateString -InputString $([string]$item."$fieldname") -MaxLength $width -Align $_.Align
      $temp = [string]::Concat($temp, [string]$buffer, " ")
    }

    $line = [string]::Concat($line, $temp)
    
    if ($index -lt $items.Count - 1) {
      $line = [string]::Concat($line, "`n")
    }
    $index ++
  }
  return $line
}

function makeHeader {
  param(
    [column[]]$columns
  )
  $header = "   "
  $index = 0
  # TODO: #1 fix the white line if the terminal is too small
  $columns | ForEach-Object {
    $w = Get-ProportionalLength -MaxLength $_.Width
    $filler = " "
    if ($index -eq $columns.Count - 1) {
      $filler = ""
    }
    $Label = $_.Label
    switch ($_.Align) {
      # TODO: #4 Add Center alignment
      Left { $colName = $Label.PadRight($w, " ") }
      Right { $colName = $Label.PadLeft($w, " ") }
      Default {}
    }
    $header = [string]::Concat($header, $colName, $filler)
    $index ++
  }
  return gum style $([string]::Concat("    ", $header)) --foreground $($Theme["brightYellow"])
}

function makeTitle {
  param(
    [string]$title,
    [int]$width
  )
  $w = ($width / 2) + ($title.Length / 2)
  $title = $title.PadLeft($w, " ")
  $title = $title.PadRight($width, " ")
  return gum style $title --foreground $($Theme["brightPurple"]) --background $($Theme["background"]) --bold --align "center"
}

function GumOutput {
  param(
    [string[]]$Text
  )
  $Text | ForEach-Object {
    [System.Console]::WriteLine($_)
  }
}