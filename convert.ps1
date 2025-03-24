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
                'LAC / TAC' = $(
                    if ($_.TAC) { $_.TAC }
                    else { $_.LAC }
                )
                'Band Freq' = ''
                'Band Num' = ''
                'Channel' = $(
                    if ($_.EARFCN) { $_.EARFCN } 
                    else { $_.Frequency }
                )
                'eNB / gNB' = $_.eNB
                'Sector ID' = $_.ShortCellID
                'PSC / PCI' = $(
                    if ($_.PSC) { $_.PSC }
                    else { $_.PCI }
                )
                'Power' = $(
                    if ($_.RSRP) { $_.RSRP }
                    elseif ($_.RSCP) { $_.RSCP }
                    else { '' }
                )
                'Quality' = $(
                    if ($_.RSRQ) { $_.RSRQ }
                    elseif ($_.ECIO) { $_.ECIO }
                    else { '' }
                )
                'N1_CID' = $(
                    if ($_.A1_CellID) { $_.A1_CellID }
                    else { $_.N1_CellID }
                )
                'N1_Channel' = $(
                    if ($_.N1_EARFCN) { $_.N1_EARFCN }
                    elseif ($_.A1_Frequency) { $_.A1_Frequency }
                    else { '' }
                )
                'N1_PSC/PCI' = $(
                    if ($_.A1_PSC) { $_.A1_PSC }
                    else { $_.N1_PCI }
                )
                'N2_CID' = $(
                    if ($_.A2_CellID) { $_.A2_CellID }
                    else { $_.N2_CellID }
                )
                'N2_Channel' = $(
                    if ($_.N2_EARFCN) { $_.N2_EARFCN }
                    elseif ($_.A2_Frequency) { $_.A2_Frequency }
                    else { '' }
                )
                'N2_PSC/PCI' = $(
                    if ($_.A2_PSC) { $_.A2_PSC }
                    else { $_.N2_PCI }
                )
                'N3_CID' = $(
                    if ($_.A3_CellID) { $_.A3_CellID }
                    else { $_.N3_CellID }
                )
                'N3_Channel' = $(
                    if ($_.N3_EARFCN) { $_.N3_EARFCN }
                    elseif ($_.A3_Frequency) { $_.A3_Frequency }
                    else { '' }
                )
                'N3_PSC/PCI' = $(
                    if ($_.A3_PSC) { $_.A3_PSC }
                    else { $_.N3_PCI }
                )
                'N4_CID' = $(
                    if ($_.A4_CellID) { $_.A4_CellID }
                    else { $_.N4_CellID }
                )
                'N4_Channel' = $(
                    if ($_.N4_EARFCN) { $_.N4_EARFCN }
                    elseif ($_.A4_Frequency) { $_.A4_Frequency }
                    else { '' }
                )
                'N4_PSC/PCI' = $(
                    if ($_.A4_PSC) { $_.A4_PSC }
                    else { $_.N4_PCI }
                )
                'N5_CID' = $(
                    if ($_.A5_CellID) { $_.A5_CellID }
                    else { $_.N5_CellID }
                )
                'N5_Channel' = $(
                    if ($_.N5_EARFCN) { $_.N5_EARFCN }
                    elseif ($_.A5_Frequency) { $_.A5_Frequency }
                    else { '' }
                )
                'N5_PSC/PCI' = $(
                    if ($_.A5_PSC) { $_.A5_PSC }
                    else { $_.N5_PCI }
                )
                'N6_CID' = $(
                    if ($_.A6_CellID) { $_.A6_CellID }
                    else { $_.N6_CellID }
                )
                'N6_Channel' = $(
                    if ($_.N6_EARFCN) { $_.N6_EARFCN }
                    elseif ($_.A6_Frequency) { $_.A6_Frequency }
                    else { '' }
                )
                'N6_PSC/PCI' = $(
                    if ($_.A6_PSC) { $_.A6_PSC }
                    else { $_.N6_PCI }
                )
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