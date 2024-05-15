# Set the directory containing the BPL files
$directory = "C:\Commit 4.8\Modules\Import\"

# Get all BPL files in the directory
$bplFiles = Get-ChildItem -Path $directory -Filter "*.bpl"

# Loop through each BPL file
foreach ($file in $bplFiles) {
    # Get version information using .NET's FileVersionInfo class
    $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($file.FullName)

    # Output version information
    Write-Host "File: $($file.Name)"
    Write-Host "Product Version: $($versionInfo.ProductVersion)"
    Write-Host "File Version: $($versionInfo.FileVersion)"
    Write-Host "Original Filename: $($versionInfo.OriginalFilename)"
    Write-Host $versionInfo.Pays
    Write-Host "---------------------------------------"
}
