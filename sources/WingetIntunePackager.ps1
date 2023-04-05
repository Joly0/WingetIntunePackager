<#
.SYNOPSIS
Package Winget App to Intune with Winget-Install

.DESCRIPTION
https://github.com/Romanitho/Winget-Intune-Packager
#>

### APP INFO ###

#Winget Intune Packager version
$Script:WingetPackager = "1.0.0"
#Winget-Install Github Link
$Script:WIGithubLink = "https://github.com/Romanitho/Winget-Install/archive/refs/tags/v1.10.1.zip"
#Temp folder
$Script:Location = "$Env:ProgramData\WingetIntunePackagerTemp"
#Load assemblies
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, PresentationFramework


### FUNCTIONS ###

function Start-InstallGUI {

    ### FORM CREATION ###

    # Where is the GUI XAML file?
    $inputXML = @"
<Window x:Class="Winget_Intune_Packager.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Winget_Intune_Packager"
        mc:Ignorable="d"
        Title="Winget Intune Packager {0}" Height="490" Width="710" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.Background>
            <SolidColorBrush Color="#FFF0F0F0"/>
        </Grid.Background>
        <Label x:Name="SearchLabel" Content="Search for an app on Winget Repo:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,10,0,0"/>
        <TextBox x:Name="SearchTextBox" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,36,0,0" Width="570" Height="24" VerticalContentAlignment="Center"/>
        <Button x:Name="SearchButton" Content="Search" HorizontalAlignment="Right" VerticalAlignment="Top" Width="90" Height="24" Margin="0,36,10,0" IsDefault="True"/>
        <Label x:Name="SubmitLabel" Content="Select the matching Winget AppID (--id):" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,70,0,0"/>
        <Button x:Name="CheckButton" Content="Check" HorizontalAlignment="Right" VerticalAlignment="Top" Width="90" Height="24" Margin="0,96,10,0"/>
        <Button x:Name="IconButton" Content="Select Icon" HorizontalAlignment="Right" Width="90" Height="24" Margin="0,250,10,0" VerticalAlignment="Top"/>
        <Button x:Name="ClearButton" Content="Clear Icon" HorizontalAlignment="Right" Width="90" Height="24" Margin="0,279,10,0" VerticalAlignment="Top"/>
        <Button x:Name="InstalledAppButton" Content="List installed" HorizontalAlignment="Right" VerticalAlignment="Bottom" Width="90" Height="24" Margin="0,0,10,10"/>
        <ComboBox x:Name="IDComboBox" HorizontalAlignment="Left" Margin="10,96,0,0" VerticalAlignment="Top" Width="340" Height="24" IsEditable="True"/>
        <Button x:Name="CloseButton" Content="Close" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,10,10" Width="90" Height="24"/>
        <Button x:Name="CreateButton" Content="Create" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,105,10" Width="90" Height="24" IsEnabled="False"/>
        <TextBlock x:Name="GithubLinkLabel" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="10,0,0,14">
            <Hyperlink NavigateUri="https://github.com/Romanitho/Winget-Install-GUI">We are on GitHub</Hyperlink>
        </TextBlock>
        <Label x:Name="VersionLabel" Content="[Optional] Specify version (--version):" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="360,70,0,0"/>
        <TextBox x:Name="VersionTextBox" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="360,96,0,0" Width="220" Height="24" VerticalContentAlignment="Center"/>
        <Label x:Name="OverrideLabel" Content="[Optional] Specify arguments to pass directly to the installer (--override):" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,130,0,0"/>
        <TextBox x:Name="OverrideTextBox" VerticalAlignment="Top" Margin="10,156,0,0" Height="24" VerticalContentAlignment="Center" Width="570" HorizontalAlignment="Left"/>
        <Label x:Name="IntuneDescriptionLabel" Content="[Optional] Intune package description:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,190,0,0"/>
        <TextBox x:Name="IntuneDescriptionTextBox" HorizontalAlignment="Left" Margin="10,216,0,0" Width="570" Height="48" VerticalScrollBarVisibility="Auto" TextWrapping="WrapWithOverflow" VerticalAlignment="Top"/>
        <Label x:Name="IntuneTenantIDLabel" Content="Intune Tenant ID:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,304,0,0"/>
        <TextBox x:Name="IntuneTenantIDTextbox" VerticalAlignment="Top" Margin="10,330,10,0" Height="24" VerticalContentAlignment="Center" Width="570" HorizontalAlignment="Left"/>
        <Label x:Name="HelpTenantIDLabel" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="110,304,0,0">
            <Hyperlink NavigateUri="https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-to-find-tenant">Help?</Hyperlink>
        </Label>
        <CheckBox x:Name="WhitelistCheckbox" Content="Add to WAU WhiteList ?" HorizontalAlignment="Left" Margin="10,280,0,0" VerticalAlignment="Top"/>
        <Label x:Name="HelpWhitelistLabel" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="162,274,0,0">
            <Hyperlink NavigateUri="https://github.com/Romanitho/Winget-AutoUpdate#configurations">
                <Run Text="Help?"/>
            </Hyperlink>
        </Label>
        <Grid x:Name="GridIcon" VerticalAlignment="Top" HorizontalAlignment="Right" Width="90" Height="90" Margin="0,152,10,0" Background="White">
            <Image x:Name="AppIcon" Height="90" Width="90" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Grid>
        <Button x:Name="ConnectButton" Content="Connect" HorizontalAlignment="Right" VerticalAlignment="Top" Width="90" Height="24" Margin="0,330,10,0"/>
        <TextBlock x:Name="ConnectionStatusTextBlock" HorizontalAlignment="Left" Margin="10,354,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Text="Not connected." Foreground="Red"/>

    </Grid>
</Window>
"@

    #Create window
    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    [xml]$XAML = $inputXML -f $WingetPackager

    #Read the form
    $Reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $WingetIntunePackagerForm = [Windows.Markup.XamlReader]::Load($reader)
    $WingetIntunePackagerForm.Icon = $IconBase64

    #Store Form Objects In PowerShell
    $FormObjects = $xaml.SelectNodes("//*[@Name]")
    $FormObjects | ForEach-Object {
        Set-Variable -Name "$($_.Name)" -Value $WingetIntunePackagerForm.FindName($_.Name) -Scope Script
    }

    #Icon Dialog box
    $OpenIconDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenIconDialog.Filter = "Image Files (*.jpg,*.jpeg,*.png)|*.jpg;*.jpeg;*.png"


    ### FORM ACTIONS ###

    $SearchButton.add_click({
            if ($SearchTextBox.Text) {
                $IDComboBox.Items.Clear()
                Start-PopUp "Searching..."
                $IDComboBox.Foreground = "Black"
                $IDComboBox.Tag = $null
                $AppIcon.Source = $null
                $IntuneDescriptionTextBox.Text = $null
                $List = Get-WingetAppList $SearchTextBox.Text
                foreach ($L in $List) {
                    $IDComboBox.Items.Add($L.ID)
                }
                $IDComboBox.SelectedIndex = 0
                Close-PopUp
            }
        })

    $CheckButton.add_click({
            if ($IDComboBox.text) {
                $IntuneDescriptionTextBox.Text = ""
                Start-PopUp "Checking..."
                Get-WingetAppInfo $IDComboBox.Text $VersionTextBox.Text
                if ($AppInfo.id) {
                    if ($AppInfo.Description) {
                        $IntuneDescriptionTextBox.Text = $AppInfo.Description
                    }
                    else {
                        $IntuneDescriptionTextBox.Text = $AppInfo.ShortDescription
                    }
                    $IDComboBox.Foreground = "Green"
                    $IDComboBox.Tag = "Ok"
                    $VersionTextBox.Foreground = "Green"
                    $AppIcon.Source = $AppInfo.Icon
                    if ($ConnectionStatusTextBlock.Tag -eq "Ok") {
                        $CreateButton.IsEnabled = $true
                    }
                }
                else {
                    $IDComboBox.Foreground = "Red"
                    $IDComboBox.Tag = $null
                    $VersionTextBox.Foreground = "Red"
                    $CreateButton.IsEnabled = $false
                }
                Close-PopUp
            }
        })

    $IconButton.add_click({
            $response = $OpenIconDialog.ShowDialog() # $response can return OK or Cancel
            if ( $response -eq 'OK' ) {
                $AppIcon.Source = $AppInfo.Icon = $OpenIconDialog.FileName
            }
        })

    $ClearButton.add_click({
            $AppIcon.Source = $AppInfo.Icon = $null
        })

    $ConnectButton.add_click({
            Start-PopUp "Connecting..."
            $ConnectionStatus = Connect-MSIntuneGraph -TenantID $IntuneTenantIDTextbox.Text
            if ($ConnectionStatus.ExpiresOn) {
                $ConnectionStatusTextBlock.Foreground = "Green"
                $ConnectionStatusTextBlock.Text = "Connection expires on: $($ConnectionStatus.ExpiresOn.ToLocalTime())"
                $ConnectionStatusTextBlock.Tag = "Ok"
                if ($IDComboBox.Tag -eq "Ok") {
                    $CreateButton.IsEnabled = $true
                }
            }
            else {
                $ConnectionStatusTextBlock.Foreground = "Red"
                $ConnectionStatusTextBlock.Text = "Not connected."
                $ConnectionStatusTextBlock.Tag = $null
                $CreateButton.IsEnabled = $false
            }
            Close-PopUp
        })

    $HelpWhitelistLabel.Add_PreviewMouseDown({
            [System.Diagnostics.Process]::Start("https://github.com/Romanitho/Winget-AutoUpdate#configurations")
        })

    $HelpTenantIDLabel.Add_PreviewMouseDown({
            [System.Diagnostics.Process]::Start("https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-to-find-tenant")
        })

    $CreateButton.add_click({
            Start-PopUp "Creating app to Intune... Please wait"
            $AppConfig = $($AppInfo.id)
            if ($VersionTextBox.Text) {
                $AppConfig += " --version $($VersionTextBox.Text)"
            }
            if ($OverrideTextBox.Text) {
                $AppConfig += " --override \""$($OverrideTextBox.Text)\"""
            }
            $InstallCmd = """%systemroot%\sysnative\WindowsPowerShell\v1.0\powershell.exe"" -NoProfile -ExecutionPolicy Bypass -File winget-install.ps1 -AppIDs ""$AppConfig"""
            if ($WhitelistCheckbox.IsChecked) {
                $InstallCmd += " -WAUWhiteList"
            }
            $Win32AppArgs = @{
                "Description"          = $IntuneDescriptionTextBox.Text
                "AppVersion"           = $VersionTextBox.Text
                "Notes"                = $WIGithubLink
                "InstallCommandLine"   = $InstallCmd
                "UninstallCommandLine" = """%systemroot%\sysnative\WindowsPowerShell\v1.0\powershell.exe"" -NoProfile -ExecutionPolicy Bypass -File winget-install.ps1 -AppIDs ""$($AppInfo.id)"" -Uninstall"
                "Verbose"              = $false
            }
            Invoke-IntunePackage $Win32AppArgs
            $AppInfo = @()
            $SearchTextBox.Text = ""
            $IDComboBox.Text = ""
            $IDComboBox.Items.Clear()
            $VersionTextBox.Text = ""
            $OverrideTextBox.Text = ""
            $IntuneDescriptionTextBox.Text = ""
            $WhitelistCheckbox.IsChecked = $false
            $CreateButton.IsEnabled = $false
            $AppIcon.Source = $null
            Close-PopUp
        })

    $CloseButton.add_click({
            $WingetIntunePackagerForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $WingetIntunePackagerForm.Close()
            Sleep 3
        })

    # Shows the form
    $WingetIntunePackagerForm.ShowDialog() | Out-Null
    $WingetIntunePackagerForm = $null
}

