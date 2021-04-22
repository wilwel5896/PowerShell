<# 

Written by Will Wellington

Created to query all machine models that SCCM has in it's database, then allows the user to select the machine models they want to add to a specific collection variable.
The customers supported owned many different models, and in order to avoid typing mistakes, this was created.
In its current state, this script is to be used with demo data, to use in production lines 188-190 would have to be uncommented. 

Run on SCCM Site Server

#>

[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title1 = 'Site Code'
$msg1   = 'Please enter your Site Code:'

$siteCodeInput = [Microsoft.VisualBasic.Interaction]::InputBox($msg1, $title1)
$siteCode = $null
$siteCode = $siteCodeInput

#DEMO data
$modelList = import-csv C:\users\will.adm\Desktop\testmodelsbig.csv
#END DEMO Data Section

Write-Host "Starting Pre-Reqs" -ForegroundColor Green

#GUI Form/button properties
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '700,500'
$Form.text                       = "Model Add to Collection Variable tool"
$Form.TopMost                    = $false

$QueriedList                       = New-Object system.Windows.Forms.ListBox
$QueriedList.text                  = "listView"
$QueriedList.width                 = 270
$QueriedList.height                = 231
$QueriedList.location              = New-Object System.Drawing.Point(14,20)
$QueriedList.SelectionMode = 'MultiExtended'

$CustomList                       = New-Object system.Windows.Forms.ListBox
$CustomList.text                  = "listView"
$CustomList.width                 = 270
$CustomList.height                = 231
$CustomList.location              = New-Object System.Drawing.Point(400,23)
$CustomList.SelectionMode = 'MultiExtended'

$Add                             = New-Object system.Windows.Forms.Button
$Add.text                        = ">"
$Add.width                       = 21
$Add.height                      = 18
$Add.location                    = New-Object System.Drawing.Point(335,94)
$Add.Font                        = 'Microsoft Sans Serif,10'

$Remove                          = New-Object system.Windows.Forms.Button
$Remove.text                     = "<"
$Remove.width                    = 21
$Remove.height                   = 18
$Remove.location                 = New-Object System.Drawing.Point(335,170)
$Remove.Font                     = 'Microsoft Sans Serif,10'

$Submit                          = New-Object system.Windows.Forms.Button
$Submit.text                     = "Create"
$Submit.width                    = 60
$Submit.height                   = 30
$Submit.location                 = New-Object System.Drawing.Point(275,429)
$Submit.Font                     = 'Microsoft Sans Serif,10'

$Cancel                          = New-Object system.Windows.Forms.Button
$Cancel.text                     = "Cancel"
$Cancel.width                    = 60
$Cancel.height                   = 30
$Cancel.location                 = New-Object System.Drawing.Point(350,429)
$Cancel.Font                     = 'Microsoft Sans Serif,10'

$QueriedListLabel                          = New-Object system.Windows.Forms.Label
$QueriedListLabel.text                     = "Queried List"
$QueriedListLabel.AutoSize                 = $true
$QueriedListLabel.width                    = 25
$QueriedListLabel.height                   = 10
$QueriedListLabel.location                 = New-Object System.Drawing.Point(15,5)
$QueriedListLabel.Font                     = 'Microsoft Sans Serif,10'

$CustomListLabel                          = New-Object system.Windows.Forms.Label
$CustomListLabel.text                     = "Custom List"
$CustomListLabel.AutoSize                 = $true
$CustomListLabel.width                    = 25
$CustomListLabel.height                   = 10
$CustomListLabel.location                 = New-Object System.Drawing.Point(400,7)
$CustomListLabel.Font                     = 'Microsoft Sans Serif,10'

$CollectionNameBox                 = New-Object system.Windows.Forms.TextBox
$CollectionNameBox.multiline       = $false
$CollectionNameBox.enabled         = $false
$CollectionNameBox.width           = 220
$CollectionNameBox.height          = 20
$CollectionNameBox.location        = New-Object System.Drawing.Point(130,270)
$CollectionNameBox.Font            = 'Microsoft Sans Serif,10'
$CollectionNameBox.Text            = ""

$CollectionNameLabel               = New-Object system.Windows.Forms.Label
$CollectionNameLabel.text          = "Collection Name"
$CollectionNameLabel.AutoSize      = $true
$CollectionNameLabel.width         = 25
$CollectionNameLabel.height        = 10
$CollectionNameLabel.location      = New-Object System.Drawing.Point(20,274)
$CollectionNameLabel.Font          = 'Microsoft Sans Serif,10'

$CollectionIdComboBox                     = New-Object system.Windows.Forms.ComboBox
$CollectionIdComboBox.text                = "Enter or Select Collection Id"
$CollectionIdComboBox.width               = 220
$CollectionIdComboBox.height              = 20
$CollectionIdComboBox.location            = New-Object System.Drawing.Point(130,300)
$CollectionIdComboBox.Font                = 'Microsoft Sans Serif,10'
$CollectionIdComboBox.AutoCompleteSource  = 'ListItems'
$CollectionIdCOmboBox.AutoCompleteMode    = 'Append'

$CollectionIdLabel               = New-Object system.Windows.Forms.Label
$CollectionIdLabel.text          = "Collection ID"
$CollectionIdLabel.AutoSize      = $true
$CollectionIdLabel.width         = 25
$CollectionIdLabel.height        = 10
$CollectionIdLabel.location      = New-Object System.Drawing.Point(20,304)
$CollectionIdLabel.Font          = 'Microsoft Sans Serif,10'

$SiteCodeBox                 = New-Object system.Windows.Forms.TextBox
$SiteCodeBox.multiline       = $false
$SiteCodeBox.enabled         = $false
$SiteCodeBox.width           = 220
$SiteCodeBox.height          = 20
$SiteCodeBox.location        = New-Object System.Drawing.Point(130,330)
$SiteCodeBox.Font            = 'Microsoft Sans Serif,10'
$SiteCodeBox.Text            = "$siteCode"

$SiteCodeLabel               = New-Object system.Windows.Forms.Label
$SiteCodeLabel.text          = "Site Code"
$SiteCodeLabel.AutoSize      = $true
$SiteCodeLabel.width         = 25
$SiteCodeLabel.height        = 10
$SiteCodeLabel.location      = New-Object System.Drawing.Point(20,334)
$SiteCodeLabel.Font          = 'Microsoft Sans Serif,10'

$SupportTypeLabel               = New-Object system.Windows.Forms.Label
$SupportTypeLabel.text          = "Variable Name"
$SupportTypeLabel.AutoSize      = $true
$SupportTypeLabel.width         = 25
$SupportTypeLabel.height        = 10
$SupportTypeLabel.location      = New-Object System.Drawing.Point(380,275)
$SupportTypeLabel.Font          = 'Microsoft Sans Serif,10'

$SupportTypeComboBox                     = New-Object system.Windows.Forms.ComboBox
$SupportTypeComboBox.text                = "Select Support Type"
$SupportTypeComboBox.width               = 215
$SupportTypeComboBox.height              = 80
$SupportTypeComboBox.location            = New-Object System.Drawing.Point(480,271)
$SupportTypeComboBox.Font                = 'Microsoft Sans Serif,10'

$MSLogo                          = New-Object system.Windows.Forms.PictureBox
$MSLogo.width                    = 60
$MSLogo.height                   = 30
$MSLogo.location                 = New-Object System.Drawing.Point(315,468)
#$MSLogo.imageLocation            = "C:\Users\will.adm\Desktop\MSLogo.png"
$MSLogo.SizeMode                 = [System.Windows.Forms.PictureBoxSizeMode]::zoom

$MSLogo2                          = New-Object system.Windows.Forms.PictureBox
$MSLogo2.width                    = 120
$MSLogo2.height                   = 60
$MSLogo2.location                 = New-Object System.Drawing.Point(600,440)
#$MSLogo2.imageLocation            = "C:\Users\will.adm\Desktop\MSLogo2.png"
$MSLogo2.SizeMode                 = [System.Windows.Forms.PictureBoxSizeMode]::zoom

$MSLogo3                          = New-Object system.Windows.Forms.PictureBox
$MSLogo3.width                    = 120
$MSLogo3.height                   = 60
$MSLogo3.location                 = New-Object System.Drawing.Point(0.5,440)
#$MSLogo3.imageLocation            = "C:\Users\will.adm\Desktop\MSLogo3.jpg"
$MSLogo3.SizeMode                 = [System.Windows.Forms.PictureBoxSizeMode]::zoom

$Form.controls.AddRange(@($QueriedList,$CustomList,$Add,$Remove,$Submit,$QueriedListLabel,$CustomListLabel,$CollectionIdComboBox,$CollectionIdLabel,$SupportTypeComboBox,$SupportTypeLabel,$SiteCodeBox,$SiteCodeLabel,$CollectionNameBox,$CollectionNameLabel,$Cancel,$MSLogo,$MSLogo2,$MSLogo3))

#Import Module, Connect to ConfigMan drive
$initParams = @{}
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams}
            <#if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SMSServer @initParams 
    } #>
    Set-Location "$($SiteCode):\" @initParams

