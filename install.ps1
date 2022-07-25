<#
.NOTES
	Author      : Rizal Achmad Pahlevi
	GitHub      : https://github.com/RizalAchp/rz-winscripts
	Version 0.0.1
#>

# $inputXML = Get-Content "MainWindow.xaml" #uncomment for development
$inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/RizalAchp/rz-winscripts/master/MainWindow.xaml") #uncomment for Production
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML #Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{ $Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch [System.Management.Automation.MethodInvocationException]
{
	Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
	write-host $error[0].Exception.Message -ForegroundColor Red
	If ($error[0].Exception.Message -like "*button*") {
		write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
	}
}
catch{ Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed." }


$xaml.SelectNodes("//*[@Name]") | ForEach-Object{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}


Function Get-FormVariables{
	If ($global:ReadmeDisplay -ne $true){
		Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true
	}
	write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
	get-variable WPF*
}


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
    [int] $DefBtnIdx
  )
	Set-StrictMode -Off
	$btnMap = @{
	'OK'               = @{ buttonList = 'OK'; defBtnIdx = 0 }
	'OKCancel'         = @{ buttonList = 'OK', 'Cancel'; defBtnIdx = 0; cancelButtonIndex = 1 }
	'AbortRetryIgnore' = @{ buttonList = 'Abort', 'Retry', 'Ignore'; defBtnIdx = 2; ; cancelButtonIndex = 0 };
	'YesNoCancel'      = @{ buttonList = 'Yes', 'No', 'Cancel'; defBtnIdx = 2; cancelButtonIndex = 2 };
	'YesNo'            = @{ buttonList = 'Yes', 'No'; defBtnIdx = 0; cancelButtonIndex = 1 }
	'RetryCancel'      = @{ buttonList = 'Retry', 'Cancel'; defBtnIdx = 0; cancelButtonIndex = 1 }
	}
	$numButtons = $btnMap[$Buttons].buttonList.Count
	$defIdx = [math]::Min($numButtons - 1, ($btnMap[$Buttons].defBtnIdx, $DefBtnIdx)[$PSBoundParameters.ContainsKey('DefBtnIdx')])
    Add-Type -Assembly System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon, $defIdx * 256).ToString()
}

function CheckInstalledPrograms([string]$Program)
{
	Get-Command -Name $Program -ErrorAction SilentlyContinue -ErrorVariable CommandNotAvailableError;
	if ($CommandNotAvailableError) {
		return $false
	}
	return $true
}

function Get-Aria {
	$ARIA2CLInks = "https://github.com/RizalAchp/rz-winscripts/releases/download/alternatives/aria2c.exe"
	$CURRDIR = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')
	$OutputAria = "$CURRDIR\aria2c.exe"
	$wc = New-Object System.Net.WebClient
	$wc.DownloadFile($ARIA2CLInks, $OutputAria)
	return $OutputAria
}

#===========================================================================
# install function - Install
#===========================================================================
function DownloadWithWinget([System.Array]$ItemWingets) {
	$wingetResult = New-Object System.Collections.Generic.List[System.Object]
	foreach ( $item in $ItemWingets )
	{
		$ArgList = "-command winget install -e --accept-source-agreements --accept-package-agreements $item | Out-Host"
		Start-Process powershell.exe -Verb RunAs -ArgumentList $ArgList -Wait -WindowStyle Maximized
		$wingetResult.Add("$item`n")
	}
	$wingetResult.ToArray()
	$wingetResult | ForEach-Object { $_ } | Out-Host

	$TittleArgs = "Info Installed Programs WIth Winget"
	$MessageArgs = "Installed:`n$($wingetResult)"
	Show-MessageBox -Message $MessageArgs -Title $TittleArgs -Buttons 'OK' -Icon 'Information'
}

