[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Write-Host "Uw scripts staan op $ScriptDir"

#uncomment to target test environment
$test_env = 'Y'
If ($test_env -eq 'Y') {
    $API_Key = Get-Content -Path $ScriptDir\API-test-key.ps1
    $baseUrl = "https://deelit.test.deelbaarmechelen.be"
}
Else {
    $API_Key = Get-Content -Path $ScriptDir\API-key.ps1
    $baseUrl = "https://deelit.deelbaarmechelen.be"
}    
$bearer_token = "$API_Key"
$Local_PC_Name = $env:computername
$Local_PC_Name2 = "0"
$Serial_check = "0"
$Serial_Local = Get-CIMInstance win32_bios | select -ExpandProperty SerialNumber
$Serial_Inventory_Check = "2"
$Body_PUT = @{ 
    serial = "$Serial_Local"
}
$Environment_variabel_OK = "0"
$Set_Master = "0"
$Environment_variabel = ${env:Test-DeelbaarM}
$Win10_Key = "0"
$Win10_Key_On_MotherBoard = "0"
$EindTextBox = "0"
$header = @{"Authorization" = "Bearer " + $bearer_token }
$url = $baseUrl + "/api/v1/hardware/bytag/$Local_PC_Name"
$url2 = $baseUrl + "/api/v1/hardware/bytag/$Local_PC_Name2"
$url3 = $baseUrl + "/api/v1/hardware/byserial/$Serial_Local"
$Asset_tag_test = (Invoke-RestMethod -Method Get -Uri $url -Headers $header).asset_tag



If ($Asset_tag_test -eq $Local_PC_Name) {
    Write-Host "bestaat al" <#Nog aan te passen#>
    $Serial_check = "1"
}
Else {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Data Entry Form'
    $form.Size = New-Object System.Drawing.Size(300, 200)
    $form.StartPosition = 'CenterScreen'
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75, 120)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150, 120)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $label.Text = 'Geef de nieuwe PC_naam in (zoals ingegeven in inventaris):'
    $form.Controls.Add($label)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 40)
    $textBox.Size = New-Object System.Drawing.Size(260, 20)
    $form.Controls.Add($textBox)
    $form.Topmost = $true
    $form.Add_Shown({ $textBox.Select() })
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $Local_PC_Name2 = $textBox.Text
        $Local_PC_Name2
    }


    $url2 = $baseUrl + "/api/v1/hardware/bytag/$Local_PC_Name2"
    $GET2_response = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header)
    $Asset_tag_test2 = $GET2_response.asset_tag
    $Serial_asset_check = $GET2_response.serial


    do {
        If ($Asset_tag_test2 -eq $Local_PC_Name2 -and $Serial_Local -eq $Serial_asset_check ) {


            rename-computer -NewName "$Local_PC_Name2" 
            $env:computername
            $response = "No"
            $Serial_check = "2"

        }
        Else {
            Add-Type -AssemblyName PresentationFramework
            $msgBoxInput = [System.Windows.MessageBox]::Show('Computernaam was niet terug te vinden of serial nr. kwam niet overeen, opnieuw ingeven (YES) of script afbreken (NO)?', 'Deelbaarmechelen Clone station', 'YesNo', 'Error')
            switch ($msgBoxInput) {
                'Yes' {
                    $response = "YES"
                    $form = New-Object System.Windows.Forms.Form
                    $form.Text = 'Data Entry Form'
                    $form.Size = New-Object System.Drawing.Size(300, 200)
                    $form.StartPosition = 'CenterScreen'
                    $okButton = New-Object System.Windows.Forms.Button
                    $okButton.Location = New-Object System.Drawing.Point(75, 120)
                    $okButton.Size = New-Object System.Drawing.Size(75, 23)
                    $okButton.Text = 'OK'
                    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                    $form.AcceptButton = $OKButton
                    $form.Controls.Add($OKButton)
                    $cancelButton = New-Object System.Windows.Forms.Button
                    $cancelButton.Location = New-Object System.Drawing.Point(150, 120)
                    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
                    $cancelButton.Text = 'Cancel'
                    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                    $form.CancelButton = $cancelButton
                    $form.Controls.Add($cancelButton)
                    $label = New-Object System.Windows.Forms.Label
                    $label.Location = New-Object System.Drawing.Point(10, 20)
                    $label.Size = New-Object System.Drawing.Size(280, 20)
                    $label.Text = 'Geef de nieuwe PC_naam in (zoals ingegeven in inventaris):'
                    $form.Controls.Add($label)
                    $textBox = New-Object System.Windows.Forms.TextBox
                    $textBox.Location = New-Object System.Drawing.Point(10, 40)
                    $textBox.Size = New-Object System.Drawing.Size(260, 20)
                    $form.Controls.Add($textBox)
                    $form.Topmost = $true
                    $form.Add_Shown({ $textBox.Select() })
                    $result = $form.ShowDialog()

                    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                        $Local_PC_Name2 = $textBox.Text
                        $Local_PC_Name2

                        $url2 = $baseUrl + "/api/v1/hardware/bytag/$Local_PC_Name2"
                        $Asset_tag_test2 = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).asset_tag

                    }
                } 'No' {
                    exit
                    <#Waarvoor dient deze exit#>
                }
            }


        }
    }

    while ($response -eq "Yes")
}

