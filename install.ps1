<#
.NOTES
   Author      : Rizal Achmad Pahlevi
   GitHub      : https://github.com/RizalAchp
    Version 0.0.1
#>

$inputXML = Get-Content "MainWindow.xaml" #uncomment for development
# $inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/MainWindow.xaml") #uncomment for Production

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
    $WPFTabNav.Items[2].IsSelected = $false
    $WPFTabNav.Items[3].IsSelected = $false
})
$WPFTab2BT.Add_Click({
    $WPFTabNav.Items[0].IsSelected = $false
    $WPFTabNav.Items[1].IsSelected = $true
    $WPFTabNav.Items[2].IsSelected = $false
    $WPFTabNav.Items[3].IsSelected = $false
    })
#===========================================================================
# install function - Install
#===========================================================================
function DownloadWinget([array]$itemwingets) {
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

#===========================================================================
# Tab 1 - Install
#===========================================================================
$WPFinstall.Add_Click({
    $wingetinstall = New-Object System.Collections.Generic.List[System.Object]
    If ( $WPFInstalladobe.IsChecked -eq $true ) {
        $wingetinstall.Add("Adobe.Acrobat.Reader.64-bit")
        $WPFInstalladobe.IsChecked = $false
    }
    If ( $WPFInstallaudacity.IsChecked -eq $true ) {
        $wingetinstall.Add("Audacity.Audacity")
        $WPFInstallaudacity.IsChecked = $false
    }
    If ( $WPFInstallbrave.IsChecked -eq $true ) {
        $wingetinstall.Add("BraveSoftware.BraveBrowser")
        $WPFInstallbrave.IsChecked = $false
    }
    If ( $WPFInstallchrome.IsChecked -eq $true ) {
        $wingetinstall.Add("Google.Chrome")
        $WPFInstallchrome.IsChecked = $false
    }
    If ( $WPFInstalldiscord.IsChecked -eq $true ) {
        $wingetinstall.Add("Discord.Discord")
        $WPFInstalldiscord.IsChecked = $false
    }
    If ( $WPFInstalletcher.IsChecked -eq $true ) {
        $wingetinstall.Add("Balena.Etcher")
        $WPFInstalletcher.IsChecked = $false
    }
    If ( $WPFInstallfirefox.IsChecked -eq $true ) {
        $wingetinstall.Add("Mozilla.Firefox")
        $WPFInstallfirefox.IsChecked = $false
    }
    If ( $WPFInstallgimp.IsChecked -eq $true ) {
        $wingetinstall.Add("GIMP.GIMP")
        $WPFInstallgimp.IsChecked = $false
    }
    If ( $WPFInstallimageglass.IsChecked -eq $true ) {
        $wingetinstall.Add("DuongDieuPhap.ImageGlass")
        $WPFInstallimageglass.IsChecked = $false
    }
    If ( $WPFInstallmpc.IsChecked -eq $true ) {
        $wingetinstall.Add("clsid2.mpc-hc")
        $WPFInstallmpc.IsChecked = $false
    }
    If ( $WPFInstallnotepadplus.IsChecked -eq $true ) {
        $wingetinstall.Add("Notepad++.Notepad++")
        $WPFInstallnotepadplus.IsChecked = $false
    }
    If ( $WPFInstallsevenzip.IsChecked -eq $true ) {
        $wingetinstall.Add("7zip.7zip")
        $WPFInstallsevenzip.IsChecked = $false
    }
    If ( $WPFInstallsharex.IsChecked -eq $true ) {
        $wingetinstall.Add("ShareX.ShareX")
        $WPFInstallsharex.IsChecked = $false
    }
    If ( $WPFInstallsumatra.IsChecked -eq $true ) {
        $wingetinstall.Add("SumatraPDF.SumatraPDF")
        $WPFInstallsumatra.IsChecked = $false
    }
    If ( $WPFInstallvlc.IsChecked -eq $true ) {
        $wingetinstall.Add("VideoLAN.VLC")
        $WPFInstallvlc.IsChecked = $false
    }
    If ( $WPFInstallblender.IsChecked -eq $true ) {
        $wingetinstall.Add("BlenderFoundation.Blender")
        $WPFInstallblender.IsChecked = $false
    }
    If ( $WPFInstallchromium.IsChecked -eq $true ) {
        $wingetinstall.Add("eloston.ungoogled-chromium")
        $WPFInstallchromium.IsChecked = $false
    }
    If ( $WPFInstallcpuz.IsChecked -eq $true ) {
        $wingetinstall.Add("CPUID.CPU-Z")
        $WPFInstallcpuz.IsChecked = $false
    }
    If ( $WPFInstalleartrumpet.IsChecked -eq $true ) {
        $wingetinstall.Add("File-New-Project.EarTrumpet")
        $WPFInstalleartrumpet.IsChecked = $false
    }
    If ( $WPFInstallepicgames.IsChecked -eq $true ) {
        $wingetinstall.Add("EpicGames.EpicGamesLauncher")
        $WPFInstallepicgames.IsChecked = $false
    }
    If ( $WPFInstallflameshot.IsChecked -eq $true ) {
        $wingetinstall.Add("Flameshot.Flameshot")
        $WPFInstallflameshot.IsChecked = $false
    }
    If ( $WPFInstallfoobar.IsChecked -eq $true ) {
        $wingetinstall.Add("PeterPawlowski.foobar2000")
        $WPFInstallfoobar.IsChecked = $false
    }
    If ( $WPFInstallgpuz.IsChecked -eq $true ) {
        $wingetinstall.Add("TechPowerUp.GPU-Z")
        $WPFInstallgpuz.IsChecked = $false
    }
    If ( $WPFInstallgreenshot.IsChecked -eq $true ) {
        $wingetinstall.Add("Greenshot.Greenshot")
        $WPFInstallgreenshot.IsChecked = $false
    }
    If ( $WPFInstallhandbrake.IsChecked -eq $true ) {
        $wingetinstall.Add("HandBrake.HandBrake")
        $WPFInstallhandbrake.IsChecked = $false
    }
    If ( $WPFInstallhwinfo.IsChecked -eq $true ) {
        $wingetinstall.Add("REALiX.HWiNFO")
        $WPFInstallhwinfo.IsChecked = $false
    }
    If ( $WPFInstallinkscape.IsChecked -eq $true ) {
        $wingetinstall.Add("Inkscape.Inkscape")
        $WPFInstallinkscape.IsChecked = $false
    }
    If ( $WPFInstallkeepass.IsChecked -eq $true ) {
        $wingetinstall.Add("KeePassXCTeam.KeePassXC")
        $WPFInstallkeepass.IsChecked = $false
    }
    If ( $WPFInstallobs.IsChecked -eq $true ) {
        $wingetinstall.Add("OBSProject.OBSStudio")
        $WPFInstallobs.IsChecked = $false
    }
    If ( $WPFInstallrufus.IsChecked -eq $true ) {
        $wingetinstall.Add("Rufus.Rufus")
        $WPFInstallrufus.IsChecked = $false
    }
    If ( $WPFInstallspotify.IsChecked -eq $true ) {
        $wingetinstall.Add("Spotify.Spotify")
        $WPFInstallspotify.IsChecked = $false
    }
    If ( $WPFInstallsteam.IsChecked -eq $true ) {
        $wingetinstall.Add("Valve.Steam")
        $WPFInstallsteam.IsChecked = $false
    }
    If ( $WPFInstallvoicemeeter.IsChecked -eq $true ) {
        $wingetinstall.Add("VB-Audio.Voicemeeter")
        $WPFInstallvoicemeeter.IsChecked = $false
    }
    If ( $WPFInstallwindirstat.IsChecked -eq $true ) {
        $wingetinstall.Add("WinDirStat.WinDirStat")
        $WPFInstallwindirstat.IsChecked = $false
    }
    If ( $WPFInstallzoom.IsChecked -eq $true ) {
        $wingetinstall.Add("Zoom.Zoom")
        $WPFInstallzoom.IsChecked = $false
    }

	DownloadWinget $wingetinstall.ToArray()
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
# Tab 2 - Tweak Buttons
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
	$WPFInstallatom.IsChecked = $true
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
	$WPFInstallatom.IsChecked = $true
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
	$WPFInstallatom.IsChecked = $true
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

$WPFalladev.Add_Click({
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
	$WPFInstallatom.IsChecked = $true
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
    $wingetinstall = New-Object System.Collections.Generic.List[System.Object]
	if ($WPFInstallgit.IsChecked -eq $true)
	{
		$wingetinstall.Add("Git.Git")
		$WPFInstallgit.IsChecked = $false
	}
	if ($WPFInstallwinterm.IsChecked -eq $true)
	{
		$wingetinstall.Add("Microsoft.WindowsTerminal")
		$WPFInstallwinterm.IsChecked = $false
	}
	if ($WPFInstallgithubdesktop.IsChecked -eq $true)
	{
		$wingetinstall.Add("Git.Git")
		$wingetinstall.Add("GitHub.cli")
		$wingetinstall.Add("GitHub.GitHubDesktop")
		$WPFInstallgithubdesktop.IsChecked = $false
	}
	if ($WPFInstalljetbrains.IsChecked -eq $true)
	{
		$WPFInstalljetbrains.IsChecked = $false
	}
	if ($WPFInstallandroidstudio.IsChecked -eq $true)
	{
		$WPFInstallandroidstudio.IsChecked = $false
	}
	if ($WPFInstallsublime.IsChecked -eq $true)
	{
		$WPFInstallsublime.IsChecked = $false
	}
	if ($WPFInstallvim.IsChecked -eq $true)
	{
		$WPFInstallvim.IsChecked = $false
	}
	if ($WPFInstallneovim.IsChecked -eq $true)
	{
		$WPFInstallneovim.IsChecked = $false
	}
	if ($WPFInstallneovide.IsChecked -eq $true)
	{
		$WPFInstallneovide.IsChecked = $false
	}
	if ($WPFInstallvisualstudio22.IsChecked -eq $true)
	{
		$WPFInstallvisualstudio22.IsChecked = $false
	}
	if ($WPFInstallvisualstudio19.IsChecked -eq $true)
	{
		$WPFInstallvisualstudio19.IsChecked = $false
	}
	if ($WPFInstallcodelite.IsChecked -eq $true)
	{
		$WPFInstallcodelite.IsChecked = $false
	}
	if ($WPFInstallpycharm.IsChecked -eq $true)
	{
		$WPFInstallpycharm.IsChecked = $false
	}
	if ($WPFInstallcygwin.IsChecked -eq $true)
	{
		$WPFInstallcygwin.IsChecked = $false
	}
	if ($WPFInstallmsys2.IsChecked -eq $true)
	{
		$WPFInstallmsys2.IsChecked = $false
	}
	if ($WPFInstallcmake.IsChecked -eq $true)
	{
		$WPFInstallcmake.IsChecked = $false
	}
	if ($WPFInstallvscode.IsChecked -eq $true)
	{
		$WPFInstallvscode.IsChecked = $false
	}
	if ($WPFInstallvscodium.IsChecked -eq $true)
	{
		$WPFInstallvscodium.IsChecked = $false
	}
	if ($WPFInstallatom.IsChecked -eq $true)
	{
		$WPFInstallatom.IsChecked = $false
	}
	if ($WPFInstallpowertoys.IsChecked -eq $true)
	{
		$WPFInstallpowertoys.IsChecked = $false
	}
	if ($WPFInstallwindirstat.IsChecked -eq $true)
	{
		$WPFInstallwindirstat.IsChecked = $false
	}
	if ($WPFInstalladvancedip.IsChecked -eq $true)
	{
		$WPFInstalladvancedip.IsChecked = $false
	}
	if ($WPFInstallmremoteng.IsChecked -eq $true)
	{
		$WPFInstallmremoteng.IsChecked = $false
	}
	if ($WPFInstallputty.IsChecked -eq $true)
	{
		$WPFInstallputty.IsChecked = $false
	}
	if ($WPFInstallscp.IsChecked -eq $true)
	{
		$WPFInstallscp.IsChecked = $false
	}
	if ($WPFInstallwireshark.IsChecked -eq $true)
	{
		$WPFInstallwireshark.IsChecked = $false
	}
	if ($WPFInstalljava8.IsChecked -eq $true)
	{
		$WPFInstalljava8.IsChecked = $false
	}
	if ($WPFInstalljava16.IsChecked -eq $true)
	{
		$WPFInstalljava16.IsChecked = $false
	}
	if ($WPFInstalljava18.IsChecked -eq $true)
	{
		$WPFInstalljava18.IsChecked = $false
	}
	if ($WPFInstallpython3.IsChecked -eq $true)
	{
		$WPFInstallpython3.IsChecked = $false
	}
	if ($WPFInstallnodejs.IsChecked -eq $true)
	{
		$WPFInstallnodejs.IsChecked = $false
	}
	if ($WPFInstallnodejslts.IsChecked -eq $true)
	{
		$WPFInstallnodejslts.IsChecked = $false
	}
	if ($WPFInstallminiconda.IsChecked -eq $true)
	{
		$WPFInstallminiconda.IsChecked = $false
	}
	if ($WPFInstallrust.IsChecked -eq $true)
	{
		$WPFInstallrust.IsChecked = $false
	}
	if ($WPFInstallgo.IsChecked -eq $true)
	{
		$WPFInstallgo.IsChecked = $false
	}
})

#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null
