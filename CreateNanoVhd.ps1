
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
	
########################################################################################################
#Name: Create Nano Vhd.ps1
#Author: Viktor Lindström
#
#Comments:
#Creates custom Nano VHD from Windows 2016 ISO. I have only tried it with Technical preview 4.
#You have to run the script as administrator.
#Sometimes the script stop on "dismounting image..." this is microsofts script that stops and the vhd is created att you can stop the script manually.
#1. Enter namne of VHD
#2. Check the functions you want to add and press button add server, you can add multiple server if you want to.
#3. Press button Add Disk Image to point out windows 2016 iso.
#4. Press button create servers to start building VHDs.
#5. Enter Administrator password
#6. You ne VHD will be stored in C:\Temp_NanoServer
########################################################################################################
 
 
 
 
#build GUI
 
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
 
[xml]$XAML = @'
 
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:create_nano_server"
        Title="Create Nano Server" Height="483.193" Width="705.901">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="133*"/>
            <RowDefinition Height="319*"/>
        </Grid.RowDefinitions>
        <Label Name="labelComputername" Content="Computer name:" HorizontalAlignment="Left" Margin="24,28,0,0" VerticalAlignment="Top" Width="111" Height="26"/>
        <Label Name="labelFeaturesAndRoles" Content="Feature and roles:" HorizontalAlignment="Left" Margin="24,73,0,0" VerticalAlignment="Top" FontWeight="Bold" Height="26" Width="111"/>
        <CheckBox Name="checkBoxHyper" Content="Hyper-V role" HorizontalAlignment="Left" Margin="33,108,0,0" VerticalAlignment="Top" Height="15" Width="88"/>
        <CheckBox Name="checkBoxFailover" Content="Failover Clustering" HorizontalAlignment="Left" Margin="33,128,0,0" VerticalAlignment="Top" Height="15" Width="117" Grid.RowSpan="2"/>
        <CheckBox Name="checkBoxFile" Content="File Server role and other storage components" HorizontalAlignment="Left" Margin="33,35,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="265"/>
        <CheckBox Name="checkBoxWindowsDefender" Content="Windows Defender Antimalware" HorizontalAlignment="Left" Margin="33,54,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="190"/>
        <CheckBox Name="checkBoxReverse" Content="Reverse forwarders for application compatibility" HorizontalAlignment="Left" Margin="33,75,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="272"/>
        <CheckBox Name="checkBoxDns" Content="DNS Server role" HorizontalAlignment="Left" Margin="33,95,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="104"/>
        <CheckBox Name="checkBoxDcs" Content="Desired State Configuration (DSC)" HorizontalAlignment="Left" Margin="33,115,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="199"/>
        <CheckBox Name="checkBoxIis" Content="Internet Information Server (IIS)" HorizontalAlignment="Left" Margin="33,135,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="187"/>
        <CheckBox Name="checkBoxContainers" Content="Host support for Windows Containers" HorizontalAlignment="Left" Margin="33,155,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="220"/>
        <CheckBox Name="checkBoxSystemCenter" Content="System Center Virtual Machine Manager agent" HorizontalAlignment="Left" Margin="33,175,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="266"/>
        <CheckBox Name="checkBoxNpds" Content="Network Performance Diagnostics Service (NPDS)" HorizontalAlignment="Left" Margin="33,195,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="281"/>
        <CheckBox Name="checkBoxDcb" Content="Data Center Bridging" HorizontalAlignment="Left" Margin="33,15,0,0" VerticalAlignment="Top" Grid.Row="1" Height="15" Width="389"/>
        <TextBox Name="textBoxComputerName" HorizontalAlignment="Left" Height="23" Margin="133,32,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120"/>
        <Label Name="labelServers" Content="Servers:" HorizontalAlignment="Left" Margin="382,28,0,0" VerticalAlignment="Top" Height="26" Width="51"/>
        <ListBox Name="listBox" HorizontalAlignment="Left" Height="332" Margin="456,32,0,0" Grid.RowSpan="2" VerticalAlignment="Top" Width="227"/>
        <Button Name="buttonAddServer" Content="Add Server" HorizontalAlignment="Left" Margin="33,247,0,0" Grid.Row="1" VerticalAlignment="Top" Width="75" Height="20"/>
        <Button Name="buttonCreateServers" Content="Create Servers" HorizontalAlignment="Left" Margin="456,276,0,0" Grid.Row="1" VerticalAlignment="Top" Width="99" Height="20"/>
        <Button Name="buttonAddIso" Content="Add Disk Image" HorizontalAlignment="Left" Margin="456,247,0,0" Grid.Row="1" VerticalAlignment="Top" Width="99" RenderTransformOrigin="0.5,0.5"/>
        <Label Name="labelAddDiskImage" Content="" HorizontalAlignment="Left" Margin="107,244,0,0" Grid.Row="1" VerticalAlignment="Top" Width="312"/>
 
    </Grid>
