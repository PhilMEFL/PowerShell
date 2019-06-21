Get-MailboxStatistics -Server 'seuscexc03.shurgard.intl' | Where {$_.ObjectClass -eq 'Mailbox'} | 
Select-Object -Property @{label='User';expression={$_.DisplayName}},
@{label='Total Messages';expression= {$_.ItemCount}},
@{label='Total Size (MB)';expression={$_.TotalItemSize.Value.ToMB()}}, TotalItemSize, LastLogonTime, StorageLimitStatus | sort  StorageLimitStatus -Descending | ft