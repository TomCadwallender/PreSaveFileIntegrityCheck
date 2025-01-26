$downloadFolder = "C:\Your\Downloads\Folder"
$algorithm = "SHA256"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $downloadFolder
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    
    if ($changeType -eq [System.IO.WatcherChangeTypes]::Created) {
        Write-Host "File $name is being downloaded..."
        
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($algorithm)
        $stream = [System.IO.File]::OpenRead($path)
        
        $buffer = New-Object byte[] 8192
        $hasMoreData = $true
        
        while ($hasMoreData) {
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -eq 0) {
                $hasMoreData = $false
            } else {
                $hashAlgorithm.TransformBlock($buffer, 0, $bytesRead, $null, 0) | Out-Null
            }
        }
        
        $hashAlgorithm.TransformFinalBlock($buffer, 0, 0) | Out-Null
        $hash = [System.BitConverter]::ToString($hashAlgorithm.Hash).Replace("-", "")
        
        Write-Host "File hash ($algorithm) for $name : $hash"
        
        $virusTotalUrl = "https://www.virustotal.com/gui/file/$hash"
        Write-Host "VirusTotal URL: $virusTotalUrl"
        Start-Process $virusTotalUrl
        
        $stream.Close()
        $hashAlgorithm.Dispose()
    }
}

Register-ObjectEvent $watcher "Created" -Action $action

Write-Host "Monitoring downloads folder. Press Ctrl+C to stop."
while ($true) { Start-Sleep 1 }
