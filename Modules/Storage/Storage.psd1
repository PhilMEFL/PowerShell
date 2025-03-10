@{
    GUID = '41486F7D-842F-40F1-ACE4-8405F9C2ED9B'
    Author="Microsoft Corporation"
    CompanyName="Microsoft Corporation"
    Copyright="� Microsoft Corporation. All rights reserved."
    ModuleVersion = '2.0.0.0'
    PowerShellVersion = '3.0'
    FormatsToProcess = 'Storage.format.ps1xml'
    TypesToProcess = 'Storage.types.ps1xml'
    NestedModules = @(
        'Disk.cdxml',
        'DiskImage.cdxml',
        'FileIntegrity.cdxml',
        'FileServer.cdxml',
        'FileShare.cdxml',
        'FileStorageTier.cdxml',
        'InitiatorId.cdxml',
        'InitiatorPort.cdxml',
        'MaskingSet.cdxml',
        'OffloadDataTransferSetting.cdxml',
        'Partition.cdxml',
        'PhysicalDisk.cdxml',
        'ResiliencySetting.cdxml',
        'StorageCmdlets.cdxml',
        'StorageEnclosure.cdxml',
        'StorageJob.cdxml',
        'StorageHealth.cdxml',
        'StorageNode.cdxml',
        'StoragePool.cdxml',
        'StorageProvider.cdxml',
        'StorageReliabilityCounter.cdxml',
        'StorageSetting.cdxml',
        'StorageSubSystem.cdxml',
        'StorageTier.cdxml',
        'TargetPort.cdxml',
        'TargetPortal.cdxml',
        'VirtualDisk.cdxml',
        'Volume.cdxml',
        'StorageScripts.psm1'
        )
    AliasesToExport = @(
        'Disable-PhysicalDiskIndication',
        'Disable-StorageDiagnosticLog',
        'Enable-PhysicalDiskIndication',
        'Enable-StorageDiagnosticLog',
        'Flush-Volume',
        'Initialize-Volume',
        'Write-FileSystemCache',
        'Get-PhysicalDiskSNV',
        'Get-DiskSNV',
        'Get-StorageEnclosureSNV'
        )
    CmdletsToExport = @()
    FunctionsToExport = @(
        'Add-InitiatorIdToMaskingSet',
        'Add-PartitionAccessPath',
        'Add-PhysicalDisk',
        'Add-StorageFaultDomain',
        'Add-TargetPortToMaskingSet',
        'Add-VirtualDiskToMaskingSet',
        'Block-FileShareAccess',
        'Clear-Disk',
        'Clear-FileStorageTier',
        'Clear-StorageDiagnosticInfo',
        'Connect-VirtualDisk',
        'Debug-FileShare',
        'Debug-StorageSubSystem',
        'Debug-Volume',
        'Disable-PhysicalDiskIdentification',
        'Disable-StorageEnclosureIdentification',
        'Disable-StorageEnclosurePower',
        'Disable-StorageHighAvailability',
        'Disable-StorageMaintenanceMode',
        'Disconnect-VirtualDisk',
        'Dismount-DiskImage',
        'Enable-PhysicalDiskIdentification',
        'Enable-StorageEnclosureIdentification',
        'Enable-StorageEnclosurePower',
        'Enable-StorageHighAvailability',
        'Enable-StorageMaintenanceMode',
        'Format-Volume',
        'Get-DedupProperties',
        'Get-Disk',
        'Get-DiskImage',
        'Get-DiskStorageNodeView',
        'Get-FileIntegrity',
        'Get-FileStorageTier',
        'Get-StorageFileServer',
        'Get-FileShare',
        'Get-FileShareAccessControlEntry',
        'Get-InitiatorId',
        'Get-InitiatorPort',
        'Get-MaskingSet',
        'Get-Partition',
        'Get-PartitionSupportedSize',
        'Get-PhysicalDisk',
        'Get-PhysicalDiskStorageNodeView',
        'Get-PhysicalExtent',
        'Get-PhysicalExtentAssociation',
        'Get-ResiliencySetting',
        'Get-StorageAdvancedProperty',
        'Get-StorageExtendedStatus',
        'Get-StorageDiagnosticInfo',
        'Get-StorageEnclosure',
        'Get-StorageEnclosureStorageNodeView',
        'Get-StorageEnclosureVendorData',
        'Get-StorageFaultDomain',
        'Get-StorageFirmwareInformation',
        'Get-StorageHealthAction',
        'Get-StorageHealthReport',
        'Get-StorageHealthSetting',
        'Get-StorageJob',
        'Get-StorageNode',
        'Get-StoragePool',
        'Get-StorageProvider',
        'Get-StorageReliabilityCounter',
        'Get-StorageSetting',
        'Get-StorageSubSystem',
        'Get-StorageTier',
        'Get-StorageTierSupportedSize',
        'Get-SupportedFileSystems',
        'Get-SupportedClusterSizes',
        'Get-TargetPort',
        'Get-TargetPortal',
        'Get-VirtualDisk',
        'Get-VirtualDiskSupportedSize',
        'Get-OffloadDataTransferSetting'
        'Get-Volume',
        'Get-VolumeCorruptionCount',
        'Get-VolumeScrubPolicy',
        'Grant-FileShareAccess',
        'Hide-VirtualDisk',
        'Initialize-Disk',
        'Mount-DiskImage',
        'New-MaskingSet',
        'New-Partition',
        'New-StorageFileServer',
        'New-FileShare',
        'New-StoragePool',
        'New-StorageSubsystemVirtualDisk',
        'New-StorageTier',
        'New-VirtualDisk',
        'New-VirtualDiskClone',
        'New-VirtualDiskSnapshot',
        'New-Volume',
        'Optimize-Volume',
        'Optimize-StoragePool'
        'Register-StorageSubsystem',
        'Remove-FileShare',
        'Remove-InitiatorId',
        'Remove-InitiatorIdFromMaskingSet',
        'Remove-MaskingSet',
        'Remove-Partition',
        'Remove-PartitionAccessPath',
        'Remove-PhysicalDisk',
        'Remove-StorageFaultDomain',
        'Remove-StorageFileServer',
        'Remove-StorageHealthIntent',
        'Remove-StorageHealthSetting',
        'Remove-StoragePool',
        'Remove-StorageTier',
        'Remove-TargetPortFromMaskingSet',
        'Remove-VirtualDisk',
        'Remove-VirtualDiskFromMaskingSet',
        'Rename-MaskingSet',
        'Repair-FileIntegrity',
        'Repair-VirtualDisk',
        'Repair-Volume',
        'Reset-PhysicalDisk',
        'Reset-StorageReliabilityCounter',
        'Resize-Partition',
        'Resize-StorageTier',
        'Resize-VirtualDisk',
        'Revoke-FileShareAccess',
        'Set-Disk',
        'Set-FileIntegrity',
        'Set-FileStorageTier',
        'Set-FileShare',
        'Set-InitiatorPort',
        'Set-Partition',
        'Set-PhysicalDisk',
        'Set-ResiliencySetting',
        'Set-StorageFileServer',
        'Set-StorageHealthSetting',
        'Set-StoragePool',
        'Set-StorageProvider',
        'Set-StorageSetting',
        'Set-StorageSubSystem',
        'Set-StorageTier',
        'Set-VirtualDisk',
        'Set-Volume',
        'Set-VolumeScrubPolicy',
        'Show-VirtualDisk',
        'Start-StorageDiagnosticLog',
        'Stop-StorageDiagnosticLog',
        'Stop-StorageJob',
        'Unregister-StorageSubsystem',
        'Unblock-FileShareAccess',
        'Update-Disk',
        'Update-HostStorageCache',
        'Update-StorageFirmware',
        'Update-StoragePool',
        'Update-StorageProviderCache',
        'Write-VolumeCache')
    HelpInfoUri = "https://go.microsoft.com/fwlink/?linkid=390832"
}


