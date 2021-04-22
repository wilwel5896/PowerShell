#Function that removes local ContentStore folders except for ignored folders that are defined. Copies Release\ContentStore content folders to local ContentStore.
#To build ContentStore based off of working branch within VSCode, CTRL-SHIFT-B, select build task "ContentStore". This should create a folder called "Release" within your local Repo, and will build the ContentStore there.

function CopyStore
{
    #Get ContentStore, and Release\ContentStore paths
    $rootPath = 'C:\'
    $contentStorePath = Join-Path -Path $rootPath -ChildPath 'ContentStore'
    $releaseStorePath = Join-Path -Path $rootPath -ChildPath 'Repos\Core\Release\ContentStore'

    #Ignore folders to avoid removal
    $ignore = @('DAC', 'Office', 'SQLServer2012', 'SystemCenter2016', 'WindowsServer2012', 'Wills Misc')
    Write-Host 'Folders that will be protected from removal' -ForegroundColor Green

    foreach($folder in $ignore)
    {
    Write-Host "$($folder)" -ForegroundColor Cyan
    }

    #Get folders within ContentStore not defined in ignore array
    $oldListOfFolders = Get-ChildItem $contentStorePath -Directory| Where-Object {$ignore -notcontains $_.Name}

    #Remove folders from ContentStore not defined in ignore array, while tracking progress
    Write-Host "Removing folders from $($contentStorePath)..." -ForegroundColor Green

    for ($i = 0; $i -lt $oldListOfFolders.count; $i++)
    {
        Write-Progress -Activity 'Removing folders...' -Status "Currently removing $($oldListOfFolders[$i].FullName) from $contentStorePath" -PercentComplete ($i / $oldListOfFolders.Count * 100)
        Remove-Item $oldListOfFolders[$i].FullName -Recurse -Force
        Write-Host "Removed folder $($oldListOfFolders[$i])" -ForegroundColor Cyan
    }

    #Get folders within ContentStore not defined in ignore array
    $currentOldListOfFolders = Get-ChildItem $contentStorePath -Directory| Where-Object {$ignore -notcontains $_.Name}

    #Verify folders have been removed
    If (!$currentOldListOfFolders)
    {
        Write-Host "$($oldListOfFolders.Count) folders have been removed from $($contentStorePath)" -ForegroundColor Green
    }
    else
    {
        Write-Host "All folders have not been removed from $($contentStorePath)" -ForegroundColor Red
    }

    #Get folders within Release\ContentStore
    $newListOfFolders = Get-ChildItem $releaseStorePath

    #Copy folders from Release\ContentStore to ContentStore, while tracking progress
    Write-Host "Copying folders from $($releaseStorePath) to $($contentStorePath)..." -ForegroundColor Green

    for ($i = 0; $i -lt $newListOfFolders.count; $i++)
    {
        Write-Progress -Activity "Copying folders..." -Status "Currently copying $($newListOfFolders[$i].FullName) to $contentStorePath" -PercentComplete ($i / $newListOfFolders.Count * 100)
        $newListOfFolders[$i].FullName | Copy-Item -Destination $contentStorePath -Recurse -Force
        Write-Host "Copied folder $($newListOfFolders[$i])" -ForegroundColor Cyan
    }

    #Get folders within ContentStore not defined in ignore array
    $currentNewListOfFolders = Get-ChildItem $contentStorePath -Directory| Where-Object {$ignore -notcontains $_.Name}

    #Verify folders have been copied
    If ($currentNewListOfFolders.Count -eq $newListOfFolders.Count)
    {
        Write-Host "$($newListOfFolders.Count) folders have been copied from $($releaseStorePath) to $($contentStorePath) successfully" -ForegroundColor Green
    }
    else
    {
        Write-Host "Number of folders in $($releaseStorePath) does not match the number of folders in $($contentStorePath)" -ForegroundColor Red
    }

    #All done
    Start-Sleep -s 3
}

CopyStore


