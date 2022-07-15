function testingdoang([array]$items) {
	foreach($item in $items) {
		Write-Output "item: $item"
	}
}

$wingetinstall = New-Object System.Collections.Generic.List[System.Object]
$wingetinstall.Add("satu")
$wingetinstall.Add("dua")
$wingetinstall.Add("tiga")
$wingetinstall.Add("empat")
$wingetinstall.Add("lima")

Write-Output "as objects[system.objects] = $wingetinstall"

Write-Output "as objects[arrays] = $($wingetinstall.ToArray())"

testingdoang $wingetinstall.ToArray()