Function Start-PopUp ($Message) {

    if (!$Window) {

        #Create window
        $inputXML = @"
<Window x:Class="WiGui_v3.PopUp"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WiGui_v3"
        mc:Ignorable="d"
        Title="WiGui {0}" Width="260" Height="130" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" Topmost="True">
    <Grid>
        <TextBlock x:Name="PopUpLabel" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10"/>

    </Grid>
</Window>
"@

        $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
        [xml]$XAML = $inputXML -f $WiGuiVersion

        #Read the form
        $Reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $Script:PopUpWindow = [Windows.Markup.XamlReader]::Load($reader)
        $PopUpWindow.Icon = $IconBase64

        #Store Form Objects In PowerShell
        $XAML.SelectNodes("//*[@Name]") | foreach {
            Set-Variable -Name "$($_.Name)" -Value $PopUpWindow.FindName($_.Name) -Scope Script
        }

        $PopUpWindow.Show()
    }
    #Message to display
    $PopUpLabel.Text = $Message
    #Update PopUp
    $PopUpWindow.Dispatcher.Invoke([action] {}, "Render")
}

Function Close-PopUp {
    $Script:PopUpWindow.Close()
    $Script:PopUpWindow = $null
}

function Get-GithubRepository ($Url) {

    # Force to create a zip file
    $ZipFile = "$Location\temp.zip"
    New-Item $ZipFile -ItemType File -Force | Out-Null

    # Download the zip
    Invoke-RestMethod -Uri $Url -OutFile $ZipFile

    # Extract Zip File
    Expand-Archive -Path $ZipFile -DestinationPath $Location -Force
    Get-ChildItem -Path $Location -Recurse | Unblock-File

    # remove the zip file
    Remove-Item -Path $ZipFile -Force
}