function DownloadWithAria([System.Array]$ItemArias) {
	$DOWNLOADFOLDER = "${env:HOMEDRIVE}${env:HOMEPATH}\Downloads"
	$Aria2CExec = Get-Aria
	if(Test-Path $Aria2CExec -eq $false)
	{
		$TittleArgs = "Aria2c is is Missing, i Think.."
		$MessageArgs = "Terjadi Kesalahan saat mendownload Aria2c, Coba Lagi (Retry)! or Cancel"
		$ReturnMsg = Show-MessageBox -Message $MessageArgs -Title $TittleArgs -Buttons 'RetryCancel' -Icon 'Information'
		switch ($ReturnMsg) {
			'Retry' { return DownloadWithAria -ItemArias $ItemArias }
			'Cancel' { return }
		}
	}
	$ariaResult = New-Object System.Collections.Generic.List[System.Object]
	foreach( $item in $ItemArias )
	{
		$ArgList = "--command $Aria2CExec -d $DOWNLOADFOLDER | Out-Host"
		Start-Process powershell.exe -Verb RunAs -ArgumentList $ArgList -Wait  -WindowStyle Maximized
		$ariaResult.Add("$item`n")
	}
	$ariaResult.ToArray() | ForEach-Object { $_ } | Out-Host
	$TittleArgs = "Info Installed Programs WIth Aria2c"
	$MessageArgs = "Installed Progams On Download $DOWNLOADFOLDER :`n$ariaResult"
	Show-MessageBox -Message $MessageArgs -Title $TittleArgs -Buttons 'OK' -Icon 'Information'

}

$ListOfPackageName = @( "Adobe.Acrobat.Reader.64-bit", "Famatech.AdvancedIPScanner",
	"Google.AndroidStudio", "Audacity.Audacity", "Lexikos.AutoHotkey -s winget",
	"BlenderFoundation.Blender", "BraveSoftware.BraveBrowser", "Google.Chrome",
	"eloston.ungoogled-chromium", "Kitware.CMake", "CodeLite.CodeLite", "CPUID.CPU-Z",
	"Cygwin.Cygwin", "Discord.Discord", "File-New-Project.EarTrumpet",
	"EpicGames.EpicGamesLauncher", "Balena.Etcher", "Mozilla.Firefox",
	"Flameshot.Flameshot", "PeterPawlowski.foobar2000", "GIMP.GIMP", "Git.Git",
	"GitHub.GitHubDesktop", "GoLang.Go", "TechPowerUp.GPU-Z", "Greenshot.Greenshot",
	"HandBrake.HandBrake", "REALiX.HWiNFO", "DuongDieuPhap.ImageGlass", "Inkscape.Inkscape",
	"AdoptOpenJDK.OpenJDK.16", "AdoptOpenJDK.OpenJDK.18", "AdoptOpenJDK.OpenJDK.8",
	"JetBrains.Toolbox", "KeePassXCTeam.KeePassXC", "TheDocumentFoundation.LibreOffice.LTS",
	"Anaconda.Miniconda3", "clsid2.mpc-hc", "mRemoteNG.mRemoteNG", "msys2.msys2",
	"Neovim.Neovim", "OpenJS.NodeJS", "OpenJS.NodeJS.LTS", "Notepad++.Notepad++",
	"OBSProject.OBSStudio", "Microsoft.PowerToys --source winget", "PuTTY.PuTTY --source winget",
	"JetBrains.PyCharm.Community", "Python.Python.3", "Rufus.Rufus", "Rustlang.Rust.MSVC",
	"WinSCP.WinSCP", "7zip.7zip", "ShareX.ShareX", "Spotify.Spotify", "Valve.Steam",
	"SublimeHQ.SublimeText.4", "SumatraPDF.SumatraPDF", "vim.vim",
	"Microsoft.VisualStudio.2019.Community", "Microsoft.VisualStudio.2022.Community",
	"VideoLAN.VLC", "VB-Audio.Voicemeeter", "Microsoft.VisualStudioCode --source winget",
	"VSCodium.VSCodium", "WinDirStat.WinDirStat", "Microsoft.WindowsTerminal",
	"WiresharkFoundation.Wireshark", "Zoom.Zoom"
)
$ListCheckBoxes = @($(Get-Variable "WPFInstall*").Value)

