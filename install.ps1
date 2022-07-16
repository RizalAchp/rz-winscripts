<#
.NOTES
   Author      : Rizal Achmad Pahlevi
   GitHub      : https://github.com/RizalAchp/rz-winscripts
    Version 0.0.1
#>

function Show-MessageBox {
  [CmdletBinding(PositionalBinding=$false)]
  param(
    [Parameter(Mandatory, Position=0)]
    [string] $Message,
    [Parameter(Position=1)]
    [string] $Title,
    [Parameter(Position=2)]
    [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
    [string] $Buttons = 'OK',
    [ValidateSet('Information', 'Warning', 'Stop')]
    [string] $Icon = 'Information',
    [ValidateSet(0, 1, 2)]
    [int] $DefaultButtonIndex
  )

  Set-StrictMode -Off
  $buttonMap = @{
    'OK'               = @{ buttonList = 'OK'; defaultButtonIndex = 0 }
    'OKCancel'         = @{ buttonList = 'OK', 'Cancel'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
    'AbortRetryIgnore' = @{ buttonList = 'Abort', 'Retry', 'Ignore'; defaultButtonIndex = 2; ; cancelButtonIndex = 0 };
    'YesNoCancel'      = @{ buttonList = 'Yes', 'No', 'Cancel'; defaultButtonIndex = 2; cancelButtonIndex = 2 };
    'YesNo'            = @{ buttonList = 'Yes', 'No'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
    'RetryCancel'      = @{ buttonList = 'Retry', 'Cancel'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
  }

  $numButtons = $buttonMap[$Buttons].buttonList.Count
  $defaultIndex = [math]::Min($numButtons - 1, ($buttonMap[$Buttons].defaultButtonIndex, $DefaultButtonIndex)[$PSBoundParameters.ContainsKey('DefaultButtonIndex')])
  $cancelIndex = $buttonMap[$Buttons].cancelButtonIndex

  if ($IsLinux) {
    Throw "Not supported on Linux."
  }
  elseif ($IsMacOS) {

    $iconClause = if ($Icon -ne 'Information') { 'as ' + $Icon -replace 'Stop', 'critical' }
    $buttonClause = "buttons { $($buttonMap[$Buttons].buttonList -replace '^', '"' -replace '$', '"' -join ',') }"

    $defaultButtonClause = 'default button ' + (1 + $defaultIndex)
    if ($null -ne $cancelIndex -and $cancelIndex -ne $defaultIndex) {
      $cancelButtonClause = 'cancel button ' + (1 + $cancelIndex)
    }
    $appleScript = "display alert `"$Title`" message `"$Message`" $iconClause $buttonClause $defaultButtonClause $cancelButtonClause"            #"
    Write-Verbose "AppleScript command: $appleScript"
    $result = $appleScript | osascript 2>$null
    if (-not $result) { $buttonMap[$Buttons].buttonList[$buttonMap[$Buttons].cancelButtonIndex] } else { $result -replace '.+:' }
  }
  else { # Windows
    Add-Type -Assembly System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon, $defaultIndex * 256).ToString()
  }

}

function Check-Installed-Programs([string]$Program)
{
	Get-Command -Name $Program -ErrorAction SilentlyContinue -ErrorVariable CommandNotAvailableError;
	if ($CommandNotAvailableError) {
		Show-MessageBox -Message "program '$Program' is not installed in this machine! install it first! then run this programs again!" -Title "Error: Winget not Installed" -Buttons 'OK' -Icon 'Warning'
		return $false
	}
	Write-Host "Program: '$Program' found, Continue the scripts.."
	return $true
}

#===========================================================================
# install function - Install
#===========================================================================
function Download-Winget([array]$itemwingets) {
	$wingetResult = New-Object System.Collections.Generic.List[System.Object]
	foreach ( $item in $itemwingets )
	{
		Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget install -e --accept-source-agreements --accept-package-agreements --silent $item | Out-Host" -Wait -WindowStyle Maximized
		$wingetResult.Add("$item`n")
	}
	$wingetResult.ToArray()
	$wingetResult | % { $_ } | Out-Host

	$ButtonType = [System.Windows.MessageBoxButton]::OK
	$MessageboxTitle = "Installed Programs "
	$Messageboxbody = ($wingetResult)
	$MessageIcon = [System.Windows.MessageBoxImage]::Information

	[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
}

if ((Check-Installed-Programs -Program "winget") -eq $true)
{
	$inputXML = Get-Content "MainWindow.xaml" #uncomment for development
	# $inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/RizalAchp/rz-winscripts/master/MainWindow.xaml") #uncomment for Production

	$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
	[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
	[xml]$XAML = $inputXML
	#Read XAML

	$reader=(New-Object System.Xml.XmlNodeReader $xaml)
	try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
	catch [System.Management.Automation.MethodInvocationException] {
		Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
		write-host $error[0].Exception.Message -ForegroundColor Red
		If ($error[0].Exception.Message -like "*button*") {
			write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
		}
	}
	catch{# If it broke some other way <img draggable="false" role="img" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
		Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
			}

	#===========================================================================
	# Store Form Objects In PowerShell
	#===========================================================================

	$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}

	Function Get-FormVariables{
	If ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
	write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
	get-variable WPF*
	}

	Get-FormVariables

	#===========================================================================
	# Navigation Controls
	#===========================================================================
	$WPFTab1BT.Add_Click({
		$WPFTabNav.Items[0].IsSelected = $true
		$WPFTabNav.Items[1].IsSelected = $false
	})
	$WPFTab2BT.Add_Click({
		$WPFTabNav.Items[0].IsSelected = $false
		$WPFTabNav.Items[1].IsSelected = $true
	})

	#===========================================================================
	# Tab 1 - Install
	#===========================================================================
	$WPFinstall.Add_Click({
		$wingetarrays = New-Object System.Collections.Generic.List[System.Object]
		If ( $WPFInstalladobe.IsChecked -eq $true ) {
			$wingetarrays.Add("Adobe.Acrobat.Reader.64-bit")
			$WPFInstalladobe.IsChecked = $false
		}
		If ( $WPFInstallaudacity.IsChecked -eq $true ) {
			$wingetarrays.Add("Audacity.Audacity")
			$WPFInstallaudacity.IsChecked = $false
		}
		If ( $WPFInstallbrave.IsChecked -eq $true ) {
			$wingetarrays.Add("BraveSoftware.BraveBrowser")
			$WPFInstallbrave.IsChecked = $false
		}
		If ( $WPFInstallchrome.IsChecked -eq $true ) {
			$wingetarrays.Add("Google.Chrome")
			$WPFInstallchrome.IsChecked = $false
		}
		If ( $WPFInstalldiscord.IsChecked -eq $true ) {
			$wingetarrays.Add("Discord.Discord")
			$WPFInstalldiscord.IsChecked = $false
		}
		If ( $WPFInstalletcher.IsChecked -eq $true ) {
			$wingetarrays.Add("Balena.Etcher")
			$WPFInstalletcher.IsChecked = $false
		}
		If ( $WPFInstallfirefox.IsChecked -eq $true ) {
			$wingetarrays.Add("Mozilla.Firefox")
			$WPFInstallfirefox.IsChecked = $false
		}
		If ( $WPFInstallgimp.IsChecked -eq $true ) {
			$wingetarrays.Add("GIMP.GIMP")
			$WPFInstallgimp.IsChecked = $false
		}
		If ( $WPFInstallimageglass.IsChecked -eq $true ) {
			$wingetarrays.Add("DuongDieuPhap.ImageGlass")
			$WPFInstallimageglass.IsChecked = $false
		}
		If ( $WPFInstallmpc.IsChecked -eq $true ) {
			$wingetarrays.Add("clsid2.mpc-hc")
			$WPFInstallmpc.IsChecked = $false
		}
		If ( $WPFInstallnotepadplus.IsChecked -eq $true ) {
			$wingetarrays.Add("Notepad++.Notepad++")
			$WPFInstallnotepadplus.IsChecked = $false
		}
		If ( $WPFInstallsevenzip.IsChecked -eq $true ) {
			$wingetarrays.Add("7zip.7zip")
			$WPFInstallsevenzip.IsChecked = $false
		}
		If ( $WPFInstallsharex.IsChecked -eq $true ) {
			$wingetarrays.Add("ShareX.ShareX")
			$WPFInstallsharex.IsChecked = $false
		}
		If ( $WPFInstallsumatra.IsChecked -eq $true ) {
			$wingetarrays.Add("SumatraPDF.SumatraPDF")
			$WPFInstallsumatra.IsChecked = $false
		}
		If ( $WPFInstallvlc.IsChecked -eq $true ) {
			$wingetarrays.Add("VideoLAN.VLC")
			$WPFInstallvlc.IsChecked = $false
		}
		If ( $WPFInstallblender.IsChecked -eq $true ) {
			$wingetarrays.Add("BlenderFoundation.Blender")
			$WPFInstallblender.IsChecked = $false
		}
		If ( $WPFInstallchromium.IsChecked -eq $true ) {
			$wingetarrays.Add("eloston.ungoogled-chromium")
			$WPFInstallchromium.IsChecked = $false
		}
		If ( $WPFInstallcpuz.IsChecked -eq $true ) {
			$wingetarrays.Add("CPUID.CPU-Z")
			$WPFInstallcpuz.IsChecked = $false
		}
		If ( $WPFInstalleartrumpet.IsChecked -eq $true ) {
			$wingetarrays.Add("File-New-Project.EarTrumpet")
			$WPFInstalleartrumpet.IsChecked = $false
		}
		If ( $WPFInstallepicgames.IsChecked -eq $true ) {
			$wingetarrays.Add("EpicGames.EpicGamesLauncher")
			$WPFInstallepicgames.IsChecked = $false
		}
		If ( $WPFInstallflameshot.IsChecked -eq $true ) {
			$wingetarrays.Add("Flameshot.Flameshot")
			$WPFInstallflameshot.IsChecked = $false
		}
		If ( $WPFInstallfoobar.IsChecked -eq $true ) {
			$wingetarrays.Add("PeterPawlowski.foobar2000")
			$WPFInstallfoobar.IsChecked = $false
		}
		If ( $WPFInstallgpuz.IsChecked -eq $true ) {
			$wingetarrays.Add("TechPowerUp.GPU-Z")
			$WPFInstallgpuz.IsChecked = $false
		}
		If ( $WPFInstallgreenshot.IsChecked -eq $true ) {
			$wingetarrays.Add("Greenshot.Greenshot")
			$WPFInstallgreenshot.IsChecked = $false
		}
		If ( $WPFInstallhandbrake.IsChecked -eq $true ) {
			$wingetarrays.Add("HandBrake.HandBrake")
			$WPFInstallhandbrake.IsChecked = $false
		}
		If ( $WPFInstallhwinfo.IsChecked -eq $true ) {
			$wingetarrays.Add("REALiX.HWiNFO")
			$WPFInstallhwinfo.IsChecked = $false
		}
		If ( $WPFInstallinkscape.IsChecked -eq $true ) {
			$wingetarrays.Add("Inkscape.Inkscape")
			$WPFInstallinkscape.IsChecked = $false
		}
		If ( $WPFInstallkeepass.IsChecked -eq $true ) {
			$wingetarrays.Add("KeePassXCTeam.KeePassXC")
			$WPFInstallkeepass.IsChecked = $false
		}
		If ( $WPFInstallobs.IsChecked -eq $true ) {
			$wingetarrays.Add("OBSProject.OBSStudio")
			$WPFInstallobs.IsChecked = $false
		}
		If ( $WPFInstallrufus.IsChecked -eq $true ) {
			$wingetarrays.Add("Rufus.Rufus")
			$WPFInstallrufus.IsChecked = $false
		}
		If ( $WPFInstallspotify.IsChecked -eq $true ) {
			$wingetarrays.Add("Spotify.Spotify")
			$WPFInstallspotify.IsChecked = $false
		}
		If ( $WPFInstallsteam.IsChecked -eq $true ) {
			$wingetarrays.Add("Valve.Steam")
			$WPFInstallsteam.IsChecked = $false
		}
		If ( $WPFInstallvoicemeeter.IsChecked -eq $true ) {
			$wingetarrays.Add("VB-Audio.Voicemeeter")
			$WPFInstallvoicemeeter.IsChecked = $false
		}
		If ( $WPFInstallwindirstat.IsChecked -eq $true ) {
			$wingetarrays.Add("WinDirStat.WinDirStat")
			$WPFInstallwindirstat.IsChecked = $false
		}
		If ( $WPFInstallzoom.IsChecked -eq $true ) {
			$wingetarrays.Add("Zoom.Zoom")
			$WPFInstallzoom.IsChecked = $false
		}

		$OutputMsg = Show-MessageBox -Message "Yakin? ;) click OK kalo dah yakin beb :v" -Title "Begin Installation" -Buttons 'OKCancel'
		switch ($OutputMsg) {
			'Yes' {
				Download-Winget $wingetarrays.ToArray()
			}
			'Cancel' {
				$wingetarrays.Clear()
			}
		}
	})

	$WPFInstallUpgrade.Add_Click({
		Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget upgrade --all  | Out-Host" -Wait -WindowStyle Maximized

		$ButtonType = [System.Windows.MessageBoxButton]::OK
		$MessageboxTitle = "Upgraded All Programs "
		$Messageboxbody = ("Done")
		$MessageIcon = [System.Windows.MessageBoxImage]::Information

		[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)
	})

	#===========================================================================
	# Tab 2 - Development Tabs
	#===========================================================================
	$WPFembeddev.Add_Click({
		$WPFInstallgit.IsChecked = $true
		$WPFInstallwinterm.IsChecked = $true
		$WPFInstallgithubdesktop.IsChecked = $true
		$WPFInstalljetbrains.IsChecked = $true
		$WPFInstallandroidstudio.IsChecked = $true
		$WPFInstallsublime.IsChecked = $true
		$WPFInstallvim.IsChecked = $true
		$WPFInstallneovim.IsChecked = $true
		$WPFInstallneovide.IsChecked = $true
		$WPFInstallvisualstudio22.IsChecked = $true
		$WPFInstallvisualstudio19.IsChecked = $true
		$WPFInstallcodelite.IsChecked = $true
		$WPFInstallpycharm.IsChecked = $true
		$WPFInstallcygwin.IsChecked = $true
		$WPFInstallmsys2.IsChecked = $true
		$WPFInstallcmake.IsChecked = $true
		$WPFInstallvscode.IsChecked = $true
		$WPFInstallvscodium.IsChecked = $true
		$WPFInstallpowertoys.IsChecked = $true
		$WPFInstallwindirstat.IsChecked = $true
		$WPFInstalladvancedip.IsChecked = $true
		$WPFInstallmremoteng.IsChecked = $true
		$WPFInstallputty.IsChecked = $true
		$WPFInstallscp.IsChecked = $true
		$WPFInstallwireshark.IsChecked = $true
		$WPFInstalljava8.IsChecked = $true
		$WPFInstalljava16.IsChecked = $true
		$WPFInstalljava18.IsChecked = $true
		$WPFInstallpython3.IsChecked = $true
		$WPFInstallnodejs.IsChecked = $true
		$WPFInstallnodejslts.IsChecked = $true
		$WPFInstallminiconda.IsChecked = $true
		$WPFInstallrust.IsChecked = $true
		$WPFInstallgo.IsChecked = $true
	})

	$WPFwebdev.Add_Click({
		$WPFInstallgit.IsChecked = $true
		$WPFInstallwinterm.IsChecked = $true
		$WPFInstallgithubdesktop.IsChecked = $true
		$WPFInstalljetbrains.IsChecked = $true
		$WPFInstallandroidstudio.IsChecked = $true
		$WPFInstallsublime.IsChecked = $true
		$WPFInstallvim.IsChecked = $true
		$WPFInstallneovim.IsChecked = $true
		$WPFInstallneovide.IsChecked = $true
		$WPFInstallvisualstudio22.IsChecked = $true
		$WPFInstallvisualstudio19.IsChecked = $true
		$WPFInstallcodelite.IsChecked = $true
		$WPFInstallpycharm.IsChecked = $true
		$WPFInstallcygwin.IsChecked = $true
		$WPFInstallmsys2.IsChecked = $true
		$WPFInstallcmake.IsChecked = $true
		$WPFInstallvscode.IsChecked = $true
		$WPFInstallvscodium.IsChecked = $true
		$WPFInstallpowertoys.IsChecked = $true
		$WPFInstallwindirstat.IsChecked = $true
		$WPFInstalladvancedip.IsChecked = $true
		$WPFInstallmremoteng.IsChecked = $true
		$WPFInstallputty.IsChecked = $true
		$WPFInstallscp.IsChecked = $true
		$WPFInstallwireshark.IsChecked = $true
		$WPFInstalljava8.IsChecked = $true
		$WPFInstalljava16.IsChecked = $true
		$WPFInstalljava18.IsChecked = $true
		$WPFInstallpython3.IsChecked = $true
		$WPFInstallnodejs.IsChecked = $true
		$WPFInstallnodejslts.IsChecked = $true
		$WPFInstallminiconda.IsChecked = $true
		$WPFInstallrust.IsChecked = $true
		$WPFInstallgo.IsChecked = $true
	})

	$WPFmobiledev.Add_Click({
		$WPFInstallgit.IsChecked = $true
		$WPFInstallwinterm.IsChecked = $true
		$WPFInstallgithubdesktop.IsChecked = $true
		$WPFInstalljetbrains.IsChecked = $true
		$WPFInstallandroidstudio.IsChecked = $true
		$WPFInstallsublime.IsChecked = $true
		$WPFInstallvim.IsChecked = $true
		$WPFInstallneovim.IsChecked = $true
		$WPFInstallneovide.IsChecked = $true
		$WPFInstallvisualstudio22.IsChecked = $true
		$WPFInstallvisualstudio19.IsChecked = $true
		$WPFInstallcodelite.IsChecked = $true
		$WPFInstallpycharm.IsChecked = $true
		$WPFInstallcygwin.IsChecked = $true
		$WPFInstallmsys2.IsChecked = $true
		$WPFInstallcmake.IsChecked = $true
		$WPFInstallvscode.IsChecked = $true
		$WPFInstallvscodium.IsChecked = $true
		$WPFInstallpowertoys.IsChecked = $true
		$WPFInstallwindirstat.IsChecked = $true
		$WPFInstalladvancedip.IsChecked = $true
		$WPFInstallmremoteng.IsChecked = $true
		$WPFInstallputty.IsChecked = $true
		$WPFInstallscp.IsChecked = $true
		$WPFInstallwireshark.IsChecked = $true
		$WPFInstalljava8.IsChecked = $true
		$WPFInstalljava16.IsChecked = $true
		$WPFInstalljava18.IsChecked = $true
		$WPFInstallpython3.IsChecked = $true
		$WPFInstallnodejs.IsChecked = $true
		$WPFInstallnodejslts.IsChecked = $true
		$WPFInstallminiconda.IsChecked = $true
		$WPFInstallrust.IsChecked = $true
		$WPFInstallgo.IsChecked = $true
	})

	$WPFalldev.Add_Click({
		$WPFInstallgit.IsChecked = $true
		$WPFInstallwinterm.IsChecked = $true
		$WPFInstallgithubdesktop.IsChecked = $true
		$WPFInstalljetbrains.IsChecked = $true
		$WPFInstallandroidstudio.IsChecked = $true
		$WPFInstallsublime.IsChecked = $true
		$WPFInstallvim.IsChecked = $true
		$WPFInstallneovim.IsChecked = $true
		$WPFInstallneovide.IsChecked = $true
		$WPFInstallvisualstudio22.IsChecked = $true
		$WPFInstallvisualstudio19.IsChecked = $true
		$WPFInstallcodelite.IsChecked = $true
		$WPFInstallpycharm.IsChecked = $true
		$WPFInstallcygwin.IsChecked = $true
		$WPFInstallmsys2.IsChecked = $true
		$WPFInstallcmake.IsChecked = $true
		$WPFInstallvscode.IsChecked = $true
		$WPFInstallvscodium.IsChecked = $true
		$WPFInstallpowertoys.IsChecked = $true
		$WPFInstallwindirstat.IsChecked = $true
		$WPFInstalladvancedip.IsChecked = $true
		$WPFInstallmremoteng.IsChecked = $true
		$WPFInstallputty.IsChecked = $true
		$WPFInstallscp.IsChecked = $true
		$WPFInstallwireshark.IsChecked = $true
		$WPFInstalljava8.IsChecked = $true
		$WPFInstalljava16.IsChecked = $true
		$WPFInstalljava18.IsChecked = $true
		$WPFInstallpython3.IsChecked = $true
		$WPFInstallnodejs.IsChecked = $true
		$WPFInstallnodejslts.IsChecked = $true
		$WPFInstallminiconda.IsChecked = $true
		$WPFInstallrust.IsChecked = $true
		$WPFInstallgo.IsChecked = $true
	})

	$WPFinstalldev.Add_Click({
		$wingetarrays = New-Object System.Collections.Generic.List[System.Object]
		if ( $WPFInstallgit.IsChecked -eq $true )
		{
			$wingetarrays.Add("Git.Git")
			$WPFInstallgit.IsChecked = $false
		}
		if ( $WPFInstallwinterm.IsChecked -eq $true )
		{
			$wingetarrays.Add("Microsoft.WindowsTerminal")
			$WPFInstallwinterm.IsChecked = $false
		}
		if ( $WPFInstallgithubdesktop.IsChecked -eq $true )
		{
			$wingetarrays.Add("Git.Git")
			$wingetarrays.Add("GitHub.cli")
			$wingetarrays.Add("GitHub.GitHubDesktop")
			$WPFInstallgithubdesktop.IsChecked = $false
		}
		if ( $WPFInstalljetbrains.IsChecked -eq $true )
		{
			$wingetarrays.Add("JetBrains.Toolbox")
			$WPFInstalljetbrains.IsChecked = $false
		}
		if ( $WPFInstallandroidstudio.IsChecked -eq $true )
		{
			$wingetarrays.Add("Google.AndroidStudio")
			$WPFInstallandroidstudio.IsChecked = $false
		}
		if ( $WPFInstallsublime.IsChecked -eq $true )
		{
			$wingetarrays.Add("SublimeHQ.SublimeText.4")
			$WPFInstallsublime.IsChecked = $false
		}
		if ( $WPFInstallvim.IsChecked -eq $true )
		{
			$wingetarrays.Add("vim.vim")
			$WPFInstallvim.IsChecked = $false
		}
		if ( $WPFInstallneovim.IsChecked -eq $true )
		{
			$wingetarrays.Add("Neovim.Neovim")
			$WPFInstallneovim.IsChecked = $false
		}
		if ($WPFInstallneovide.IsChecked -eq $true)
		{
			Write-Warning "Warning: Neovide tidak tersedia pada repository Winget! Neovide tidak ada terinstall (hanya warning, abaikan saja)"
			$WPFInstallneovide.IsChecked = $false
		}
		if ($WPFInstallvisualstudio22.IsChecked -eq $true)
		{
			$wingetarrays.Add("Microsoft.VisualStudio.2022.Community")
			$WPFInstallvisualstudio22.IsChecked = $false
		}
		if ($WPFInstallvisualstudio19.IsChecked -eq $true)
		{
			$wingetarrays.Add("Microsoft.VisualStudio.2019.Community")
			$WPFInstallvisualstudio19.IsChecked = $false
		}
		if ($WPFInstallcodelite.IsChecked -eq $true)
		{
			$wingetarrays.Add("CodeLite.CodeLite")
			$WPFInstallcodelite.IsChecked = $false
		}
		if ($WPFInstallpycharm.IsChecked -eq $true)
		{
			$wingetarrays.Add("JetBrains.PyCharm.Community")
			$WPFInstallpycharm.IsChecked = $false
		}
		if ($WPFInstallcygwin.IsChecked -eq $true)
		{
			$wingetarrays.Add("Cygwin.Cygwin")
			$WPFInstallcygwin.IsChecked = $false
		}
		if ($WPFInstallmsys2.IsChecked -eq $true)
		{
			$wingetarrays.Add("msys2.msys2")
			$WPFInstallmsys2.IsChecked = $false
		}
		if ($WPFInstallcmake.IsChecked -eq $true)
		{
			$wingetarrays.Add("Kitware.CMake")
			$WPFInstallcmake.IsChecked = $false
		}
		if ($WPFInstallvscode.IsChecked -eq $true)
		{
			$wingetarrays.Add("Git.Git")
			$wingetarrays.Add("Microsoft.VisualStudioCode --source winget")
			$WPFInstallvscode.IsChecked = $false
		}
		if ($WPFInstallvscodium.IsChecked -eq $true)
		{
			$wingetarrays.Add("Git.Git")
			$wingetarrays.Add("VSCodium.VSCodium")
			$WPFInstallvscodium.IsChecked = $false
		}
		if ($WPFInstallpowertoys.IsChecked -eq $true)
		{
			$wingetarrays.Add("Microsoft.PowerToys --source winget")
			$WPFInstallpowertoys.IsChecked = $false
		}
		if ($WPFInstallwindirstat.IsChecked -eq $true)
		{
			$wingetarrays.Add("WinDirStat.WinDirStat")
			$WPFInstallwindirstat.IsChecked = $false
		}
		if ($WPFInstalladvancedip.IsChecked -eq $true)
		{
			$wingetarrays.Add("Famatech.AdvancedIPScanner")
			$WPFInstalladvancedip.IsChecked = $false
		}
		if ($WPFInstallmremoteng.IsChecked -eq $true)
		{
			$wingetarrays.Add("mRemoteNG.mRemoteNG")
			$WPFInstallmremoteng.IsChecked = $false
		}
		if ($WPFInstallscp.IsChecked -eq $true)
		{
			$wingetarrays.Add("WinSCP.WinSCP")
			$WPFInstallscp.IsChecked = $false
			$WPFInstallputty.IsChecked = $false
		}
		if ($WPFInstallputty.IsChecked -eq $true)
		{
			$wingetarrays.Add("PuTTY.PuTTY --source winget")
			$WPFInstallputty.IsChecked = $false
		}
		if ($WPFInstallwireshark.IsChecked -eq $true)
		{
			$wingetarrays.Add("WiresharkFoundation.Wireshark")
			$WPFInstallwireshark.IsChecked = $false
		}
		if ($WPFInstalljava8.IsChecked -eq $true)
		{
			$wingetarrays.Add("AdoptOpenJDK.OpenJDK.8")
			$WPFInstalljava8.IsChecked = $false
		}
		if ($WPFInstalljava16.IsChecked -eq $true)
		{
			$wingetarrays.Add("AdoptOpenJDK.OpenJDK.16")
			$WPFInstalljava16.IsChecked = $false
		}
		if ($WPFInstalljava18.IsChecked -eq $true)
		{
			$wingetarrays.Add("AdoptOpenJDK.OpenJDK.16")
			$WPFInstalljava18.IsChecked = $false
		}
		if ($WPFInstallpython3.IsChecked -eq $true)
		{
			$wingetarrays.Add("Python.Python.3")
			$WPFInstallpython3.IsChecked = $false
		}
		if ($WPFInstallnodejs.IsChecked -eq $true)
		{
			$wingetarrays.Add("OpenJS.NodeJS")
			$WPFInstallnodejs.IsChecked = $false
		}
		if ($WPFInstallnodejslts.IsChecked -eq $true)
		{
			$wingetarrays.Add("OpenJS.NodeJS.LTS")
			$WPFInstallnodejslts.IsChecked = $false
		}
		if ($WPFInstallminiconda.IsChecked -eq $true)
		{
			$wingetarrays.Add("Anaconda.Miniconda3")
			$WPFInstallminiconda.IsChecked = $false
		}
		if ($WPFInstallrust.IsChecked -eq $true)
		{
			$wingetarrays.Add("Rustlang.Rust.MSVC")
			$WPFInstallrust.IsChecked = $false
		}
		if ($WPFInstallgo.IsChecked -eq $true)
		{
			$wingetarrays.Add("GoLang.Go")
			$WPFInstallgo.IsChecked = $false
		}

		$OutputMsg = Show-MessageBox -Message "Yakin? ;) click OK kalo dah yakin beb :v" -Title "Begin Installation" -Buttons 'OKCancel'
		switch ($OutputMsg) {
			'Yes' {
				Download-Winget $wingetarrays.ToArray()
			}
			'Cancel' {
				$wingetarrays.Clear()
			}
		}
	})

	#===========================================================================
	# Shows the form
	#===========================================================================
	$Form.ShowDialog() | out-null
}
else {
	Write-Warning "Exiting program"
	exit 1
}
