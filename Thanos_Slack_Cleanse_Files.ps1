<#_______ _                           
|__   __| |                          
   | |  | |__   __ _ _ __   ___  ___ 
   | |  | '_ \ / _` | '_ \ / _ \/ __|
   | |  | | | | (_| | | | | (_) \__ \
   |_|  |_| |_|\__,_|_| |_|\___/|___/

   This script was created to remove attached files within our Slack group chat in order to stay under the free storage limit
#>

Import-module psslack

$mytoken = #Token goes here
$uri = #Uri goes here
$filesBefore = Get-SlackFileInfo -token $mytoken -paging
$filesBeforeCount = $filesBefore.count
Get-SlackFileInfo -token $mytoken -paging -Before (Get-Date).AddMonths(-2) | Remove-SlackFile -token $mytoken -force
$filesAfter = Get-SlackFileInfo -token $mytoken -paging
$filesRemaining = $filesAfter.count
$a = get-date
$totalSize = ($filesAfter | Measure-Object -Property Size -Sum -ErrorAction Stop).Sum / 1GB
$totalSize2 = "{0:N2} GB" -f ($totalSize)
$filesRemoved = $filesBeforeCount - $filesRemaining

$Complete = [pscustomobject]@{
    'Completion Time'    = "$a"
    'Files Removed'      = "$filesRemoved"
    'Files Remaining'    = "$filesRemaining"
    'Current Space Used' = "$totalSize2"
}

$Fields = @()
foreach($Prop in $Complete.psobject.Properties.Name)
{
    $Fields += @{
        title = $Prop
        value = $Complete.$Prop
        short = $true
    }
}

New-SlackMessageAttachment -Color "#350a4a" `
                           -Title 'File upload cleanse complete' `
                           -TitleLink https://www.youtube.com/watch?v=hCC6ZhRS7sY `
                           -Fields $Fields `
                           -Fallback 'Test' |
New-SlackMessage -Channel '@how-to' |
Send-SlackMessage -uri $uri

remove-module psslack