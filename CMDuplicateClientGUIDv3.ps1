################################
#                              #
#         DISCLAIMER           #
#                              #
################################


<#

The following script is not supported under any Microsoft standard support program or service. 
The following script is provided AS IS without warranty of any kind. Microsoft further disclaims
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance 
of the following script and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for 
any damages whatsoever (including, without limitation, damages for loss of business profits,
business interruption, loss of business information, or other pecuniary loss) arising out of the
use of or inability to use the following script or documentation, even if Microsoft has been 
advised of the possibility of such damages.

© 2020 Microsoft. All rights reserved.

    .SCRIPTNAME 
        CMDuplicateClientGUID.ps1

    .AUTHOR
        Will Wellington

    .SYNOPSIS
        This script automates the fix action for Configuration Manager clients that contains duplicate GUIDs.

    .DESCRIPTION
        This script automates the fix action for Configuration Manager clients that contains duplicate GUIDs by recreating the SMSCFG.ini file on remote computers and performing the
        necessary steps to obtain a new GUID. Step by step actions are listed within the notes below. Part of this fix action REQUIRES the removal of Machine Certificates from the
        Local Machine\Personal store on remote computers. This will only remove the certificates that contains the FQDN within the subject name of the machine that it was issued to.
        If there are certificates within the store that are not set to auto-enroll, then these certificates will have to be requested manually.

    .INPUTS
        After running this script, this script only requests input for the Configuration Manager Site Code that the remote computers are located in.

    .OUTPUTS
        Actions and pre/post checks are logged to c:\CMDuplicateClientGuidLOGS\CM_PS_GUIDRefresh-Date-Time.log.

    .EXAMPLE
        1. Create CSV file with list of remote computers that require this fix action (Example of CSV format on next line)
        Computers
        ComputerName1
        ComputerName2
        ComputerName3
        2. Run Powershell ISE as Admin on Configuration Manager Site Server. 
        3. Modify line 148 to the path of CSV file, the default path is c:\temp\computers.txt
        4. Run Script
        5. Enter valid Configuration Manager Site Code into the pop-up

    .NOTES
        Actions performed by this script on the remote computers and Configuration Manager site server.
        1. Stops CcmExec service on remote computer.
        2. Removes c:\Windows\SMSCFG.ini from remote computer.
        3. Removes SMS certificates from Local Machine\SMS certificate store on remote computer (Removes SMS certificates with subject names containing SMS).
        4. Removes Personal certificates from Local Machine\Personal certificate store on remote computer. (Removes only machine certificates with subject names 
        that contain FQDN of remote computer)
        5. Removes Archived Personal certificates from Local Machine\Personal certificate store on remote computer. (Removes only machine certificates with subject names 
        that contain FQDN of remote computer)
        6. Removes remote computer from Configuration Manager Site Server
        7. Starts CcmExec service on remote computer.
#>

#Create Log Function
Function Write-DuplicateGUIDLog {
    param(
        [Parameter(Mandatory = $true)][String]$logMessage,
        [Parameter(Mandatory = $true)][String]$logFile
    )

    Add-Content $logFile $logMessage
}

#Create log file folder if it does not exist
$logFolderPath = "c:\CMDuplicateClientGuidLOGS"
$logFolderPathTest = Test-Path -Path $logFolderPath

If (!$logFolderPathTest) {
    New-Item -Path "c:\" -Name "CMDuplicateClientGuidLOGS" -ItemType "directory"
    Write-Host "$logFolderPath folder does not exist, creating Directory $logFolderPath" -ForegroundColor Cyan
    Write-Host "$logFolderPath Created" -ForegroundColor Green
}

#Create log file
$dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
$logFileName = "\CM_PS_GUIDRefresh"
$joinDateFileName = $logFileName + $dateTime
$logFileJoin = $joinDateFileName + ".log"
$logFile = $logFolderPath + $logFileJoin

If ((Test-Path $logFile) -eq $False) {
    New-Item -ItemType File -Path $logFile
}