function Get-WingetCmd {

    #WinGet Path (if User/Admin context)
    $UserWingetPath = Get-Command winget.exe -ErrorAction SilentlyContinue
    #WinGet Path (if system context)
    $SystemWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"

    #Get Winget Location in User/Admin context
    if ($UserWingetPath) {
        $Script:Winget = $UserWingetPath.Source
    }
    #Get Winget Location in System context
    elseif ($SystemWingetPath) {
        #If multiple version, pick last one
        $Script:Winget = $SystemWingetPath[-1].Path
    }
    else {
        Write-Host "WinGet is not installed!"
        break
    }

}

function Get-WingetAppList ($SearchApp) {
    class Software {
        [string]$Name
        [string]$Id
    }

    #Check if App and Version exists
    if ($SearchApp.Length -lt "2") {
        Write-Host "Please enter at least 2 characters"
        return
    }

    #Search for winget apps
    $AppResult = & $Winget search $SearchApp --accept-source-agreements --source winget

    #Start Convertion of winget format to an array. Check if "-----" exists
    if (!($AppResult -match "-----")) {
        Write-Host "No application found."
        return
    }

    #Split winget output to lines
    $lines = $AppResult.Split([Environment]::NewLine) | Where-Object { $_ }

    # Find the line that starts with "------"
    $fl = 0
    while (-not $lines[$fl].StartsWith("-----")) {
        $fl++
    }

    $fl = $fl - 1

    #Get header titles
    $index = $lines[$fl] -split '\s+'

    # Line $fl has the header, we can find char where we find ID and Version
    $idStart = $lines[$fl].IndexOf($index[1])
    $versionStart = $lines[$fl].IndexOf($index[2])

    # Now cycle in real package and split accordingly
    $searchList = @()
    For ($i = $fl + 2; $i -le $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line.Length -gt ($sourceStart + 5)) {
            $software = [Software]::new()
            $software.Name = $line.Substring(0, $idStart).TrimEnd()
            $software.Id = $line.Substring($idStart, $versionStart - $idStart).TrimEnd()
            #add formated soft to list
            $searchList += $software
        }
    }
    return $searchList
}

