# Get all CSV files in the directory
$csvFiles = Get-ChildItem -LiteralPath "$PSScriptRoot/data/" -Filter "*.csv"

Write-Output "Starting to process CSV files..."

# Print out the CSV files found
foreach ($file in $csvFiles) {
    Write-Output "Found CSV file: $($file.FullName)"
}

foreach ($file in $csvFiles) {
    try {

    # Clear out the output folder at the start
    $outputFolder = "$PSScriptRoot/output/"
    if (Test-Path -Path $outputFolder) {
        Remove-Item -Path "$outputFolder/*.csv" -Force
    } else {
        New-Item -Path $outputFolder -ItemType Directory
    }

        # Import the CSV file
        $csvContent = Import-Csv -LiteralPath $file.FullName

        # Output the number of lines processed
        $lineCount = $csvContent.Count
        Write-Output "Number of lines processed in $($file.Name): $lineCount"

        # Define the output file path
        $outputFilePath = Join-Path -Path "$PSScriptRoot/output/" -ChildPath $file.Name


    # Remove the specified columns from each row
    foreach ($row in $csvContent) {
        if ($column -match '^N(7|8|9|1[0-5])*') {
            $row.PSObject.Properties.Remove($column)
        }
}

        try {
            # Export the processed CSV content to a new file in the output folder without quotes
            $csvContent | Export-Csv -Path $outputFilePath -NoTypeInformation -Force -UseQuotes Never
            Write-Output "Processed file saved to: $outputFilePath"
        } catch {
            Write-Error "Failed to process file $($file.FullName): $_"
        }

    } catch {
        Write-Error "Failed to import or process file $($file.FullName): $_"
    }
}