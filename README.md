# Remote PC Info (PowerShell GUI Tool)

A simple WPF-based PowerShell tool for Desktop Support Technicians.  
Allows technicians to quickly gather system information from a remote PC using a clean point-and-click GUI.

## Features
- Automatic elevation (UAC prompt)
- No PowerShell console window (GUI only)
- Query a remote PC by hostname
- Displays:
  - Logged-in user
  - System model
  - Last reboot time
  - Drive storage totals (GB)
- Clean, simple interface for techs

## How to Use
1. Copy `Remote_PC_Info.ps1` to your **Desktop**.
2. Double-click it — you will see a UAC prompt.
3. Enter the remote PC name.
4. Click **Get Info**.
5. The information will populate in the GUI window.

For detailed instructions, see:  
`Remote_PC_Info_Instructions.txt`

## Requirements
- Windows 10/11
- PowerShell 5.1
- Technician account with remote access permissions

## License
MIT License (Feel free to use or modify)
