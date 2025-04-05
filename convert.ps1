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
        # Import and process the CSV file as a stream
        $reader = [System.IO.StreamReader]::new($file.FullName)
        $writer = [System.IO.StreamWriter]::new((Join-Path -Path "$PSScriptRoot/output/" -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "-FCX" + [System.IO.Path]::GetExtension($file.Name))))

        # Read header line and write transformed header
        $header = $reader.ReadLine()
        $writer.WriteLine("Date,Time,Latitude,Longitude,Accuracy,Point,Source,Network,PLMN,Technology,Serving CID,LAC / TAC,Band Freq,Band Num,Channel,eNB / gNB,Sector ID,PSC / PCI,Power,Quality,N1_CID,N1_Channel,N1_PSC/PCI,N2_CID,N2_Channel,N2_PSC/PCI,N3_CID,N3_Channel,N3_PSC/PCI,N4_CID,N4_Channel,N4_PSC/PCI,N5_CID,N5_Channel,N5_PSC/PCI,N6_CID,N6_Channel,N6_PSC/PCI")

        $lineCount = 0
        # Process each line
        while (($line = $reader.ReadLine()) -ne $null) {
            # Parse CSV line into object
            $fields = $line -split ','
            $row = @{}
            $header -split ',' | ForEach-Object { $i = 0 } { $row[$_] = $fields[$i++] }

            # Skip if CellID/Serving CID or Latitude is empty or values are 0
            if (([string]::IsNullOrWhiteSpace($row.CellID) -and [string]::IsNullOrWhiteSpace($row.'Serving CID')) -or [string]::IsNullOrWhiteSpace($row.Latitude) -or ($row.CellID -eq "0" -and $row.'Serving CID' -eq "0") -or $row.Latitude -eq "0") { continue }

            $lineCount++
            # Get total line count if not already calculated
            if (-not $totalLines) {
                $totalLines = (Get-Content $file.FullName).Count - 1 # Subtract 1 for header
            }
            
            # Calculate percentage
            $percentComplete = [math]::Min(($lineCount / $totalLines) * 100, 100)

            # Show progress with percentage
            Write-Progress -Activity "Processing $($file.Name)" -Status "Processing line $lineCount of $totalLines ($([math]::Round($percentComplete))%)" -PercentComplete $percentComplete

            # If BoxID is empty then set Source to "Forensic Compass"
            if ([string]::IsNullOrWhiteSpace($row.BoxID)) {
                $row.BoxID = "Forensic Compass"
            }

            # If Point is populated then set it as a field
            if ($row.Point) {
                $row.Point = $row.Point
            } else {
                $row.Point = ''
            }

            # If Serviing CID exists then set it as CellID
            if ($row.'Serving CID') {
                $row.CellID = $row.'Serving CID'
            }

            # If BAND exists then set it as Band Freq
            if ($row.BAND) {
                $row.'Band Freq' = $row.BAND
            } else {
                $row.'Band Freq' = ''
            }

            # Transform the data
            # Extract PLMN from Network (MCC MNC) field if present
            $plmn = if ($row.'Network (MCC MNC)' -match '\((\d{3}\s\d{2})\)') {
                $matches[1] -replace '\s',''
                $row.PLMN = $matches[1] -replace '\s'
            } else {
                $row.PLMN
            }

            $network = switch ($plmn) {
                '23410' { 'O2 - UK' }
                '23415' { 'Vodafone UK' }
                '23420' { '3' }
                '23430' { 'EE' }
                '23433' { 'EE' }
                default { $row.Network }
            }

            $technology = if ($file.Name -like '*2G*') { '2G' }
                         elseif ($file.Name -like '*3G*') { '3G' }
                         elseif ($file.Name -like '*4G*') { '4G' }
                         else { '' }

            $channel = if ($row.EARFCN) { $row.EARFCN }
                      elseif ($row.UARFCN) { $row.UARFCN }
                      elseif ($row.ARFCN) { $row.ARFCN }
                      else { $row.Frequency }

            $power = if ($row.RSRP) { $row.RSRP }
                    elseif ($row.RSCP) { $row.RSCP }
                    elseif ($row.Power) { $row.Power }
                    elseif ($row['RSSI (dBm)']) { $row['RSSI (dBm)'] }
                    elseif ($row['RSCP (dBm)']) { $row['RSCP (dBm)'] }
                    else { '' }

            $quality = if ($row.RSRQ) { $row.RSRQ }
                      elseif ($row.ECIO) { $row.ECIO }
                      else { '' }

            # Write transformed line
            $transformedLine = @(
                $row.Date,               # Date
                $row.Time,               # Time
                $row.Latitude,           # Latitude
                $row.Longitude,          # Longitude
                $row.Satellites,         # Accuracy
                $row.Point,              # Point
                $row.BoxID,              # Source
                $network,                # Network
                $row.PLMN,               # PLMN
                $technology,             # Technology
                $row.CellID,             # Serving CID
                $(if ($row.TAC) { $row.TAC } else { $row.LAC }), # LAC / TAC
                $row.'Band Freq',        # Band Freq
                '',                      # Band Num
                $channel,                # Channel
                $row.eNB,                # eNB / gNB
                $row.ShortCellID,        # Sector ID
                $(if ($row.PSC) { $row.PSC } elseif ($row.BSIC) { $row.BSIC } else { $row.PCI }), # PSC / PCI
                $power,                  # Power
                $quality,                # Quality
                $(if ($row.A1_CellID) { $row.A1_CellID } else { $row.N1_CellID }), # N1_CID
                $(if ($row.N1_EARFCN) { $row.N1_EARFCN } elseif ($row.A1_Frequency) { $row.A1_Frequency } elseif ($row.A1_Freq) { $row.A1_Freq } elseif ($row.N1_ARFCN) { $row.N1_ARFCN } else { '' }), # N1_Channel
                $(if ($row.A1_PSC) { $row.A1_PSC } elseif ($row.N1_BSIC) { $row.N1_BSIC } else { $row.N1_PCI }), # N1_PSC/PCI
                $(if ($row.A2_CellID) { $row.A2_CellID } else { $row.N2_CellID }), # N2_CID
                $(if ($row.N2_EARFCN) { $row.N2_EARFCN } elseif ($row.A2_Frequency) { $row.A2_Frequency } elseif ($row.A2_Freq) { $row.A2_Freq } elseif ($row.N2_ARFCN) { $row.N2_ARFCN } else { '' }), # N2_Channel
                $(if ($row.A2_PSC) { $row.A2_PSC } elseif ($row.N2_BSIC) { $row.N2_BSIC } else { $row.N2_PCI }), # N2_PSC/PCI
                $(if ($row.A3_CellID) { $row.A3_CellID } else { $row.N3_CellID }), # N3_CID
                $(if ($row.N3_EARFCN) { $row.N3_EARFCN } elseif ($row.A3_Frequency) { $row.A3_Frequency } elseif ($row.A3_Freq) { $row.A3_Freq } elseif ($row.N3_ARFCN) { $row.N3_ARFCN } else { '' }), # N3_Channel
                $(if ($row.A3_PSC) { $row.A3_PSC } elseif ($row.N3_BSIC) { $row.N3_BSIC } else { $row.N3_PCI }), # N3_PSC/PCI
                $(if ($row.A4_CellID) { $row.A4_CellID } else { $row.N4_CellID }), # N4_CID
                $(if ($row.N4_EARFCN) { $row.N4_EARFCN } elseif ($row.A4_Frequency) { $row.A4_Frequency } elseif ($row.A4_Freq) { $row.A4_Freq } elseif ($row.N4_ARFCN) { $row.N4_ARFCN } else { '' }), # N4_Channel
                $(if ($row.A4_PSC) { $row.A4_PSC } elseif ($row.N4_BSIC) { $row.N4_BSIC } else { $row.N4_PCI }), # N4_PSC/PCI
                $(if ($row.A5_CellID) { $row.A5_CellID } else { $row.N5_CellID }), # N5_CID
                $(if ($row.N5_EARFCN) { $row.N5_EARFCN } elseif ($row.A5_Frequency) { $row.A5_Frequency } elseif ($row.A5_Freq) { $row.A5_Freq } elseif ($row.N5_ARFCN) { $row.N5_ARFCN } else { '' }), # N5_Channel
                $(if ($row.A5_PSC) { $row.A5_PSC } elseif ($row.N5_BSIC) { $row.N5_BSIC } else { $row.N5_PCI }), # N5_PSC/PCI
                $(if ($row.A6_CellID) { $row.A6_CellID } else { $row.N6_CellID }), # N6_CID
                $(if ($row.N6_EARFCN) { $row.N6_EARFCN } elseif ($row.A6_Frequency) { $row.A6_Frequency } elseif ($row.A6_Freq) { $row.A6_Freq } elseif ($row.N6_ARFCN) { $row.N6_ARFCN } else { '' }), # N6_Channel
                $(if ($row.A6_PSC) { $row.A6_PSC } elseif ($row.N6_BSIC) { $row.N6_BSIC } else { $row.N6_PCI }) # N6_PSC/PCI
            ) -join ','

            $writer.WriteLine($transformedLine)
        }
        Write-Progress -Activity "Processing $($file.Name)" -Completed

        Write-Output "Number of lines processed in $($file.Name): $lineCount"
        Write-Output "Processed file saved to: $($writer.BaseStream.Name)"

        # Clean up
        $reader.Close()
        $writer.Close()

    } catch {
        Write-Error "Failed to import or process file $($file.FullName): $_"
    }
}