function InitializeDownloadWinget {
	$ListWillDownloaded = New-Object System.Collections.Generic.List[System.Object]
	$Index = 0
	foreach ($CBItem in $ListCheckBoxes) {
		if ($CBItem.IsChecked -eq $false) { $Index++; continue; }
		else { $ListWillDownloaded.Add($ListOfPackageName.Get($Index)); $Index++;}
	}
	DownloadWithWinget -ItemWingets $ListWillDownloaded.ToArray()
}

#===========================================================================
# Navigation Controls
#===========================================================================
$JUMLAHTAB = 3
$WPFTab1BT.Add_Click({
	$TABIdx = 0
	foreach ($Idx in $(0..$($JUMLAHTAB-1))) {
		if ($Idx -eq $TABIdx) { $WPFTabNav.Items[$Idx].IsSelected = $true; }
		else { $WPFTabNav.Items[$Idx].IsSelected = $false }
	}
})
$WPFTab2BT.Add_Click({
	$TABIdx = 1
	foreach ($Idx in $(0..$($JUMLAHTAB-1))) {
		if ($Idx -eq $TABIdx) { $WPFTabNav.Items[$Idx].IsSelected = $true; }
		else { $WPFTabNav.Items[$Idx].IsSelected = $false }
	}
})
$WPFTab3BT.Add_Click({
	$TABIdx = 2
	foreach ($Idx in $(0..$($JUMLAHTAB-1))) {
		if ($Idx -eq $TABIdx) { $WPFTabNav.Items[$Idx].IsSelected = $true; }
		else { $WPFTabNav.Items[$Idx].IsSelected = $false }
	}
})

#===========================================================================
# Tab 1 - Install
#===========================================================================
$WPFselectinstall.Add_Click({
	if ((CheckInstalledPrograms -Program "winget") -eq $false)
	{
		$MessageArgs = "Winget tidak terinstall di PC ini!..$(
		)PAKE WINDOWS BAJAKAN YA..WKWK..$(
		)Kamu tidak dapat menginstal program pada bagian ini $(
		)jika tidak memiliki Winget! Mungkin Pada TAB: MYCHOICE bisa membantu!"
		$ErrorArgs = "Warning: Winget not Installed"
		Show-MessageBox -Message $MessageArgs  -Title $ErrorArgs -Buttons 'OK' -Icon 'Warning'
	}
	else {
		$OutputMsg = Show-MessageBox -Message "Yakin? ;) click OK kalo dah yakin beb :v" -Title "Begin Installation" -Buttons 'OKCancel'
		switch ($OutputMsg) {
			'OK' { InitializeDownloadWinget; }
			'Cancel' { return; }
		}
	}
})

$WPFselectupgrade.Add_Click({
	Start-Process powershell.exe -Verb RunAs -ArgumentList "-command winget upgrade --all  | Out-Host" -Wait -WindowStyle Maximized
	Show-MessageBox -Message "Done Upgrading All Programs!" -Title "Done Upgrade" -Icon 'Information' -Buttons 'OK'
})

function CheckByIndex([System.Array]$Indexes) {
	foreach ($Item in $ListCheckBoxes) { $Item.IsChecked = $false; }
	foreach ($Idx in $Indexes) { $ListCheckBoxes[$Idx].IsChecked = $true; }
}
#===========================================================================
# Tab 2 - Development Tabs
#===========================================================================
$WPFembeddev.Add_Click({
	$IndexEmbeded = 21,22,42,46,48,50,63
	CheckByIndex -Indexes $IndexEmbeded
})

$WPFwebdev.Add_Click({
	$IndexWebDev = 21,22,42,48,50,63,45
	CheckByIndex -Indexes $IndexWebDev
})

$WPFmobiledev.Add_Click({
	$IndexMobileDev = 2,21,22,63
	CheckByIndex -Indexes $IndexMobileDev
})

$WPFalldev.Add_Click({
	$IndexAll = 0..68
	CheckByIndex -Indexes $IndexAll
})

