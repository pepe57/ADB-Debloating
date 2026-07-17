# Check whether all necessary files exist in the bin folder
$Files = @(
	"$PSScriptRoot\platform-tools\adb.exe",
	"$PSScriptRoot\Apps.json"
)
if (($Files | Test-Path) -contains $false)
{
	Write-Warning -Message "Re-download archive and download ADB via Download_ADB.ps1."
	Start-Process -FilePath "https://github.com/farag2/ADB-Debloating"

	pause
	exit
}

Get-Process -Name adb -ErrorAction Ignore | Stop-Process -Name adb -Force -ErrorAction Ignore

try
{
	Get-Content -Raw "$PSScriptRoot\Apps.json" -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
}
catch
{
	Write-Warning "$PSScriptRoot\Apps.json is not valid"
}

if ($PSVersionTable.PSVersion.Major -eq 5)
{
	Remove-TypeData -TypeName System.Array -ErrorAction Ignore
}

# Sort  by app's name
$JSON = Get-Content -Path "$PSScriptRoot\Apps.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$JSON = $JSON | Sort-Object -Property Name -Unique
($JSON | ConvertTo-JSON -Depth 5).Replace("\u0026", "&") | Set-Content -Path "$PSScriptRoot\Apps.json" -Encoding UTF8 -Force

Write-Warning -Message "Waiting your phone to be connected and allowed USB debugging"
& $PSScriptRoot\platform-tools\adb.exe wait-for-device
pause

# Check whether adb is functioning
try
{
	(& $PSScriptRoot\platform-tools\adb.exe shell cmd package list packages).replace("package:", "") | Select-Object -First 0
}
catch [System.Management.Automation.RuntimeException]
{
	Write-Warning -Message "Re-connect cable or revoke USB debugging authorizations in developer settings"
	Stop-Process -Name adb -Force -ErrorAction Ignore

	pause
	exit
}

Write-Warning -Message "Please wait...
"

$PackagesList = Get-Content -Path "$PSScriptRoot\Apps.json" | ConvertFrom-Json
# Check if disabled packages exist, unless we cannot check if replace() method exists for them
if ($null -ne (& $PSScriptRoot\platform-tools\adb.exe shell pm list packages -d))
{
	$DisabledPackages = @((& $PSScriptRoot\platform-tools\adb.exe shell pm list packages -d).replace("package:", ""))
}

$Packages = @()
foreach ($Package in $PackagesList.Package)
{
	if ((@((& $PSScriptRoot\platform-tools\adb.exe shell cmd package list packages).replace("package:", "")) | Where-Object -FilterScript {$_ -eq $Package}) -and ($DisabledPackages -notcontains $Package))
	{
		$Packages += $PackagesList | Where-Object {$_.Package -eq $Package}
	}
}

Add-Type -AssemblyName PresentationCore, PresentationFramework

$CheckedPackages = New-Object -TypeName System.Collections.ArrayList($null)

#region XAML Markup
# The section defines the design of the upcoming dialog box
[xml]$XAML = @"
<Window
	xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	Name="Window"
	MinHeight="460" MinWidth="350"
	SizeToContent="Width" WindowStartupLocation="CenterScreen"
	TextOptions.TextFormattingMode="Display" SnapsToDevicePixels="True"
	FontFamily="Candara" FontSize="16" ShowInTaskbar="True"
	Background="#F1F1F1" Foreground="#262626">
	<Window.Resources>
		<Style TargetType="CheckBox">
			<Setter Property="VerticalAlignment" Value="Center"/>
			<Setter Property="Margin" Value="10"/>
		</Style>
		<Style TargetType="TextBlock">
			<Setter Property="VerticalAlignment" Value="Center"/>
			<Setter Property="Margin" Value="0, 0, 0, 2"/>
		</Style>
		<Style TargetType="Button">
			<Setter Property="Margin" Value="20"/>
			<Setter Property="Padding" Value="10"/>
			<Setter Property="IsEnabled" Value="False"/>
		</Style>
	</Window.Resources>
	<Grid>
		<Grid.RowDefinitions>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		<ScrollViewer Grid.Row="0">
		<StackPanel Name="PanelContainer"/>
		</ScrollViewer>
		<Button Name="ButtonUninstall" Grid.Row="2"/>
	</Grid>
</Window>
"@
#endregion XAML Markup

$Form = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $XAML))
$XAML.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object -Process {
	Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)
}

$ButtonUninstall.Content = "Uninstall"
$Window.Title = "Bloatware ADB Uninstaller"
#endregion Variables

#region Functions
function CheckBoxClicked
{
	if ($Script:CheckedPackages.Contains($_.Source.Tag))
	{
		$Script:CheckedPackages.Remove($_.Source.Tag)
	}
	else
	{
		$Script:CheckedPackages.Add($_.Source.Tag) | Out-Null
	}

	$Script:ButtonUninstall.IsEnabled = $Script:CheckedPackages.Count -gt 0
}

function ButtonUninstallClicked
{
	$Form.Close()

	$Script:CheckedPackages | ForEach-Object -Process {
		$_ -split " " | ForEach-Object -Process {
			Write-Verbose -Message $_ -Verbose

			if ((@(& $PSScriptRoot\platform-tools\adb.exe shell pm uninstall --user 0 $_)) -contains "Failure [-1000]")
			{
				& $PSScriptRoot\platform-tools\adb.exe shell pm disable-user $_
			}
		}
	}
}
#endregion

foreach ($Package in $Packages)
{
	$Panel = New-Object -TypeName System.Windows.Controls.StackPanel
	$CheckBox = New-Object -TypeName System.Windows.Controls.CheckBox
	$TextBlock = New-Object -TypeName System.Windows.Controls.TextBlock
	$Panel.Orientation = "Horizontal"
	$CheckBox.Tag = $Package.Package
	$CheckBox.Add_Click({ CheckBoxClicked })
	$TextBlock.Text = $Package.Name
	$Panel.Children.Add($CheckBox) | Out-Null
	$Panel.Children.Add($TextBlock) | Out-Null
	$PanelContainer.Children.Add($Panel) | Out-Null
}

$ButtonUninstall.Add_Click({ ButtonUninstallClicked })
$Form.ShowDialog() | Out-Null

Start-Sleep -Seconds 3

Stop-Process -Name adb -Force -ErrorAction Ignore

Remove-Item -Path "$env:USERPROFILE\.android", "$env:USERPROFILE\dbus-keyrings" -Recurse -Force -ErrorAction Ignore

pause