#Store ConfigMan site code working path for future use
$cmSiteLocation = (Get-Location).path

#Add Device Collection Id ComboBox
Write-Host "Gathering Collections..." -ForegroundColor Cyan
$DeviceCollections = $null
$DeviceCollections = Get-CMDeviceCollection 

Write-Host "Gathering Collection Ids..." -ForegroundColor Cyan
foreach ( $Id in $DeviceCollections.CollectionId)
{
$CollectionIdComboBox.Items.Add("$Id") | Out-Null
}
Write-Host "Pre-Reqs Complete" -ForegroundColor Green

#Action when Collection Id ComboBox is changed. Sets Collection Name textbox.
$CollectionIdComboBox.add_TextChanged({

If(!$CollectionIdCombobox)
{
$CollectionIdComboBoxSelected = $CollectionIdComboBox.SelectedItem
}
else 
{
$CollectionIdComboBoxSelected = $CollectionIdComboBox.Text
}

#$CollectionIdComboBoxSelected = $CollectionIdComboBox.SelectedItem
$GetCollectionById = Get-CMCollection -id "$CollectionIdComboBoxSelected"
$CollectionIdName = $GetCollectionById.Name 
$CollectionNameBox.Text = $CollectionIdName
})

#Add Support Type ComboBox Options
[void] $SupportTypeComboBox.Items.Add("SHBA_SHBSupportedModels")
[void] $SupportTypeComboBox.Items.Add("SHBA_OnlyUEFISupportedModels")
[void] $SupportTypeComboBox.Items.Add("SHBA_DellSupportedTPM")
[void] $SupportTypeComboBox.Items.Add("SHBA_HpSupportedTPM")

