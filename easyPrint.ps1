# Hide Powershell window
$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

# Vars
$appName = "easyPrinter"
$printer = "" # example "name.myprinter.com" or "192.168.0.2"
$printerName = "" # Printer name
$domain = "" # Domain

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{ 

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '313,137'
$Form.text                       = $appName
$Form.TopMost                    = $true
$Form.StartPosition             = "CenterScreen"

$usernameLabel                   = New-Object system.Windows.Forms.Label
$usernameLabel.text              = "Username"
$usernameLabel.AutoSize          = $true
$usernameLabel.width             = 25
$usernameLabel.height            = 10
$usernameLabel.location          = New-Object System.Drawing.Point(3,8)
$usernameLabel.Font              = 'Microsoft Sans Serif,10'

$usernameTextbox                 = New-Object system.Windows.Forms.TextBox
$usernameTextbox.multiline       = $false
$usernameTextbox.width           = 235
$usernameTextbox.height          = 20
$usernameTextbox.location        = New-Object System.Drawing.Point(73,5)
$usernameTextbox.Font            = 'Microsoft Sans Serif,10'

$passwordLabel                   = New-Object system.Windows.Forms.Label
$passwordLabel.text              = "Password"
$passwordLabel.AutoSize          = $true
$passwordLabel.width             = 25
$passwordLabel.height            = 15
$passwordLabel.location          = New-Object System.Drawing.Point(3,43)
$passwordLabel.Font              = 'Microsoft Sans Serif,10'

$passwordTextbox                 = New-Object system.Windows.Forms.TextBox
$passwordTextbox.PasswordChar    = '*'
$passwordTextbox.multiline       = $false
$passwordTextbox.width           = 236
$passwordTextbox.height          = 20
$passwordTextbox.location        = New-Object System.Drawing.Point(72,40)
$passwordTextbox.Font            = 'Microsoft Sans Serif,10'

$statusTextbox                 = New-Object system.Windows.Forms.TextBox
$statusTextbox.multiline       = $false
$statusTextbox.width           = 304
$statusTextbox.height          = 10
$statusTextbox.Text            = "Status ready..."
$statusTextbox.Enabled         = $false
$statusTextbox.location        = New-Object System.Drawing.Point(3,72)
$statusTextbox.Font            = 'Microsoft Sans Serif,8'

<# $statusLabel                   = New-Object system.Windows.Forms.Label
$statusLabel.text              = "Status"
$statusLabel.AutoSize          = $true
$statusLabel.width             = 25
$statusLabel.height            = 10
$statusLabel.location          = New-Object System.Drawing.Point(3,92)
$statusLabel.Font              = 'Microsoft Sans Serif,10' #>

$infoButton                      = New-Object system.Windows.Forms.Button
$infoButton.text                 = "Info"
$infoButton.width                = 50
$infoButton.height               = 20
$infoButton.location             = New-Object System.Drawing.Point(200,100)
$infoButton.Font                 = 'Microsoft Sans Serif,10'

$saveButton                      = New-Object system.Windows.Forms.Button
$saveButton.text                 = "Save"
$saveButton.width                = 50
$saveButton.height               = 20
$saveButton.location             = New-Object System.Drawing.Point(258,100)
$saveButton.Font                 = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($usernameTextbox,$usernameLabel,$passwordTextbox,$passwordLabel,$statusTextbox,$statusLabel,$saveButton,$infoButton))

#region gui events {
#endregion events }

#endregion GUI }
$infoButton.Add_Click({
    # Info button
    #[System.Windows.Forms.MessageBox]::Show("Fill in username/password in order to install Printer.",$appName,1,48)
    $statusTextbox.text = "Fill in username/password in order to install Printer."
})

$saveButton.Add_Click({
$username = $usernameTextbox.text
$password = $passwordTextbox.text
$err0r = 0

if(!($username -and $password)){
	$statusTextbox.text = "Username and/or Password is missing, please try again..."
    $err0r = 1
}

Function Add-WinCreds {
        
        # Add credentials to Windows vault
        [string]$result = cmdkey /add:$printer /user:$username /pass:$password

	    if($result -match "CMDKEY: Credential added successfully"){
            $statusTextbox.text = "Printer credentials added successfully. Installing printer..."
	    } else{
            $statusTextbox.text = "Failed to add printer credentials to Windows vault."
            $err0r = 1
	    }

        if($err0r -eq 0){
            # Add printer
            try {
                Add-Printer -connectionname "\\$printer\$printerName" -ErrorAction Stop
                $statusTextbox.text = "Printer $printerName installed correctly."
			    [System.Windows.Forms.MessageBox]::Show("Printer $printerName installed successfully!",$appName,1,48)
			    [void]$Form.Close()
            } catch {
                $statusTextbox.text = "Failed to install $printerName!"
			    [System.Windows.Forms.MessageBox]::Show("Failed to install $printerName!",$appName,1,48)
			    [void]$Form.Close()
            }

        } else {
            $statusTextbox.text = "Failed to install $printerName!"
			[System.Windows.Forms.MessageBox]::Show("Failed to install $printerName!",$appName,1,48)
			[void]$Form.Close()
        }
}
    if($err0r -eq 0){
        # Verify credentials before adding them to credential manager
        $testConn = net use \\$printer\ipc$ /user:$username $password 2>&1
        if($testConn -like "Kommandot har*" -or $testConn -like "The command completed*"){
            net use /delete \\$printer
            # Success!
            Add-WinCreds
        } else {
            $statusTextbox.text = "Wrong username/password..."
			[System.Windows.Forms.MessageBox]::Show("Wrong username/password...",$appName,1,48)
        }

        
    }
})

[void]$Form.ShowDialog()
