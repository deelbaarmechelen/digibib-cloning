
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Write-Host "Uw scripts staan op $ScriptDir"
$API_Key = Get-Content -Path $ScriptDir\API-key.ps1
$bearer_token = "$API_Key"
$Local_PC_Name =  $env:computername
$Local_PC_Name2 = "0"
$Serial_check = "0"
$Serial_Local =  gwmi win32_bios | select -ExpandProperty SerialNumber
$Serial_Inventory_Check = "2"
$Body_PUT = @{ 
serial = "$Serial_Local"
}
$header = @{"Authorization" ="Bearer "+$bearer_token}
$url = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/$Local_PC_Name"
$url2 = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/$Local_PC_Name2"
$url3 = "https://inventory.deelbaarmechelen.be/api/v1/hardware/byserial/$Serial_Local"
$Asset_tag_test = (Invoke-RestMethod -Method Get -Uri $url -Headers $header).asset_tag

If ($Asset_tag_test -eq $Local_PC_Name) {
Write-Host "bestaat al" <#Nog aan te passen#>
$Serial_check = "1"
}
Else {
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data Entry Form'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Geef de nieuwe PC_naam in:'
$form.Controls.Add($label)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textBox)
$form.Topmost = $true
$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)


{
    $Local_PC_Name2 = $textBox.Text
    $Local_PC_Name2
}


$url2 = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/$Local_PC_Name2"
$Asset_tag_test2 = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).asset_tag
$Serial_asset_check = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).serial


do{
If ($Asset_tag_test2 -eq $Local_PC_Name2 -and $Serial_Local -eq $Serial_asset_check ) {


rename-computer -NewName "$Local_PC_Name2" 
$env:computername
$response = "No"
$Serial_check = "2"

<# $ID = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).id
$url_PUT = "https://inventory.deelbaarmechelen.be/api/v1/hardware/$ID"
$Body_PUT = @{
serial = "$Serial_local"
} 
$Body_PUT_JSON = $Body_PUT | ConvertTo-Json
$ContentType = "application/json"
Invoke-RestMethod -Method PUT -Uri $url_PUT -Headers $header -Body $Body_PUT_JSON -ContentType $ContentType #>

exit}
Else{
Add-Type -AssemblyName PresentationFramework
$msgBoxInput =  [System.Windows.MessageBox]::Show('Computernaam was niet terug te vinden of serial nr. kwam niet overeen, opnieuw ingeven (YES) of script afbreken (NO)?','Deelbaarmechelen Clone station','YesNo','Error')
switch  ($msgBoxInput) { 'Yes' {
$response = "YES"
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data Entry Form'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Geef de nieuwe PC_naam in:'
$form.Controls.Add($label)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textBox)
$form.Topmost = $true
$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $Local_PC_Name2 = $textBox.Text
    $Local_PC_Name2

$url2 = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/$Local_PC_Name2"
$Asset_tag_test2 = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).asset_tag

}
} 'No' {exit}}


}
}

while ($response -eq "Yes")
}

$url2 = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/$Local_PC_Name2"


if($Serial_check -eq "1"){
$Serial_test = (Invoke-RestMethod -Method Get -Uri $url -Headers $header).serial
}
Else{
$Serial_test = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).serial
}


if ($Serial_test -eq $Serial_Local) {
Write-Host "Serienummer stemt overeen"
$Serial_Inventory_Check = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).total
<#Checken of serialnummer bij asset_tag hoort#>
<#Toekomstige PUT#>
}
Else {
Write-Host "Serienummer stemt niet overeen met asset"
<# Bestaat hij in inventory?#>
$Serial_Inventory_Check = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).total
<#Nee - Bericht nieuw aanmaken? L163#>
}

if ($Serial_Inventory_Check -ge 2){ 
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data Entry Form'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,40)
$label.Text = 'De locale serienummer komt meermaals voor in de inventory, hernoem de locale PC:'
$form.Controls.Add($label)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,60)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textBox)
$form.Topmost = $true
$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $GE1 = $textBox.Text
    $GE1
    rename-computer -NewName "$GE1" 
    $env:computername
}


}

if ($Serial_Inventory_Check -eq 1){<#PUT in de toekomst#>
Write-Host "Update local name"
$Inventory_PC_Name = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).rows.asset_tag
rename-computer -NewName "$Inventory_PC_Name" 
$env:computername

}

