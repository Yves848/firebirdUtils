function LoadSql {
  param (
    [string]$file
  )

  $buffer = (Get-Content -Path $file -Raw) -csplit '(?=create|( or\s+alter\s+))'
  $sql = @("SET TERM ^ ;")

  $buffer | ForEach-Object {
    if ($_ -cmatch 'create\s+(or\s+alter\s+)?(trigger|procedure)') {
      $block = $_.trim() -split '\n'
      $block[$block.Length - 1] = "END^"
      $block | ForEach-Object {
        $sql += $_ 
      }
    }
    else {
      $sql += $_ -replace ';', '^'
    }
  }

  $sql += "SET TERM ; ^"
  return $sql
}