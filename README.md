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

This will work with 2G, 3G and 4G files. They need to have 2G or 3G or 4G in the name for the the technology column.

Note all files will be deleted from the output folder when you are done.

Large test files are here: https://1drv.ms/f/c/4752ca10e441ee13/EitmDcp-AJFNoihAoTxJTBUB8GinEnqOS4q5uioQ6CHvxA?e=rvXgIN

Dump of something that seems like a spec is here: https://1drv.ms/u/c/4752ca10e441ee13/Ea91Xf1AIkpNiASfAagGRSgBi2qWdzQtIx3dOY0eQdvyXw?e=000Zgn