if ($Serial_Inventory_Check -eq 0){
Add-Type -AssemblyName PresentationFramework
$msgBoxInput =  [System.Windows.MessageBox]::Show('Serienummer staat niet in de inventaris, wilt u een volledig nieuwe asset aanmaken?','Deelbaarmechelen Clone station','YesNo','Error')
switch  ($msgBoxInput) { 'Yes' 
{
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data Entry Form'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'De Master-Clone die u wenst te kopieeren:'
$form.Controls.Add($label)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textBox)
$form.Topmost = $true
$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $textBox.Text
    $x
}


<#$form2 = New-Object System.Windows.Forms.Form
$form2.Text = 'Data Entry Form'
$form2.Size = New-Object System.Drawing.Size(300,200)
$form2.StartPosition = 'CenterScreen'
$okButton2 = New-Object System.Windows.Forms.Button
$okButton2.Location = New-Object System.Drawing.Point(75,120)
$okButton2.Size = New-Object System.Drawing.Size(75,23)
$okButton2.Text = 'OK'
$okButton2.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form2.AcceptButton = $OKButton2
$form2.Controls.Add($OKButton2)
$cancelButton2 = New-Object System.Windows.Forms.Button
$cancelButton2.Location = New-Object System.Drawing.Point(150,120)
$cancelButton2.Size = New-Object System.Drawing.Size(75,23)
$cancelButton2.Text = 'Cancel'
$cancelButton2.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form2.CancelButton = $cancelButton2
$form2.Controls.Add($cancelButton2)
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,20)
$label2.Size = New-Object System.Drawing.Size(280,20)
$label2.Text = 'De Clone die u wenst te maken:'
$form2.Controls.Add($label2)
$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Location = New-Object System.Drawing.Point(10,40)
$textBox2.Size = New-Object System.Drawing.Size(260,20)
$form2.Controls.Add($textBox2)
$form2.Topmost = $true2
$form2.Add_Shown({$textBox2.Select()})
$result2 = $form2.ShowDialog()
if ($result2 -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x2 = $textBox2.Text
    $x2
}
#>


$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Write-Host "Uw scripts staan op $ScriptDir"
$API_Key = Get-Content -Path $ScriptDir\API-key.ps1

$bearer_token = "$API_Key"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$header = @{"Authorization" ="Bearer "+$bearer_token}
<#
$url_GET = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/DB-20-001"
#>
$url_GET = "https://inventory.deelbaarmechelen.be/api/v1/hardware/bytag/$x"

Invoke-RestMethod -Method Get -Uri $url_GET -Headers $header


  
$url_POST = 'https://inventory.deelbaarmechelen.be/api/v1/klusbib/assets'
$GET_Start = (Invoke-RestMethod -Method Get -Uri $url_GET -Headers $header)
<#$Asset = "$x2"#>
$notes = ""
$status_id = $GET_Start.status_label.id
$model_id = $GET_Start.model.id
$Name =""
$OS = $GET_Start.custom_fields.os.value
$RU = $GET_Start.custom_fields.{regular user}.value
$RUP = $GET_Start.custom_fields.{Regular user password}.value
$AL = $GET_Start.custom_fields.{Admin login}.value
$AP = $GET_Start.custom_fields.{Admin password}.value
$TL = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\TeamViewer\).ClientID
$TP = $GET_Start.custom_fields.{Teamviewer Password}.value
$A = $GET_Start.custom_fields.Antivirus.value
$U = $GET_Start.custom_fields.Updates.value


$Body = @{
notes = "$notes"
status_id ="$status_id"
model_id = "$model_id"
serial = "$Serial_Local"
_snipeit_os_2 = "$OS"
_snipeit_regular_user_9 = "$RU"
_snipeit_regular_user_password_10 = "$RUP"
_snipeit_admin_login_7 = "$AL"
_snipeit_admin_password_8 = "$AP"
_snipeit_teamviewer_login_3 = "$TL"
_snipeit_teamviewer_password_4 = "$TP"
_snipeit_antivirus_5 = "$A"
_snipeit_updates_6 = "$U"

 }



Invoke-RestMethod -Method POST -Uri $url_POST -Headers $header -Body $Body 

$GET_local_Name= (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).rows.asset_tag
rename-computer -NewName "$GET_local_Name" 
$env:computername


<#Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Asset_Tag', "$x2"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_status_id', "$Status_id"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_model_id', "$Model_id"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_OS', "$custom_fields_OS"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1

Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Regular_user_password', "$custom_fields_Regular_User_Password"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Regular_User', "$custom_fields_Regular_User"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Admin_login', "$custom_fields_Admin_Login"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Admin_password', "$custom_fields_Admin_Password"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Teamviewer_password', "$custom_fields_Teamviewer_Password"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Antivirus', "$custom_fields_Antivirus"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Update', "$custom_fields_Updates"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1

(Get-Content -Path $ScriptDir\POST_3.ps1) |
    ForEach-Object {$_ -Replace 'Replace_Teamviewer_ID', "$custom_fields_Teamviewer_ID"} |
        Set-Content -Path $ScriptDir\POST_3.ps1
Get-Content -Path $ScriptDir\POST_3.ps1


#>

} 'No' {exit}}


}