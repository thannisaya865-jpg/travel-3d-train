$OWNER = "chilrawut20042016-alt"
$REPO  = "travel-map-nara"
$BRANCH = "main"

Write-Host "=== GitHub Pages Uploader ===" -ForegroundColor Cyan
Write-Host "Repo: https://github.com/$OWNER/$REPO" -ForegroundColor Gray

$TOKEN = Read-Host "Enter GitHub Personal Access Token"
if (-not $TOKEN) { Write-Host "Cancelled: no token." -ForegroundColor Red; exit 1 }

$HEADERS = @{
    "Authorization" = "Bearer $TOKEN"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function Upload-File($localPath, $repoPath, $msg) {
    Write-Host "Uploading $repoPath ..." -ForegroundColor Yellow
    $bytes = [System.IO.File]::ReadAllBytes($localPath)
    $b64 = [Convert]::ToBase64String($bytes)
    $url = "https://api.github.com/repos/$OWNER/$REPO/contents/$repoPath"
    $sha = $null
    try {
        $ex = Invoke-RestMethod -Uri $url -Headers $HEADERS -Method Get -ErrorAction Stop
        $sha = $ex.sha
        Write-Host "  File exists (SHA: $sha) - will update" -ForegroundColor Gray
    } catch {
        Write-Host "  New file - will create" -ForegroundColor Gray
    }
    $body = @{ message = $msg; content = $b64; branch = $BRANCH }
    if ($sha) { $body.sha = $sha }
    try {
        $r = Invoke-RestMethod -Uri $url -Headers $HEADERS -Method Put `
            -Body ($body | ConvertTo-Json -Depth 5) -ContentType "application/json" -ErrorAction Stop
        Write-Host "  OK! Commit: $($r.commit.sha.Substring(0,7))" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        return $false
    }
}

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ok1 = Upload-File "$dir\index.html"    "index.html"    "Update 2D travel map Leaflet"
$ok2 = Upload-File "$dir\travel-3d.html" "travel-3d.html" "Add 3D train animation Three.js"

Write-Host ""
if ($ok1 -and $ok2) {
    Write-Host "Done!" -ForegroundColor Cyan
    Write-Host "2D Map  : https://$OWNER.github.io/$REPO/" -ForegroundColor White
    Write-Host "3D Train: https://$OWNER.github.io/$REPO/travel-3d.html" -ForegroundColor White
    Write-Host "(GitHub Pages may take 1-2 min to update)" -ForegroundColor Gray
} else {
    Write-Host "Some uploads failed." -ForegroundColor Red
}
