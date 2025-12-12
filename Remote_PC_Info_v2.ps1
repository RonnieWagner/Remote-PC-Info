# --- Auto Elevate & Hide PS Window ---
if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell.exe `
        "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

Add-Type -AssemblyName PresentationFramework

# --- Create WPF Window ---
$XAML = @'
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Remote PC Info" Height="450" Width="520" 
    ResizeMode="NoResize" WindowStartupLocation="CenterScreen">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
            <TextBlock Text="PC Name:" VerticalAlignment="Center" FontSize="14"/>
            <TextBox x:Name="PCBox" Width="200" Margin="10,0,0,0" FontSize="14"/>
            <Button x:Name="RunButton" Content="Get Info" Width="100" Margin="10,0,0,0" FontSize="14"/>
        </StackPanel>

        <TextBlock Text="Results:" FontWeight="Bold" FontSize="16" Grid.Row="1" Margin="0,0,0,5"/>

        <TextBox x:Name="OutputBox" Grid.Row="2" FontFamily="Consolas" FontSize="14"
                 TextWrapping="Wrap" IsReadOnly="True" VerticalScrollBarVisibility="Auto"/>

        <Button x:Name="CloseButton" Content="Close" Grid.Row="3" Height="30" Width="100"
                HorizontalAlignment="Right" Margin="0,10,0,0" />
    </Grid>

</Window>
'@

# --- Parse XAML ---
[xml]$XamlXML = $XAML
$Reader = New-Object System.Xml.XmlNodeReader $XamlXML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Retrieve controls
$PCBox       = $Window.FindName("PCBox")
$RunButton   = $Window.FindName("RunButton")
$OutputBox   = $Window.FindName("OutputBox")
$CloseButton = $Window.FindName("CloseButton")

# Close button logic
$CloseButton.Add_Click({ $Window.Close() })

# --- Core Logic ---
$RunButton.Add_Click({
    $PC = $PCBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($PC)) {
        [System.Windows.MessageBox]::Show("Please enter a PC name.","Missing Input")
        return
    }

    $OutputBox.Text = "Gathering information from $PC ...`r`n"

    # Logged in user
    try { $LoggedOn = (Get-CimInstance Win32_ComputerSystem -ComputerName $PC).UserName }
    catch { $LoggedOn = "Unavailable" }

    # Model
    try { $Model = (Get-CimInstance Win32_ComputerSystem -ComputerName $PC).Model }
    catch { $Model = "Unavailable" }

    # Last Reboot
    try {
        $LastBootRaw = Get-WmiObject Win32_OperatingSystem -ComputerName $PC | Select-Object -ExpandProperty LastBootUpTime
        $LastReboot  = [Management.ManagementDateTimeConverter]::ToDateTime($LastBootRaw)
    } catch { $LastReboot = "Unavailable" }

    # Drive Info
    try {
        $DrivesRaw = Get-CimInstance Win32_LogicalDisk -ComputerName $PC -Filter "DriveType=3"
        $DriveReport = ($DrivesRaw | ForEach-Object {
            "{0}: Total {1} GB — Free {2} GB" -f `
                $_.DeviceID,
                [math]::Round($_.Size/1GB,2),
                [math]::Round($_.FreeSpace/1GB,2)
        }) -join "`r`n"
    } catch { $DriveReport = "Unavailable" }

    # Output
    $OutputBox.Text = @"
PC Name:         $PC
Model:           $Model
Logged in User:  $LoggedOn
Last Reboot:     $LastReboot

Drive Info:
$DriveReport
"@
})

# --- Show Window ---
$Window.ShowDialog() | Out-Null
