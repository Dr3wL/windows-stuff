$credentials = Get-Credential -Message "Enter a set of domain administrator credentials"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Get all Windows computers in the domain using provided credentials
$computers = Get-ADComputer -Filter * -Properties * -Credential $credentials

# Create an array to store computer information
$computerInfo = @()

# Loop through each computer
foreach ($computer in $computers) {
    if ($computer.OperatingSystem -like "*Windows*") {
        # Get IP address info using Invoke-Command
        $ipInfo = Invoke-Command -ComputerName $computer.Name -Credential $credentials -ScriptBlock {
            $activeNic = Get-NetAdapter | Select-Object -ExpandProperty IfIndex
            [ordered]@{
                "Hostname"        = $env:COMPUTERNAME
                "IPv4 Address"    = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.ifIndex -eq $activeNic} | Select-Object -ExpandProperty IPAddress)
                "IPv6 Address"    = (Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.ifIndex -eq $activeNic} | Select-Object -ExpandProperty IPAddress)
                "MAC Address"     = (Get-NetAdapter | Select-Object -ExpandProperty MacAddress)
            }
        }

        # Get operating system details
        $operatingSystem = $computer.OperatingSystem

        # Get services information using Invoke-Command
        $servicesInfo = Invoke-Command -ComputerName $computer.Name -Credential $credentials -ScriptBlock {
            Get-Service | Select-Object Name, DisplayName, StartType, Status
        }

        # Create a custom object to store computer information
        $info = [PSCustomObject]@{
            "Host Name"            = $ipInfo.Hostname
            "IPv4 Network Address" = $ipInfo."IPv4 Address"
            "IPv6 Network Address" = $ipInfo."IPv6 Address"
            "Mac"                  = $ipInfo."MAC Address"
            "Operating System"     = $operatingSystem
            "Services"             = ($servicesInfo | Format-Table -AutoSize | Out-String).Trim()
        }

        # Add computer information to the array
        $computerInfo += $info
    }
}

# Export computer information to CSV file on desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
$computerInfo | Export-Csv -Path "$desktopPath\ComputerInfo.csv" -NoTypeInformation