function Get-WingetAppInfo ($AppID, $AppVersion) {

    $Script:AppInfo = @{}

    #Search for winget apps
    if ($AppVersion) {
        $AppResult = & $Winget show $AppID --source winget --version $AppVersion --accept-source-agreements
    }
    else {
        $AppResult = & $Winget show $AppID --source winget --accept-source-agreements
    }

    #Check if App and Version exists
    if (!($AppResult.ToLower() -match $AppID.ToLower())) {
        Write-Host "No application found."
        return
    }

    #Split winget output to lines
    $lines = $AppResult.Split([Environment]::NewLine) | Where-Object { $_ }

    #Find the line that contains AppID (should be 1st line)
    $fl = 0
    while (-not $lines[$fl].ToLower().Contains($AppID.ToLower())) {
        $fl++
    }

    #Get App ID
    $AppInfo.ID = ($lines[$fl] -split "[\[\]]")[1]

    #Get App Version
    if (!$AppVersion) {
        $AppVersion = $lines[$fl + 1].Split(":", 2)[1].Trim()
    }
    $AppInfo.Version = $AppVersion

    #Get Other App info from online yaml (and in local if exists)
    $AppUrl = ($AppInfo.ID).Replace(".", "/")
    $AppFirstChar = $AppID.Substring(0, 1).ToLower()
    $url = "https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/$($AppFirstChar)/$($AppUrl)/$($AppVersion)/$($AppInfo.ID).locale.{0}.yaml"
    try {
        $LocalUrl = Invoke-WebRequest -UseBasicParsing -Uri ($url -f (Get-UICulture).name)
    }
    catch {
        $LocalUrl = Invoke-WebRequest -UseBasicParsing -Uri ($url -f "en-US")
    }
    $OtherInfo = ($LocalUrl.Content).Split([Environment]::NewLine) | Where-Object { $_ }

    #Get App info from manifest
    for ($i = 0; $i -lt $OtherInfo.Count; $i++) {
        if ($OtherInfo[$i] -like "Publisher:*") {
            $AppInfo.Publisher = $OtherInfo[$i].Split(":", 2)[1].Trim()
        }
        if ($OtherInfo[$i] -like "PackageName:*") {
            $AppInfo.PackageName = $OtherInfo[$i].Split(":", 2)[1].Trim()
        }
        if ($OtherInfo[$i] -like "ShortDescription:*") {
            $AppInfo.ShortDescription = $OtherInfo[$i].Split(":", 2)[1].Trim()
        }
        if ($OtherInfo[$i] -like "Description:*") {
            $AppInfo.Description = $OtherInfo[$i].Split(":", 2)[1].Trim()
            while ($OtherInfo[$i + 1].StartsWith(" ")) {
                $AppInfo.Description += $OtherInfo[$i + 1].Trim() + " "
                $i++
            }
        }
        if ($OtherInfo[$i] -like "PackageUrl:*") {
            $AppInfo.PackageUrl = $OtherInfo[$i].Split(":", 2)[1].Trim()
        }
        if ($OtherInfo[$i] -like "PrivacyUrl:*") {
            $AppInfo.PrivacyUrl = $OtherInfo[$i].Split(":", 2)[1].Trim()
        }
        if ($OtherInfo[$i] -like "Author:*") {
            $AppInfo.Author = $OtherInfo[$i].Split(":", 2)[1].Trim()
        }
    }

    #Get Google Image app icon
    $SearchImageUrl = "https://www.google.com/search?tbm=isch&q=$($AppInfo.PackageName.replace('.','+'))+logo"
    $IconUrl = ((Invoke-WebRequest -Uri $SearchImageUrl).Images | Select -ExpandProperty src)[1]
    $AppInfo.Icon = "$Location\$($AppInfo.ID).jpg"
    Invoke-WebRequest -Uri $IconUrl -OutFile $($AppInfo.Icon)
}

