# Get all CSV files in the directory
$csvFiles = Get-ChildItem -LiteralPath "$PSScriptRoot/data/" -Filter "*.csv"

Write-Output "Starting to process CSV files..."

# Print out the CSV files found
foreach ($file in $csvFiles) {
    Write-Output "Found CSV file: $($file.FullName)"
}

# Clear out the output folder at the start
$outputFolder = "$PSScriptRoot/output/"
if (Test-Path -Path $outputFolder) {
    Remove-Item -Path "$outputFolder/*.csv" -Force
} else {
    New-Item -Path $outputFolder -ItemType Directory
}

foreach ($file in $csvFiles) {
    try {
        # Import the CSV file
        $csvContent = Import-Csv -LiteralPath $file.FullName
        # Filter out rows where CellID is blank
        $csvContent = $csvContent | Where-Object { -not [string]::IsNullOrWhiteSpace($_.CellID) }

        # Output the number of lines processed
        $lineCount = $csvContent.Count
        Write-Output "Number of lines processed in $($file.Name): $lineCount"


        # Create a new array to store transformed data
        $transformedData = $csvContent | ForEach-Object {
            # Create new object with transformed data
            [PSCustomObject]@{
                'Date' = $_.Date
                'Time' = $_.Time
                'Latitude' = $_.Latitude 
                'Longitude' = $_.Longitude
                'Accuracy' = $_.Satellites
                'Point' = ''
                'Source' = $_.BoxID
                'Network' = $(
                    switch ($_.PLMN) {
                        '23410' { 'O2 - UK' }
                        '23415' { 'Vodafone UK' }
                        '23420' { '3' }
                        '23430' { 'EE' }
                        '23433' { 'EE' }
                        default { $_.Network }
                    }
                )
                'PLMN' = $_.PLMN
                'Technology' = $(
                    if ($file.Name -like '*2G*') { '2G' }
                    elseif ($file.Name -like '*3G*') { '3G' }
                    elseif ($file.Name -like '*4G*') { '4G' }
                    else { '' }
                )
                'Serving CID' = $_.CellID
                'LAC / TAC' = $_.TAC
                'Band Freq' = ''
                'Band Num' = ''
                'Channel' = $_.EARFCN
                'eNB / gNB' = $_.eNB
                'Sector ID' = $_.ShortCellID
                'PSC / PCI' = $_.PCI
                'Power' = $_.RSRP
                'Quality' = $_.RSRQ
                'N1_CID' = $_.N1_CellID
                'N1_Channel' = $_.N1_EARFCN
                'N1_PSC/PCI' = $_.N1_PCI
                'N2_CID' = $_.N2_CellID
                'N2_Channel' = $_.N2_EARFCN
                'N2_PSC/PCI' = $_.N2_PCI
                'N3_CID' = $_.N3_CellID
                'N3_Channel' = $_.N3_EARFCN
                'N3_PSC/PCI' = $_.N3_PCI
                'N4_CID' = $_.N4_CellID
                'N4_Channel' = $_.N4_EARFCN
                'N4_PSC/PCI' = $_.N4_PCI
                'N5_CID' = $_.N5_CellID
                'N5_Channel' = $_.N5_EARFCN
                'N5_PSC/PCI' = $_.N5_PCI
                'N6_CID' = $_.N6_CellID
                'N6_Channel' = $_.N6_EARFCN
                'N6_PSC/PCI' = $_.N6_PCI
            }
        }
        # Append FCX to the output filename
        $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "-FCX" + [System.IO.Path]::GetExtension($file.Name)
        $outputFilePath = Join-Path -Path "$PSScriptRoot/output/" -ChildPath $outputFileName

        try {
            # Export the transformed CSV content to a new file in the output folder
            $transformedData | Export-Csv -Path $outputFilePath -NoTypeInformation -Force
            
            # Remove quotes from the output file if needed (compatible with all PowerShell versions)
            $content = Get-Content $outputFilePath
            $content | ForEach-Object { $_ -replace '\"([^\"]*?)\"', '$1' } | Set-Content $outputFilePath
            
            Write-Output "Processed file saved to: $outputFilePath"
        } catch {
            Write-Error "Failed to process file $($file.FullName): $_"
        }

    } catch {
        Write-Error "Failed to import or process file $($file.FullName): $_"
    }
}