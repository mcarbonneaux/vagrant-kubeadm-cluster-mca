if ((Get-Host).Version.Major -lt 7) {
  echo "you must install power shell 7 before use this script!"
  exit -1;
}

$powershellexe=[System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$routenb=(Get-NetRoute  | Where-Object {$_.DestinationPrefix -eq "10.10.10.0/24" } | measure).Count
$scriptpath= $MyInvocation.MyCommand.Source, $args | %{ $_ }

if ($routenb -eq 0) {
  # require admin elevation
  if (!
      #current role
      (New-Object Security.Principal.WindowsPrincipal(
	  [Security.Principal.WindowsIdentity]::GetCurrent()
      #is admin?
      )).IsInRole(
	  [Security.Principal.WindowsBuiltInRole]::Administrator
      )
  ) {
      #elevate script and exit current non-elevated runtime
      echo "Route add need admin privileg!"
      echo 'Run the script in admin to add route...'
      Start-Process -Verb RunAs -WindowStyle Hidden -FilePath $powershellexe -ArgumentList  ( '-File', $scriptpath )
      $iteration=0
      while(($routenb=(Get-NetRoute  | Where-Object {$_.DestinationPrefix -eq "10.10.10.0/24" } | measure).Count) -eq 0)
      {
        Start-Sleep -Milliseconds 100
	$iteration++
	if ($routenb -ne 0 -or $iteration -gt 20) {
	 break
	}
      }

      if ($routenb -ne 0) {
         echo "Route added!"
         Get-NetRoute  | Where-Object {$_.DestinationPrefix -eq "10.10.10.0/24" } 
      } else {
         echo "Error: route not added!"
	 echo "use this command in admin powershell: route add 10.10.10.0/24  172.22.100.2"
	 echo "to add manualy the route"
      }
      exit
  }
  else {
    $ifindex=(Get-NetIPAddress  | Where-Object {$_.IPv4Address -eq "172.22.100.1" }).ifIndex
    #echo "add route for 10.10.10.0/24 on interface index: $ifindex"
    New-NetRoute -DestinationPrefix "10.10.10.0/24" -InterfaceIndex $ifindex -NextHop "172.22.100.2" -PolicyStore "ActiveStore"
  }
} else {
  echo "Route already added"
}