function Invoke-IntunePackage ($Win32AppArgs) {
    # Package .intunewin file
    if (!(Test-Path "$Location/Winget-Install*")) {
        Get-GithubRepository $WIGithubLink
    }
    $DetectionScriptPath = (Get-Item "$Location\Winget-Install*").FullName
    $DetectionScriptFile = "winget-detect.ps1"
    $DetectionScriptContent = Get-Content "$DetectionScriptPath\$DetectionScriptFile"
    $DetectionScriptContent[1] = '$AppToDetect = "' + $($AppInfo.id) + '"'
    $DetectionScriptContent | Set-Content -Path "$DetectionScriptPath\$DetectionScriptFile" -Force
    $IntuneWinFile = "$DetectionScriptPath\winget-install.intunewin"
    if (!(Test-Path $IntuneWinFile)) {
        $Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $DetectionScriptPath -SetupFile "winget-install.ps1" -OutputFolder $DetectionScriptPath
        $Win32AppPackagePath = $Win32AppPackage.Path
    }
    else {
        $Win32AppPackagePath = $IntuneWinFile
    }

    # Create requirement rule for all platforms and Windows 10 2004
    $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "2004"

    # Create MSI detection rule
    $DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile "$DetectionScriptPath\$DetectionScriptFile"

    # Convert image file to icon
    echo = $($AppInfo.Icon)
    $Icon = New-IntuneWin32AppIcon -FilePath $AppInfo.Icon

    # Add parameters to table for the Win32 app
    $Win32AppArgs.DisplayName = $AppInfo.PackageName
    $Win32AppArgs.FilePath = $Win32AppPackagePath
    $Win32AppArgs.InstallExperience = "system"
    $Win32AppArgs.RestartBehavior = "suppress"
    $Win32AppArgs.DetectionRule = $DetectionRule
    $Win32AppArgs.RequirementRule = $RequirementRule
    if ($AppInfo.Publisher) {
        $Win32AppArgs.Publisher = $AppInfo.Publisher
    }
    if ($AppInfo.PackageUrl) {
        $Win32AppArgs.InformationURL = $AppInfo.PackageUrl
    }
    if ($AppInfo.PrivacyUrl) {
        $Win32AppArgs.PrivacyURL = $AppInfo.PrivacyUrl
    }
    if ($AppInfo.Author) {
        $Win32AppArgs.Developer = $AppInfo.Author
    }
    if ($AppInfo.Icon) {
        $Win32AppArgs.Icon = $Icon
    }

    Add-IntuneWin32App @Win32AppArgs
}



