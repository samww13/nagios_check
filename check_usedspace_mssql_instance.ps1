[CmdletBinding()]

param (
    [Parameter()]
    [String]
    $ServerInstance = 'W-IZVPP-1\IZVPP',
    [Parameter()]
    [String]
    $Database = 'Master'
)

    $returnStateOK = 0
    $returnStateWarning = 1
    $returnStateCritical = 2


$Query = 'With theInfo as (
SELECT
  [Dbase] = db_name(f.database_id)
, [ServerName]=CONVERT(VARCHAR(128),SERVERPROPERTY(''machinename'') )
, [File] = f.name
, [MountPoint] = vs.volume_mount_point
, [Volume] = vs.logical_volume_name
, [SizeGB] = vs.total_bytes / 1024 / (1024 * 1024)
, [FreeGB] = vs.available_bytes / 1024/ (1024 * 1024)
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) as vs
)
Select
  ServerName,
   MAX( ceiling (100 - round ( cast (ti.[FreeGB] as decimal ) / cast (ti.[SizeGB] as decimal) *100 ,2)))
From
	theInfo as ti
Group By
  ti.ServerName'


$sqlreturn = sqlcmd.exe -U Nagios1 -P NagGEPEL4 -S $ServerInstance -d $Database -Q $Query -h-1 -W -s ";" 
$resultsql= ($sqlreturn.Split([Environment]::NewLine) | Select -First 1).split(";")[1]

if ($resultsql -ge 90) {
    $ResultString = "Critical - Espace disque instance $ServerInstance est : $($resultsql) %"
    $ExitCode = $returnStateCritical
    }

elseif (($resultsql -ge 80) -And ($resultsql -lt 90)) {
    $ResultString = "Warning - Espace disque instance $ServerInstance est : $($resultsql) %"
    $ExitCode = $returnStateWarning
    }
    
else {
    $ResultString = "OK - Espace disque instance $ServerInstance est : $resultsql %"
    $ExitCode = $returnStateOK
    }

    #write-host $ResultString 
    return $ResultString
