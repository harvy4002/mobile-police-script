# Get all CSV files in the directory
$csvFiles = Get-ChildItem -LiteralPath "$PSScriptRoot/data/" -Filter "*.csv"

Write-Output "Starting to process CSV files..."

# Print out the CSV files found
foreach ($file in $csvFiles) {
    Write-Output "Found CSV file: $($file.FullName)"
}

foreach ($file in $csvFiles) {
    try {
        # Import the CSV file
        $csvContent = Import-Csv -LiteralPath $file.FullName

        # Process each row in the CSV file
        foreach ($row in $csvContent) {
            # Example: Output each row to the console
            Write-Output $row
        }
    } catch {
        Write-Error "Failed to process file $($file.FullName): $_"
    }
}