A script to parse a mobile CSV file to format it for volunteer search app

# Setup

* Download the zip
* Unzip and add the files you want to convert to the data folder
* Shift+right-click in downloaded folder, then click open PowerShell window from here

Run the script with:

### On Windows
```powershell
.\convert.ps1
```

### On Mac
```powershell
pwsh ./convert.ps1
```

This will work with 3G and 4G files. They need to have 3G or 4G in the name for the the technology column.

Note all files will be deleted from the output folder when you are done.