#Queried List Logic
foreach ($model in $modelList.model)  {

[void] $QueriedList.Items.Add($model)

}

#Button click to add to custom list
$Add.Add_Click({$ChosenItem=$QueriedList.SelectedItem;[void] $CustomList.Items.Add($ChosenItem);[void] $QueriedList.Items.Remove($ChosenItem)})


#Button click to remove from custom list
$Remove.Add_Click({$ChosenItem2=$CustomList.SelectedItem;[void] $QueriedList.Items.Add($ChosenItem2);[void] $CustomList.Items.Remove($ChosenItem2)})

#Button click to cancel form
$Cancel.Add_Click({$form.Close()})

#Button click to submit to collection variable by Collection Id
$Submit.Add_Click({

$SupportTypeComboBoxSelected = $SupportTypeComboBox.SelectedItem

    If(!$CollectionIdCombobox)
    {
    $CollectionIdComboBoxSelected = $CollectionIdComboBox.SelectedItem
    }
    else 
    {
    $CollectionIdComboBoxSelected = $CollectionIdComboBox.Text
    }    

    $GetCollectionVariables = $null
    $GetCollectionVariables = Get-CMDeviceCollectionVariable -CollectionId $CollectionIdComboBoxSelected

    #Error handling if collection variable already exists
    If($GetCollectionVariables.Name | Where-Object { $GetCollectionVariables.Name -like $SupportTypeComboBoxSelected})

    {

    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $DuplicateButtonType = [System.Windows.MessageBoxButton]::Ok
    $DuplicateboxTitle = “Collection Variable already exists”
    $Duplicateboxbody = “Collection Variable $SupportTypeComboBoxSelected already exists within Collection Id $CollectionIdComboBoxSelected”
    [System.Windows.MessageBox]::Show($Duplicateboxbody,$DuplicateboxTitle,$DuplicateButtonType,'Error')

    }

    else

    {

    New-CMDeviceCollectionVariable -CollectionId $CollectionIdComboBoxSelected -VariableName "$SupportTypeComboBoxSelected"

    $CustomListItems =  $CustomList.items
    $CustomListFormatted = $customlistitems.split("`n") -join ":"

    Set-CMDeviceCollectionVariable -CollectionId $CollectionIdComboBoxSelected -VariableName "$SupportTypeComboBoxSelected" -NewVariableValue "$CustomListFormatted"

    #Complete Message
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $CompleteButtonType = [System.Windows.MessageBoxButton]::Ok
    $CompleteboxTitle = “Models added successfully”
    $Completeboxbody = “Models have been added to the collection variable $SupportTypeComboBoxSelected within Collection Id: $CollectionIdComboBoxSelected”
    [System.Windows.MessageBox]::Show($Completeboxbody,$CompleteboxTitle,$CompleteButtonType)

    }

})

$form.ShowDialog()