Write-Host "$logFile created" -ForegroundColor Green
$logMessage = "$dateTime $logFile created"
Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

#Log current script running
$serverName = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname
$logMessage = "$dateTime $PSCommandPath running on $serverName"
Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

#Log current user context
$currentUserContext = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentUser = $currentUserContext.Name
$logMessage = "$dateTime $PSCommandPath running as $currentUser"
Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage


#Site Code popup *Will not proceed unless valid Site Code is Entered*
DO {
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    $title1 = 'Site Code'
    $msg1 = 'Please enter your Configuration Manager Site Code:'

    $siteCodeInput = [Microsoft.VisualBasic.Interaction]::InputBox($msg1, $title1)
    $siteCode = $null
    $siteCode = $siteCodeInput

    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
    Write-Host "Site Code entered is $siteCode" -ForegroundColor Green
    $logMessage = "$dateTime Site Code entered is $siteCode"
    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

    #Import Configuration Manager Module using SMS PSdrive based on Site Code
    Write-Host "Importing Configuration Manager Module..." -ForegroundColor Cyan
    $logMessage = "$dateTime Importing Configuration Manager Module"
    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

    $initParams = @{ }
    if ((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
    }

    $testSitePSDrivePath = Test-Path "$($SiteCode):\" @initParams
    Set-Location "$($SiteCode):\" @initParams

} While (!$testSitePSDrivePath)


#Import list of computers
$dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
$computerListPath = "c:\temp\computers.txt"
Write-Host "Importing Computers from $computerListPath..." -ForegroundColor Cyan
$logMessage = "$dateTime Importing Computers from $computerListPath"
Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
$computerList = import-csv $computerListPath

If (!$computerList.Computers) {
    Write-Host "$computerListPath is null or has invalid header, header should be Computers" -ForegroundColor Red
    $logMessage = "$dateTime Error: $computerListPath is $null"
    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
}
else {
    Write-Host "Computers Imported Successfully" -ForegroundColor Green
    $logMessage = "$dateTime Computers imported successfully"
    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
}



#Starts tests and actions on remote computers
foreach ($computer in $computerList.Computers) {

    #Test connectivity
    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
    Write-Host "Testing Connectivity to $computer..." -ForegroundColor Cyan
    $logMessage = "$dateTime Testing Connectivity to $computer"
    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
    $testConnection = Test-Connection -ComputerName $computer -Count 4 -Quiet

    If ($testConnection -eq $true) {
        $computerFQDN = [System.Net.Dns]::GetHostByName("$computer")
        $computerFQDN = $computerFQDN.HostName
        $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
        Write-Host "Connectivity to $computer Succeeded" -ForegroundColor Green 
        $logMessage = "$dateTime Connectivity to $computer Succeeded"
        Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
    }
    else {
        $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
        Write-Host "Connectivity to $computer Failed" -ForegroundColor Red
        $logMessage = "$dateTime Connectivity to $computer Failed"
        Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
        Write-Host "Checking for next Computer in $computerListPath..." -ForegroundColor Cyan
        $logMessage = "$dateTime Checking for next Computer in $computerListPath"
        Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
    }

    #Test if WinRm service is in running state			
    If ($testConnection -eq $true) {
        $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
        Write-Host "Verifying WinRm Service status on $computer..." -ForegroundColor Cyan
        $logMessage = "$dateTime Verifying WinRm Service status on $computer"
        Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
        $winRmServiceStatus = (Get-Service -ComputerName $computer -Name WinRm).Status

        If ($winRmServiceStatus -eq 'Running') {
            $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
            Write-Host "Status of WinRm is Running on $computer" -ForegroundColor Green 
            $logMessage = "$dateTime Status of WinRm is Running on $computer"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

        }
        else {

            #Starting WinRm service
            Write-Host "WinRm is in a Stopped state on $computer..." -ForegroundColor Cyan
            $logMessage = "$dateTime WinRm is in a Stopped state on $computer"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            
            Write-Host "Starting WinRm on $computer..." -ForegroundColor Cyan
            $logMessage = "$dateTime Starting WinRm on $computer"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            $winRmService = Get-Service -ComputerName $computer -Name WinRm
            $winRmService.Start()
            $winRmService.WaitForStatus('Running')
            $winRmServiceStatus = (Get-Service -ComputerName $computer -Name WinRm).Status

            #Verify WinRm is Running
            If ($winRmServiceStatus -eq 'Running') {
                Write-Host "WinRm is in a Running state on $computer..." -ForegroundColor Green
                $logMessage = "$dateTime WinRm is in a Running state on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }
            else {
                Write-Host "WinRm is in a Stopped state on $computer..." -ForegroundColor Red
                $logMessage = "$dateTime Error: WinRm is in a Stopped state on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Write-Host "Checking for next Computer in $computerListPath..." -ForegroundColor Cyan
                $logMessage = "$dateTime Checking for next Computer in $computerListPath"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }
        } 

        #Checking SMS Agent Host (CcmExec) service status
        If (Test-WSMan $computer -ErrorAction SilentlyContinue) {
            $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
            Write-Host "Checking status of CcmExec Service on $computer..." -ForegroundColor Cyan
            $logMessage = "$dateTime Checking status CcmExec Service on $computer"
            $smsServiceStatus = (Get-Service -ComputerName $computer -Name CcmExec).Status
            Write-Host "Status of CcmExec Service on $computer is $smsServiceStatus" -ForegroundColor Green
            $logMessage = "$dateTime Status of CcmExec Service on $computer is $smsServiceStatus"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

            #Stopping CcmExec service
            If ($smsServiceStatus -eq 'Running') {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Stopping CcmExec Service on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Stopping CcmExec Service on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                $ccmExecService = Get-Service -ComputerName $computer -Name CcmExec
                $ccmExecService.Stop()
                $ccmExecService.WaitForStatus('Stopped')

            }
            #Verifying CcmExec service is in stopped state
            $smsServiceStatus = (Get-Service -ComputerName $computer -Name CcmExec).Status
            If ($smsServiceStatus -eq 'Stopped') {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "CcmExec Service on $computer is in the Stopped state" -ForegroundColor Green
                $logMessage = "$dateTime CcmExec Service on $computer is in Stopped state"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }
            #Shows CcmExec is already in stopped state
            elseif ($smsServiceStatus -eq 'Stopped') {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "CcmExec Service on $computer is in the Stopped state" -ForegroundColor Green
                $logMessage = "$dateTime CcmExec Service on $computer is in Stopped state"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }

            #Test SMSCFG.ini file path on remote computer
            $SMSCFGPath = "c:\Windows\SMSCFG.ini"
            $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
            Write-Host "Verifying $SMSCFGPath exists on $computer..." -ForegroundColor Cyan
            $logMessage = "$dateTime Verifying $SMSCFGPath exists on $computer"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            $SMSCFGPathVerify = Invoke-Command -ComputerName $Computer -ScriptBlock { Test-Path $Using:SMSCFGPath }

            #Logs if SMSCFG.ini exists on remote computer
            If ($SMSCFGPathVerify -eq $true) {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "$SMSCFGPath exists on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime $SMSCFGPath exists on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

                #Remove SMSCFG.ini from remote computer
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Removing $SMSCFGPath from $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Removing $SMSCFGPath on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Invoke-Command -Computer "$computer" -ScriptBlock { Remove-Item $Using:SMSCFGPath -force }

                #Verify SMSCFG.ini has been removed
                $SMSCFGPathVerify = Invoke-Command -ComputerName $Computer -ScriptBlock { Test-Path $Using:SMSCFGPath }
                If ($SMSCFGPathVerify -eq $false) {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "$SMSCFGPath has been removed on $computer" -ForegroundColor Green
                    $logMessage = "$dateTime $SMSCFGPath has been removed from $computer"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
                else {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "$SMSCFGPath still exists on $computer..." -ForegroundColor Red
                    $logMessage = "$dateTime Error: $SMSCFGPath still exists on $computer"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
            }
            else {
                #Logs if SMSCFG.ini does not exist on remote computer
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "$SMSCFGPath does not exists on $computer..." -ForegroundColor Green
                $logMessage = "$dateTime Error: $SMSCFGPath does not exist on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }

            #Verify certificates within Local Machine\Personal Store on remote computer
            $personalStoreSubjectCount = Invoke-Command -ComputerName "$computer" -ScriptBlock { (Get-ChildItem -Path Cert:\LocalMachine\my -Recurse | Where-Object { $_.PSISContainer -eq $false } | Where-Object { $_.Subject -like "*$Using:computerFQDN*" } ).Count }

            If ($personalStoreSubjectCount -gt 0) {
                $personalStoreArray = $null
                $personalStoreSubjectList = Invoke-Command -ComputerName $computer -ScriptBlock {
                    $personalStoreArray = @()
                    (Get-ChildItem -Path Cert:\LocalMachine\my -Recurse | 
                        Where-Object { $_.PSISContainer -eq $false } |
                        Where-Object { $_.Subject -like "*$Using:computer*" } |

                        foreach-object ( {
                                $certProp = New-Object -TypeName PSObject
                                $certProp | Add-Member -MemberType NoteProperty -Name “Thumbprint” -Value $_.Thumbprint
                                $personalStoreArray += $certProp
                                $certProp = $null
                            }))
                    $personalStoreArray
                }
                
                $personalStoreThumbPrint = $personalStoreSubjectList.Thumbprint

                Write-Host "Searching for certificates in Local Machine\Personal store with subject name of $computerFQDN on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Searching for certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage


                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Verifying number of certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Verifying number of certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Write-Host "Number of certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer is $personalStoreSubjectCount" -ForegroundColor Green
                $logMessage = "$dateTime Number of certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer is $personalStoreSubjectCount"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

                foreach ($cert in $personalStoreThumbPrint) {   
                    Write-Host "Found Certificate $cert" -ForegroundColor Green
                    $logMessage = "$dateTime Found Certificate $cert"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
            }
       
            #Remove certificates with subject name of remote computer FQDN within Local Machine\Personal Store on remote computer
            If ($personalStoreSubjectCount -gt 0) {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Removing certificates from LocalMachine\Personal that contains subject name of $computerFQDN on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Removing certificates from LocalMachine\Personal that contains subject name of $computerFQDN on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Invoke-Command -ComputerName $computer -ScriptBlock { Get-ChildItem -Recurse Cert:\LocalMachine\my | Where-Object { $_.Subject -like "*$Using:computer*" } | Remove-Item }
                #Invoke-Command -ComputerName $computer -ScriptBlock { Get-ChildItem -Recurse Cert:\LocalMachine\my | Where-Object { $_.Status -like "**" } | Remove-Item }
                $personalStoreSubjectCount = Invoke-Command -ComputerName "$computer" -ScriptBlock { (Get-ChildItem -Path Cert:\LocalMachine\my -Recurse | Where-Object { $_.PSISContainer -eq $false } | Where-Object { $_.Subject -like "*$Using:computerFQDN*" } ).Count }

                #Verify certificates have been removed
                If ($personalStoreSubjectCount -eq 0) {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")

                    foreach ($cert in $personalStoreThumbPrint) {   
                        Write-Host "Removed certificate $cert" -ForegroundColor Green
                        $logMessage = "$dateTime Removed certificate $cert"
                        Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                    }

                    Write-Host "Certificates with subject name of $computerFQDN have been removed from LocalMachine\Personal store on $computer" -ForegroundColor Green
                    $logMessage = "$dateTime Certificates with subject name of $computerFQDN have been removed from LocalMachine\Personal store on $computer"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                    Write-Host "Number of certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $personalStoreSubjectCount" -ForegroundColor Green
                    $logMessage = "$dateTime Number of certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $personalStoreSubjectCount"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
                else {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "Certificates with subject name of $computerFQDN still exist in LocalMachine\Personal store on $computer" -ForegroundColor Red
                    $logMessage = "$dateTime Error: Certificates with subject name of $computerFQDN still exist in LocalMachine\Personal store on $computer"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                    Write-Host "Number of certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer is $personalStoreSubjectCount" -ForegroundColor Red
                    $logMessage = "$dateTime Error Number of certificates in LocalMachine\Personal store with subject name of $computerFQDN on $computer is $personalStoreSubjectCount"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
            }
            else {
                Write-Host "No certificates with subject name of $computerFQDN found in LocalMachine\Personal store on $computer" -ForegroundColor Green
                $logMessage = "$dateTime No certificates with subject name of $computerFQDN found in LocalMachine\Personal store on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }

            #Archive certificate check
            $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
            Write-Host "Searching for Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer" -ForegroundColor Cyan
            $logMessage = "$dateTime Searching for Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

            $archiveCertCount = Invoke-Command -ComputerName $computer -ScriptBlock { 
                $store = New-Object  System.Security.Cryptography.X509Certificates.X509Store "My", "LocalMachine"
                $MaxAllowedIncludeArchive = ([System.Security.Cryptography.X509Certificates.openflags]::MaxAllowed –bor [System.Security.Cryptography.X509Certificates.openflags]::IncludeArchived)
                $store.Open($MaxAllowedIncludeArchive)

                [System.Security.Cryptography.X509Certificates.X509Certificate2Collection] $certificates = $store.certificates | Where-Object { $_.Subject -like "*$Using:computerFQDN*" }
                $certificates.Count
            }

            $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
            Write-Host "Number of Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $archiveCertCount" -ForegroundColor Green
            $logMessage = "$dateTime Number of Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $archiveCertCount"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

            #Remove archived certificates that exist
            If ($archiveCertCount -gt 0) {
                $logMessage = "$dateTime Removing Archived certificates from LocalMachine\Personal that contains subject name of $computerFQDN on $computer..."
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Invoke-Command -ComputerName $computer -ScriptBlock { 
                    $store = New-Object  System.Security.Cryptography.X509Certificates.X509Store "My", "LocalMachine"
                    $MaxAllowedIncludeArchive = ([System.Security.Cryptography.X509Certificates.openflags]::MaxAllowed –bor [System.Security.Cryptography.X509Certificates.openflags]::IncludeArchived)
                    $store.Open($MaxAllowedIncludeArchive)

                    [System.Security.Cryptography.X509Certificates.X509Certificate2Collection] $certificates = $store.certificates | Where-Object { $_.Subject -like "*$Using:computerFQDN*" }

                    foreach ($cert in $certificates) {
                        if ($cert.Archived) {
                            Write-Host "Removing Archived certificates from LocalMachine\Personal that contains subject name of "$Using:computerFQDN" on "$Using:computer"" -ForegroundColor Cyan
                            $store.Remove($cert)
                            Write-Host "Removed Archived certificates from LocalMachine\Personal that contains subject name of "$Using:computerFQDN" on "$Using:computer"" -ForegroundColor Green
                        }

                    }
                    $store.Close()
                }

                #Archive certificate check
                $archiveCertCount = Invoke-Command -ComputerName $computer -ScriptBlock { 
                    $store = New-Object  System.Security.Cryptography.X509Certificates.X509Store "My", "LocalMachine"
                    $MaxAllowedIncludeArchive = ([System.Security.Cryptography.X509Certificates.openflags]::MaxAllowed –bor [System.Security.Cryptography.X509Certificates.openflags]::IncludeArchived)
                    $store.Open($MaxAllowedIncludeArchive)

                    [System.Security.Cryptography.X509Certificates.X509Certificate2Collection] $certificates = $store.certificates | Where-Object { $_.Subject -like "*$Using:computerFQDN*" }
                    $certificates.Count
                }

                #Confirm archive certificates have been removed
                If ($archiveCertCount -gt 0) {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "Number of Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $archiveCertCount" -ForegroundColor Red
                    $logMessage = "$dateTime Error: Number of Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $archiveCertCount"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
                else {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "Archived certificates removed, number of Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $archiveCertCount" -ForegroundColor Green
                    $logMessage = "$dateTime Archived certificates removed, number of Archived certificates with subject name of $computerFQDN in LocalMachine\Personal store on $computer is $archiveCertCount"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
            }

            #Verify certificates within Local Machine\SMS Store on remote computer
            $smsStoreSubjectCount = Invoke-Command -ComputerName "$computer" -ScriptBlock { (Get-ChildItem -Path Cert:\LocalMachine\sms -Recurse | Where-Object { $_.PSISContainer -eq $false } | Where-Object { $_.Subject -Like "*SMS*" } ).Count }
            

            If ($smsStoreSubjectCount -gt 0) {
                $smsStoreArray = $null
                $smsStoreSubjectList = Invoke-Command -ComputerName $computer -ScriptBlock {
                    $smsStoreArray = @()
                    (Get-ChildItem -Path Cert:\LocalMachine\sms -Recurse | 
                        Where-Object { $_.PSISContainer -eq $false } |
                        Where-Object { $_.Subject -Like "*SMS*" } |
                        
                        foreach-object ( {
                                $certProp = New-Object -TypeName PSObject
                                $certProp | Add-Member -MemberType NoteProperty -Name “Thumbprint” -Value $_.Thumbprint 
                                $smsStoreArray += $certProp
                                $certProp = $null
                            }))
                    $smsStoreArray
                }

                $smsStoreThumbPrint = $smsStoreSubjectList.Thumbprint

                Write-Host "Searching for certificates in Local Machine\SMS store with subject name containing SMS on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Searching for certificates in LocalMachine\SMS store with subject name containing SMS on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage


                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Verifying number of certificates in LocalMachine\SMS store with subject name containing SMS on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Verifying number of certificates in LocalMachine\SMS store with subject name containing SMS on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Write-Host "Number of certificates in LocalMachine\SMS store with subject name containing SMS on $computer is $smsStoreSubjectCount" -ForegroundColor Green
                $logMessage = "$dateTime Number of certificates in LocalMachine\SMS store with subject name containing SMS on $computer is $smsStoreSubjectCount"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage

                foreach ($cert in $smsStoreThumbPrint) {
                    Write-Host "Found Certificate $cert" -ForegroundColor Green
                    $logMessage = "$dateTime Found Certificate $cert"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
            }

            #Remove certificates that contains subject name of SMS within Local Machine\SMS Store on remote computer
            If ($smsStoreSubjectCount -gt 0) {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Removing certificates from LocalMachine\SMS that contains subject name of SMS on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Removing certificates from LocalMachine\SMS that contains subject name of SMS on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                Invoke-Command -ComputerName $computer -ScriptBlock { Get-ChildItem -Recurse Cert:\LocalMachine\sms | Where-Object { $_.Subject -Like "*SMS*" } | Remove-Item }
                $smsStoreSubjectCount = Invoke-Command -ComputerName "$computer" -ScriptBlock { (Get-ChildItem -Path Cert:\LocalMachine\my -Recurse | Where-Object { $_.PSISContainer -eq $false } | Where-Object { $_.Subject -Like "*SMS*" } ).Count }

                #Verify certificates have been removed
                If ($smsStoreSubjectCount -eq 0) {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")

                    foreach ($cert in $smsStoreThumbPrint) {   
                        Write-Host "Removed certificate $cert" -ForegroundColor Green
                        $logMessage = "$dateTime Removed certificate $cert"
                        Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                    }

                    Write-Host "Certificates with subject name containing SMS have been removed from LocalMachine\SMS store on $computer" -ForegroundColor Green
                    $logMessage = "$dateTime Certificates with subject name containing SMS have been removed from LocalMachine\SMS store on $computer"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                    Write-Host "Number of certificates with subject name containing SMS in LocalMachine\SMS store on $computer is $smsStoreSubjectCount" -ForegroundColor Green
                    $logMessage = "$dateTime Number of certificates with subject name containing SMS in LocalMachine\SMS store on $computer is $smsStoreSubjectCount"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
                else {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "Certificates with subject name containing SMS still exists in LocalMachine\SMS store on $computer" -ForegroundColor Red
                    $logMessage = "$dateTime Error: Certificates with subject name containing SMS still exists in LocalMachine\SMS store on $computer"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                    Write-Host "Number of certificates in LocalMachine\SMS store with subject name of SMS on $computer is $smsStoreSubjectCount" -ForegroundColor Red
                    $logMessage = "$dateTime Error Number of certificates in LocalMachine\SMS store with subject name of SMS on $computer is $smsStoreSubjectCount"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
            }
            else {
                Write-Host "No certificates with subject name containing SMS found on $computer" -ForegroundColor Green
                $logMessage = "$dateTime No certificates with subject name containing SMS found on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }

            #Verify computer exists in Configuration Manager
            $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
            Write-Host "Verifying if $computer exists within Configuration Manager..." -ForegroundColor Cyan
            $logMessage = "$dateTime Verifying if $computer exists within Configuration Manager"
            Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            $computerCM = Get-CMDevice -Name $computer

            If (!$computerCM) {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "$computer does not exist within Configuration Manager" -ForegroundColor Green
                $logMessage = "$dateTime $computer does not exist within Configuration Manager"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }
            else {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "$computer exists within Configuration Manager" -ForegroundColor Green
                $logMessage = "$dateTime $computer exists within Configuration Manager"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }

            #Removing computer from Configuration Manager
            If (!$computerCM) {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                $logMessage = "$dateTime $computer does not exist within Configuration Manager"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
            }
            else {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Removing $computer from Configuration Manager..." -ForegroundColor Cyan
                $logMessage = "$dateTime Removing $computer from Configuration Manager"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                $computerCM | Remove-CMDevice -Force

                #Verify computer has been removed from Configuration Manager
                $computerCM = Get-CMDevice -Name $computer
                If (!$computerCM) {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "$computer has been removed from Configuration Manager" -ForegroundColor Green
                    $logMessage = "$dateTime $computer has been removed from Configuration Manager"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }
                else {
                    $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                    Write-Host "$computer still exists within Configuration Manager" -ForegroundColor Red
                    $logMessage = "$dateTime Error $computer still exists within Configuration Manager"
                    Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                }

            }


            #Starting CcmExec service
            $smsServiceStatus = (Get-Service -ComputerName $computer -Name CcmExec).Status
            If ($smsServiceStatus -eq 'Stopped') {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "Starting CcmExec Service on $computer..." -ForegroundColor Cyan
                $logMessage = "$dateTime Starting CcmExec Service on $computer"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage
                $ccmExecService = Get-Service -ComputerName $computer -Name CcmExec
                $ccmExecService.Start()
                $ccmExecService.WaitForStatus('Running')
            }
            #Verify CcmExec service is in running state
            $smsServiceStatus = (Get-Service -ComputerName $computer -Name CcmExec).Status
            If ($smsServiceStatus -eq 'Running') {
                $dateTime = (Get-Date).ToString("dd-MMM-yyyy-HHmm-ss")
                Write-Host "CcmExec Service on $computer is in the Running state" -ForegroundColor Green
                $logMessage = "$dateTime CcmExec Service on $computer is in Running state"
                Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage




            }
        }
    }
}
#Complete message
Write-Host "$PSCommandPath Complete" -ForegroundColor Green
$logMessage = "$PSCommandPath Complete"
Write-DuplicateGUIDLog -logFile $logFile -logMessage $logMessage