netsh advfirewall firewall delete rule name="LLM Gemma4-4B 5003" 2>$null
netsh advfirewall firewall add rule name="LLM Gemma4-4B 5003" dir=in action=allow protocol=TCP localport=5003 remoteip=192.168.149.0/255.255.255.0 profile=any enable=yes
if ($LASTEXITCODE -eq 0) { Write-Output "OK: firewall rule added" } else { Write-Output "FAIL: exit $LASTEXITCODE"; exit 1 }