</Window>
'@
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}
$xaml.SelectNodes("//*[@Name]") | foreach {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}
 
 
############################################################################################################
$tempPath = "C:\Temp_NanoServer"
$hyperV = "-Compute "
$clustering = "-Clustering "
$oemDrivers = "-OEMDrivers "
$fileServer = "-Storage "
$defender = "-Defender "
$reverseForwarders = "-ReverseForwarders "
$dnsServer = "-Packages Microsoft-NanoServer-DNS-Package "
$dsc = "-Packages Microsoft-NanoServer-DSC-Package "
$iis = "-Packages Microsoft-NanoServer-IIS-Package "
$containers = "-Containers "
$sccm = "-Packages Microsoft-Windows-Server-SCVMM-Package -Packages Microsoft-Windows-Server-SCVMM-Compute-Package " 
$npds = "-Packages Microsoft-NanoServer-NPDS-Package "
$dcb = "-Packages Microsoft-NanoServer-DCB-Package "
$ipAddress = "-Ipv4Address "
$subnetMask = "-Ipv4SubnetMask "
$gateway = "-Ipv4Gateway "
$azure = "-ForAzure "
 
 
 
 
# Show an Open File Dialog and return the file selected by the user.
function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}
 
 
$servers = @()
 
        $buttonAddServer.add_click({ 
 
        if ($checkBoxHyper.IsChecked) {$arguments += $hyperV}
        if ($checkBoxFailover.IsChecked) {$arguments += $clustering}
        if ($checkBoxBasic.IsChecked) {$arguments += $oemDrivers}
        if ($checkBoxFile.IsChecked) {$arguments += $fileServer}
        if ($checkBoxWindowsDefender.IsChecked) {$arguments += $defender}
        if ($checkBoxReverse.IsChecked) {$arguments += $reverseForwarders}
        if ($checkBoxDns.IsChecked) {$arguments += $dnsServer}
        if ($checkBoxDcs.IsChecked) {$arguments += $dsc}
        if ($checkBoxIis.IsChecked) {$arguments += $iis}
        if ($checkBoxContainers.IsChecked) {$arguments += $containers}
        if ($checkBoxSystemCenter.IsChecked) {$arguments += $sccm}
        if ($checkBoxNpds.IsChecked) {$arguments += $npds}
        if ($checkBoxDcb.IsChecked) {$arguments += $dcb}
 
            $Global:servers += New-Object psobject -Property @{
                        'Servername' = $textBoxComputerName.Text
                        'arguments' = $arguments
                        }
                        
                        $listServerArguments = $textBoxComputerName.Text + " " + $arguments
                        $listBox.Items.Add($listServerArguments)
                       if ($Variable)
                        {
                        Clear-Variable -Name arguments
                        }
})
            $buttonAddIso.add_click({
 
            $Global:imagePath = Read-OpenFileDialog -WindowTitle "Select Windows 2016 ISO" -InitialDirectory 'C:\' -Filter "ISO files (*.iso)|*.iso"
            if (![string]::IsNullOrEmpty($imagePath)) { $labelAddDiskImage.Content = $imagePath }
            else { "You did not select a file." }
           
            
            })
                
                $buttonCreateServers.add_click({
 
                    # Mount disk image.
                    Mount-DiskImage -ImagePath $imagePath 
                    
                    # Get driveletter of mounted diskimage.
                    $driveLetterIso = (Get-DiskImage -ImagePath $imagePath | Get-Volume).DriveLetter + ":\"
                    
                    # Path to Nano Server folder on image.
                    $pathNanoServer = $driveLetterIso + "NanoServer"
 
                    
                    if (-Not(Test-Path "C:\temp_NanoServer\Convert-WindowsImage.ps1"))
                    {
                    # Create temp path to place scripts from nanoserverfolder.
                    New-Item -ItemType Directory -Path $tempPath
                    # Copy scripts from disk image to temp folder.
                    Copy-Item -Path ($pathNanoServer + "\*.ps*") -Destination $tempPath
                    }
                        
                        # Test if user is running powershell as administrator
                        function Test-Administrator  
                            {  
                            $user = [Security.Principal.WindowsIdentity]::GetCurrent();
                            (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
                            }
 
                                if (Test-Administrator)
                                {
                                    Set-Location $tempPath
                                    Import-Module .\NanoServerImageGenerator.psm1 -Verbose
                                  
                                }
                                else
                                {
                                Write-Host "You are not running powershell as administrator" -ErrorAction Stop -ForegroundColor Red -BackgroundColor Yellow
                                $labelAddDiskImage.Content = "You are not running powershell as administrator"
                                return
                                }
                                
            foreach ($server in $servers)
            {
                # create the VHD
                $targetPath = ".\nanoServerVM\" +$server.Servername + ".vhd"
                $commandNewNanoServer = "New-NanoServerImage -MediaPath $driveLetterIso -BasePath .\Base -TargetPath $targetPath -ComputerName $($server.Servername) $($server.arguments) -GuestDrivers -EnableRemoteManagementPort -Language en-US"
                Invoke-Expression -Command $commandNewNanoServer
          
            }
             })
 
$Form.ShowDialog() | out-null