$WPFClickInstalldev.Add_Click({
	if ((CheckInstalledPrograms -Program "winget") -eq $false)
	{
		$MessageArgs = "Winget tidak terinstall di PC ini!..$(
		)PAKE WINDOWS BAJAKAN YA..WKWK..$(
		)Kamu tidak dapat menginstal program pada bagian ini $(
		)jika tidak memiliki Winget! Mungkin Pada TAB: MYCHOICE bisa membantu!"
		$ErrorArgs = "Warning: Winget not Installed"
		Show-MessageBox -Message $MessageArgs  -Title $ErrorArgs -Buttons 'OK' -Icon 'Warning'
	}
	else {
		$OutputMsg = Show-MessageBox -Message "Yakin? ;) click OK kalo dah yakin beb :v" -Title "Begin Installation" -Buttons 'OKCancel'
		switch ($OutputMsg) {
			'OK' { InitializeDownloadWinget; }
			'Cancel' { return; }
		}
	}
})
$RSGWingets = @(
	"Git.Git",
	"Python.Python.3",
	"OpenJS.NodeJS.LTS",
	"PuTTY.PuTTY --source winget",
	"GitHub.GitHubDesktop",
	"Microsoft.VisualStudioCode --source winget"
)

# TODO!
$RSGAria2c = @(
	"https://github.com/git-for-windows/git/releases/download/v2.37.1.windows.1/Git-2.37.1-64-bit.exe",
	"https://www.python.org/ftp/python/3.10.5/python-3.10.5-amd64.exe",
	"https://nodejs.org/dist/v16.16.0/node-v16.16.0-x64.msi",
	"https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.77-installer.msi",
	"https://central.github.com/deployments/desktop/desktop/latest/win32",
	"https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
)
$WPFReadySetGo.Add_Click({
	$IsUsingWinget = $true

	if ((CheckInstalledPrograms -Program "winget") -eq $false)
	{
		$MessageArgs = "HMM.. sepertinya Winget tidak terinstall di PC ini..$(
		)PAKE WINDOWS BAJAKAN YA..WKWK..  $(
		)Tapi Tenang! Saya ada Solusi! $(
		)Yes untuk Lanjut, atau No untuk Tidak jadi :) !"
		$ErrorArgs = "Warning: Winget not Installed"
		$ReturnBox = Show-MessageBox -Message $MessageArgs  -Title $ErrorArgs -Buttons 'YesNo' -Icon 'Warning'
		switch ($ReturnBox) {
			'Yes' {
				$IsUsingWinget = $false
			}
			'No' {
				$IsUsingWinget = $true
			}
		}
	}

	$ListInstallPrograms = New-Object System.Collections.Generic.List[System.Object]
	$ProgExecIdentifier = @("git.exe", "python.exe", "node.exe", "putty.exe", "github", "code.cmd")
	$IdxDownloads = 0
	foreach ($ProgExe in $ProgExecIdentifier) {
		switch (CheckInstalledPrograms -Program $ProgExe){
			$true {
				$IdxDownloads++
			}
			$false {
				if ($IsUsingWinget -eq $true) {
					$ListInstallPrograms.Add($RSGWingets[$IdxDownloads])
				} else {
					$ListInstallPrograms.Add($RSGAria2c[$IdxDownloads])
				}
				$IdxDownloads++
			}
		}
	}

	$TittleArgs = "Programs to Install"
	$MessageArgs = "Program to Install:`n[$($ListInstallPrograms)]`n Are you sure?"
	$ReturnBox = Show-MessageBox -Message $MessageArgs -Title $TittleArgs -Buttons 'YesNo' -Icon 'Information'
	switch ($ReturnBox) {
		'Yes' {
			if ($IsUsingWinget -eq $true) {
				DownloadWithWinget -ItemWingets $ListInstallPrograms.ToArray()
			} else {
				DownloadWithAria -ItemArias $ListInstallPrograms.ToArray()
			}
		}
		'No' {
			return
		}
	}
})


#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null
