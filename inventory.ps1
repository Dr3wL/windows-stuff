# Import Active Directory module
Import-Module ActiveDirectory

# Prompt for credentials
$credentials = Get-Credential -Message "Enter credentials for Active Directory access" -UserName (whoami)

# Get all Windows computers in the domain using provided credentials
$computers = Get-ADComputer -Filter * -Properties * -Credential $credentials

# Create an array to store computer information
$computerInfo = @()

# Loop through each computer
foreach ($computer in $computers) {
    if ($computer.OperatingSystem -like "*Windows*") {
        # Get computer details
        $hostName = $computer.Name
        $ipv4Address = $computer.IPv4Address
        $ipv6Address = $computer.IPv6Address
        $macAddress = $computer.DNSHostName

        # Get operating system details
        $operatingSystem = $computer.OperatingSystem

        # Get services and versions (using Get-WmiObject)
        $services = Get-WmiObject -Class Win32_Service -ComputerName $hostName -ErrorAction SilentlyContinue -Credential $credentials | 
            Select-Object Name, DisplayName, StartMode, State, PathName

        # Create a custom object to store computer information
        $info = [PSCustomObject]@{
            "Host Name"            = $hostName
            "IPv4 Network Address" = $ipv4Address
            "IPv6 Network Address" = $ipv6Address
            "Mac"                  = $macAddress
            "Operating System"     = $operatingSystem
            "Services and Versions" = ($services | Out-String).Trim()
        }

        # Add computer information to the array
        $computerInfo += $info
    }
}

# Export computer information to CSV file on desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
$computerInfo | Export-Csv -Path "$desktopPath\ComputerInfo.csv" -NoTypeInformation
