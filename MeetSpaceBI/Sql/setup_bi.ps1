$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sqlFiles = @(
    @{ Source = Join-Path $PSScriptRoot '01_create_bi_database.sql'; Target = '/tmp/meetspace-bi-01_create_bi_database.sql' },
    @{ Source = Join-Path $PSScriptRoot '02_load_staging_data.sql'; Target = '/tmp/meetspace-bi-02_load_staging_data.sql' },
    @{ Source = Join-Path $PSScriptRoot '03_build_bi_model.sql'; Target = '/tmp/meetspace-bi-03_build_bi_model.sql' },
    @{ Source = Join-Path $PSScriptRoot '06_sync_space_capacities.sql'; Target = '/tmp/meetspace-bi-06_sync_space_capacities.sql' }
)
$stateSqlPath = Join-Path $PSScriptRoot '00_get_bi_state.sql'
$stateSqlTarget = '/tmp/meetspace-bi-00_get_bi_state.sql'

function Invoke-DockerCompose([string[]] $Arguments) {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & docker compose --project-directory $repoRoot @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        $details = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "Docker Compose command failed with exit code $exitCode.`n$details"
    }

    return @($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] })
}

function Get-BiState {
    $command = '/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -h -1 -W -i ' + $stateSqlTarget
    $result = Invoke-DockerCompose @('exec', '-T', 'sqlserver', '/bin/bash', '-lc', $command)
    return (($result -join '').Trim())
}

Invoke-DockerCompose @('cp', $stateSqlPath, "sqlserver:$stateSqlTarget") | Out-Null
$state = Get-BiState
if ($state -eq 'READY') {
    $capacityFile = $sqlFiles[-1]
    Invoke-DockerCompose @('cp', $capacityFile.Source, "sqlserver:$($capacityFile.Target)") | Out-Null
    $command = '/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -i ' + $capacityFile.Target
    Invoke-DockerCompose @('exec', '-T', 'sqlserver', '/bin/bash', '-lc', $command) | Out-Host
    Write-Host 'MeetSpaceBI is set up with 5,000 reservations and 12,145 hourly fact rows. Space capacities were synchronized; reservation data was not changed.'
    exit 0
}
if ($state -ne 'EMPTY') {
    throw "MeetSpaceBI is in a partial or unexpected state ('$state'). Nothing was changed. Do not reset the Docker volume; inspect the BI tables before proceeding."
}

foreach ($file in $sqlFiles) {
    Invoke-DockerCompose @('cp', $file.Source, "sqlserver:$($file.Target)") | Out-Null
}

foreach ($file in $sqlFiles) {
    $command = '/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -i ' + $file.Target
    Invoke-DockerCompose @('exec', '-T', 'sqlserver', '/bin/bash', '-lc', $command) | Out-Host
}

if ((Get-BiState) -ne 'READY') {
    throw 'BI setup finished without the expected table counts. Stop here and inspect the SQL output; do not rerun the individual scripts.'
}

Write-Host 'MeetSpaceBI setup completed: 37 spaces, 365 dates, 24 hours, 4 statuses and 12,145 hourly fact rows. Simulated capacities were synchronized.'