$url2 = $baseUrl + "/api/v1/hardware/bytag/$Local_PC_Name2"


if ($Serial_check -eq "1") {
    $Serial_test = (Invoke-RestMethod -Method Get -Uri $url -Headers $header).serial
}
Else {
    $Serial_test = (Invoke-RestMethod -Method Get -Uri $url2 -Headers $header).serial
}


if ($Serial_test -eq $Serial_Local) {
    Write-Host "Serienummer stemt overeen"
    $Serial_Inventory_Check = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).total
}
Else {
    Write-Host "Serienummer stemt niet overeen met asset"
    <# Bestaat hij in inventory?#>
    $Serial_Inventory_Check = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).total
    <#Nee - Bericht nieuw aanmaken? L163#>
}

if ($Serial_Inventory_Check -ge 2) { 
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Data Entry Form'
    $form.Size = New-Object System.Drawing.Size(300, 200)
    $form.StartPosition = 'CenterScreen'
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75, 120)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150, 120)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 40)
    $label.Text = 'De locale serienummer komt meermaals voor in de inventory, hernoem de locale PC:'
    $form.Controls.Add($label)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 60)
    $textBox.Size = New-Object System.Drawing.Size(260, 20)
    $form.Controls.Add($textBox)
    $form.Topmost = $true
    $form.Add_Shown({ $textBox.Select() })
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $GE1 = $textBox.Text
        $GE1
        rename-computer -NewName "$GE1" 
        $env:computername
    }


}

if ($Serial_Inventory_Check -eq 1) {
    <#PUT in de toekomst#>
    Write-Host "Update local name"
    $Inventory_PC_Name = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).rows.asset_tag
    rename-computer -NewName "$Inventory_PC_Name" 
    $env:computername
    $url_STATUS = (Invoke-RestMethod -Method Get -Uri $url -Headers $header)
    $status_id = $url_STATUS.status_label.id
    $url4 = $baseUrl + "/api/v1/hardware/bytag/$Inventory_PC_Name"
    $ID = (Invoke-RestMethod -Method Get -Uri $url4 -Headers $header).id
    $url_PUT = $baseUrl + "/api/v1/hardware/$ID"




    $Body_PUT = @{ 
        status_id = "$status_id" 
    }

    $Body_PUT_JSON = $Body_PUT | ConvertTo-Json
    $ContentType = "application/json"
    Invoke-RestMethod -Method PUT -Uri $url_PUT -Headers $header -Body $Body_PUT_JSON -ContentType $ContentType


}


If ($Environment_variabel -Match 'DB')
{ $Environment_variabel_OK = "1" }
Else
{ $Environment_variabel_OK = "0" }


