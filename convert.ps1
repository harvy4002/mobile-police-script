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

            # Skip if CellID is empty
            if ([string]::IsNullOrWhiteSpace($row.CellID)) { continue }

            $lineCount++
            # Get total line count if not already calculated
            if (-not $totalLines) {
                $totalLines = (Get-Content $file.FullName).Count - 1 # Subtract 1 for header
            }
            
            # Calculate percentage
            $percentComplete = [math]::Min(($lineCount / $totalLines) * 100, 100)
            
            # Show progress with percentage
            Write-Progress -Activity "Processing $($file.Name)" -Status "Processing line $lineCount of $totalLines ($([math]::Round($percentComplete))%)" -PercentComplete $percentComplete

            # Transform the data
            $network = switch ($row.PLMN) {
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
                      else { $row.Frequency }

            $power = if ($row.RSRP) { $row.RSRP }
                    elseif ($row.RSCP) { $row.RSCP }
                    else { '' }

            $quality = if ($row.RSRQ) { $row.RSRQ }
                      elseif ($row.ECIO) { $row.ECIO }
                      else { '' }

            # Write transformed line
            $transformedLine = @(
                $row.Date,
                $row.Time, 
                $row.Latitude,
                $row.Longitude,
                $row.Satellites,
                '',
                $row.BoxID,
                $network,
                $row.PLMN,
                $technology,
                $row.CellID,
                $(if ($row.TAC) { $row.TAC } else { $row.LAC }),
                '',
                '',
                $channel,
                $row.eNB,
                $row.ShortCellID,
                $(if ($row.PSC) { $row.PSC } else { $row.PCI }),
                $power,
                $quality,
                $(if ($row.A1_CellID) { $row.A1_CellID } else { $row.N1_CellID }),
                $(if ($row.N1_EARFCN) { $row.N1_EARFCN } elseif ($row.A1_Frequency) { $row.A1_Frequency } else { '' }),
                $(if ($row.A1_PSC) { $row.A1_PSC } else { $row.N1_PCI }),
                $(if ($row.A2_CellID) { $row.A2_CellID } else { $row.N2_CellID }),
                $(if ($row.N2_EARFCN) { $row.N2_EARFCN } elseif ($row.A2_Frequency) { $row.A2_Frequency } else { '' }),
                $(if ($row.A2_PSC) { $row.A2_PSC } else { $row.N2_PCI }),
                $(if ($row.A3_CellID) { $row.A3_CellID } else { $row.N3_CellID }),
                $(if ($row.N3_EARFCN) { $row.N3_EARFCN } elseif ($row.A3_Frequency) { $row.A3_Frequency } else { '' }),
                $(if ($row.A3_PSC) { $row.A3_PSC } else { $row.N3_PCI }),
                $(if ($row.A4_CellID) { $row.A4_CellID } else { $row.N4_CellID }),
                $(if ($row.N4_EARFCN) { $row.N4_EARFCN } elseif ($row.A4_Frequency) { $row.A4_Frequency } else { '' }),
                $(if ($row.A4_PSC) { $row.A4_PSC } else { $row.N4_PCI }),
                $(if ($row.A5_CellID) { $row.A5_CellID } else { $row.N5_CellID }),
                $(if ($row.N5_EARFCN) { $row.N5_EARFCN } elseif ($row.A5_Frequency) { $row.A5_Frequency } else { '' }),
                $(if ($row.A5_PSC) { $row.A5_PSC } else { $row.N5_PCI }),
                $(if ($row.A6_CellID) { $row.A6_CellID } else { $row.N6_CellID }),
                $(if ($row.N6_EARFCN) { $row.N6_EARFCN } elseif ($row.A6_Frequency) { $row.A6_Frequency } else { '' }),
                $(if ($row.A6_PSC) { $row.A6_PSC } else { $row.N6_PCI })
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