### PREREQUISITES ###

Start-PopUp "Loading..."

# IntuneWin32App module needed
$IntuneWin32App = Get-InstalledModule "IntuneWin32App" -ErrorAction SilentlyContinue
if (!$IntuneWin32App) {
    $NuGet = Get-PackageProvider -name "nuget" -ListAvailable -ErrorAction SilentlyContinue
    if (!$NuGet) {
        Start-PopUp "Installing NuGet..."
        Start-Process 'powershell.exe' -Verb RunAs -ArgumentList '-ExecutionPolicy ByPass -Command "Install-PackageProvider -Name nuget -Force"' -Wait
    }
    Start-PopUp "Installing IntuneWin32App..."
    Start-Process 'powershell.exe' -Verb RunAs -ArgumentList '-ExecutionPolicy ByPass -Command "Install-Module -Name "IntuneWin32App" -force"' -Wait
}
#Create Temp folder
if (!(Test-Path $Location)) {
    New-Item -ItemType Directory -Force -Path $Location | Out-Null
}
#Encoding & error management
$null = cmd /c ''
$Global:OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
#$ProgressPreference = "SilentlyContinue"
$IconBase64 = [Convert]::FromBase64String("AAABAAEAEBAAAAAAAABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAQAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAUKEUwPHjCLECAzkRAgM5EQIDORECAzkRAgM5EQIDORECAzkRAgM5EPHjCOBQoRXwAAABQAAAAAAAAAABUoPpAyYZv9NWaj/zVmpP81ZqT/NWak/zVmpP81ZqT/NWak/zVmpP81ZqT/NWaj/zJgmv0TJDmtAAAAFAkQGC01ZZ/9MGWh/yFfl/8oY5z/IV+X/y5loP81aKT/W4S1/8XKz/+5vcL/ub3C/7m9wv99lLH/KU56/QYKD1wgOVZcOGyn/zFpov8eX5X/Lmeg/x5flf8vaKH/OGyn/2GKuf+2trb/n5+f/5+fn/+Tk5P/Z3uS/ypTf/8QHi2LJURjXzpxqv85cKn/Kmie/zlxqv8raJ//OHCo/zpxqv9Tg7X/obbM/5uxxv+QobP/d4eX/1Z0kv8sVoL/EiEwjCdHZl88daz/PHWs/zx1rP88daz/PHWs/zx1rP88daz/PHWs/zx1rP82apv/LlqE/y5ZhP8uWYT/LlmE/xMjMosrTGpfPnqv/z56r/8+eq//Pnqv/z56r/8+eq//Pnqv/z56r/84bp7/L12G/y9dhv8vXYb/L12G/y9dhv8VJTSKL1FtX0B/sv9Af7L/QH+y/0B/sv9Af7L/QH+y/0B/sv86cqD/MWGI/zFhiP8xYYj/MWGI/zFhiP8xYYj/Fyc1iTNWcF9DhLX/Q4S1/0OEtf9DhLX/Q4S1/0OEtf88dqL/M2SK/zNkiv8zZIr/M2SK/zNkiv8zZIr/M2SK/xkqN4g4WnJfRYi3/0WIt/9FiLf/RYi3/0WIt/9Girj/U5i3/1edu/83a4//NWiM/zVojP81aIz/NWiM/zdulP8fNUSHPF91X0eNuv9Hjbr/R426/0eNuv9Hjbr/SI67/1igvv9cpsP/OW+R/zZsjv82bI7/NmyO/zlylv9Girb/IzpIhUBjd19Jkb3/SZG9/0mRvf9Jkb3/SZG9/0uTvf9Yob7/XafD/zpyk/84b5D/OG+Q/zt1mP9Ij7n/SZG9/yU8SoRHaHpbS5a//0uWv/9Llr//S5a//0uWv/9Nl8D/WaO//12oxP88dpX/OXOS/z15mv9Kk7v/S5a//0uWv/8oPUl9QFRfIVuixvtOm8L/TpvC/06bwv9Om8L/T5zC/1mkwP9eqcX/PXmX/z58nP9Ml77/TpvC/06bwv9ZoMT8ExkdPwAAAAB4obZsY6jK+0+dw/9OnMP/TpzD/1Cdw/9apMD/XqnF/0GBn/9Nmb//TpzD/0+dw/9hpcf8OlFchQAAAAIAAAAAAAAAAEpdZyFhfIlbYXyKX2F8il9ifYpfZX+JX2eBil9he4hfYnyKX2J8il9bc39cHiYqKQAAAAAAAAAAgAEAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAwAMAAA==")

Close-PopUp




### MAIN ###

#Get WinGet cmd
Get-WingetCmd

#Start GUI
Start-InstallGUI

#Remove temp items
Remove-Item $Location -Recurse -Force -Confirm:$false