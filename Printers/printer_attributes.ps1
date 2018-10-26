$attributes = @{1 = 'Queued';
			    2 = 'Direct';
			    4 = 'Default';
			    8 = 'Shared';
			   16 = 'Network';
			   32 = 'Hidden';
			   64 = 'Local';
			  128 = 'EnableVQ';
			  256 = 'KeepPrintedJobs';
			  512 = 'DoCompleteFirst';
			 1024 = 'Work Offline';
			 2048 = 'Enable BiDi';
			 4096 = 'Raw Only';
			 8192 = 'Published'}
$value = 14400
$attributes.Keys | where { $_ -band $value } | foreach { $attributes.Get_Item($_) } 
$value = $value -bxor 8192
$attributes.Keys | where { $_ -band $value } | foreach { $attributes.Get_Item($_) } 
$value