if ($Serial_Inventory_Check -eq 0) {
    Add-Type -AssemblyName PresentationFramework
    $msgBoxInput = [System.Windows.MessageBox]::Show('Serienummer staat niet in de inventaris, wilt u een volledig nieuwe asset aanmaken?', 'Deelbaarmechelen Clone station', 'YesNo', 'Error')
    switch ($msgBoxInput) {
        'Yes' {
            If ($Environment_variabel_OK -eq 1)
            { $Set_Master = $Environment_variabel }
            Else {
                $form = New-Object System.Windows.Forms.Form
                $form.Text = 'Data Entry Form'
                $form.Size = New-Object System.Drawing.Size(300, 200)
                $form.StartPosition = 'CenterScreen'
                $okButton = New-Object System.Windows.Forms.Button
                $okButton.Location = New-Object System.Drawing.Point(75, 120)
                $okButton.Size = New-Object System.Drawing.Size(75, 23)
                $okButton.Text = 'OK'
                $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $form.AcceptButton = $OKButton
                $form.Controls.Add($OKButton)
                $cancelButton = New-Object System.Windows.Forms.Button
                $cancelButton.Location = New-Object System.Drawing.Point(150, 120)
                $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
                $cancelButton.Text = 'Cancel'
                $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                $form.CancelButton = $cancelButton
                $form.Controls.Add($cancelButton)
                $label = New-Object System.Windows.Forms.Label
                $label.Location = New-Object System.Drawing.Point(10, 20)
                $label.Size = New-Object System.Drawing.Size(280, 20)
                $label.Text = 'De Master-Clone die u wenst te kopieeren:'
                $form.Controls.Add($label)
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, 40)
                $textBox.Size = New-Object System.Drawing.Size(260, 20)
                $form.Controls.Add($textBox)
                $form.Topmost = $true
                $form.Add_Shown({ $textBox.Select() })
                $result = $form.ShowDialog()
                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    $x = $textBox.Text
                    $x
                }
            }

            $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
            Write-Host "Uw scripts staan op $ScriptDir"
            #$API_Key = Get-Content -Path $ScriptDir\API-key.ps1

            $bearer_token = "$API_Key"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


            $header = @{"Authorization" = "Bearer " + $bearer_token }

            If ($Environment_variabel_OK -eq 1) { $url_GET = $baseUrl + "/api/v1/hardware/bytag/$Set_Master" }
            Else
            { $url_GET = $baseUrl + "/api/v1/hardware/bytag/$x" }

            Invoke-RestMethod -Method Get -Uri $url_GET -Headers $header


  
            $url_POST = $baseUrl + '/api/v1/hardware'
            $GET_Start = (Invoke-RestMethod -Method Get -Uri $url_GET -Headers $header)
            <#$Asset = "$x2"#>
            $notes = ""
            $status_id = $GET_Start.status_label.id
            $model_id = $GET_Start.model.id
            $Name = ""
            $OS = $GET_Start.custom_fields.os.value
            $RU = $GET_Start.custom_fields. { regular user }.value
            $RUP = $GET_Start.custom_fields. { Regular user password }.value
            $AL = $GET_Start.custom_fields. { Admin login }.value
            $AP = $GET_Start.custom_fields. { Admin password }.value
            $A = $GET_Start.custom_fields.Antivirus.value
            $U = $GET_Start.custom_fields.Updates.value


            $Body = @{
                company_id                        = 2
                notes                             = "$notes"
                status_id                         = "$status_id"
                model_id                          = "$model_id"
                serial                            = "$Serial_Local"
                _snipeit_os_2                     = "$OS"
                _snipeit_regular_user_9           = "$RU"
                _snipeit_regular_user_password_10 = "$RUP"
                _snipeit_admin_login_7            = "$AL"
                _snipeit_admin_password_8         = "$AP"
                _snipeit_antivirus_5              = "$A"
                _snipeit_updates_6                = "$U"

            }



            $POST_response = (Invoke-RestMethod -Method POST -Uri $url_POST -Headers $header -Body $Body) 
            Write-Host "POST response is $POST_response"

            $GET_local_Name = (Invoke-RestMethod -Method Get -Uri $url3 -Headers $header).rows.asset_tag
            rename-computer -NewName "$GET_local_Name" 
            Write-Host "Oude naam is $env:computername"
            Write-Host "Nieuwe naam is $Get_local_Name"
            $EindTextBox = "1"

            slmgr /xpr

            $Win10_Key = (Get-CIMInstance -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
            If ($Win10_Key -match "0")
            { $Win10_Key_On_MotherBoard = "0" }
            Else
            { $Win10_Key_On_MotherBoard = "1" }


            If ($EindTextBox -match "1") {
                Add-Type -AssemblyName PresentationFramework
                $msgBoxInput = [System.Windows.MessageBox]::Show("Het script heeft correct gelopen; nieuwe PC-naam is $Get_local_Name; Win10_Key is $Win10_Key", 'Deelbaarmechelen Clone station', 'YesNo', 'Error')
            }



        } 'No' {
            exit
            <#Waarvoor dient deze exit#>
        }
    }


}