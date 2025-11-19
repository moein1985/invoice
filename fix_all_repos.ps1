# Fix all repositories - remove all localDataSource references and use only remote

$repos = @{
    'lib\features\customer\data\repositories\customer_repository_impl.dart' = 'CustomerRemoteDataSource'
    'lib\features\dashboard\data\repositories\dashboard_repository_impl.dart' = 'DashboardLocalDataSource'
    'lib\features\document\data\repositories\document_repository_impl.dart' = 'DocumentRemoteDataSource'
    'lib\features\user_management\data\repositories\user_repository_impl.dart' = 'UserRemoteDataSource'
}

foreach ($repo in $repos.Keys) {
    $fullPath = Join-Path $PSScriptRoot $repo
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        
        # Replace all localDataSource calls with remoteDataSource
        $content = $content -replace '\blocalDataSource\.', 'remoteDataSource.'
        
        # Remove localDataSource field declaration
        $content = $content -replace 'final\s+\w+LocalDataSource\s+localDataSource;\s*', ''
        
        # Fix constructor - remove localDataSource parameter
        $content = $content -replace 'required\s+this\.localDataSource,?\s*', ''
        
        # Remove try-catch fallback to localDataSource (keep only remote)
        # This is complex - we'll do it manually per file if needed
        
        Set-Content $fullPath $content -NoNewline
        Write-Host "✅ Fixed: $repo"
    }
}

# Fix DashboardRepository specifically (it only has localDataSource, no remote!)
$dashboardPath = Join-Path $PSScriptRoot 'lib\features\dashboard\data\repositories\dashboard_repository_impl.dart'
if (Test-Path $dashboardPath) {
    $content = Get-Content $dashboardPath -Raw
    
    # For Dashboard, we need to remove getDashboardData since there's no remote version
    # Let's make it return empty data for now
    $content = $content -replace 'final dashboardData = await remoteDataSource\.getDashboardData\(userId\);', 'final dashboardData = null; // TODO: Implement remote dashboard API'
    
    Set-Content $dashboardPath $content -NoNewline
    Write-Host "⚠️  Dashboard needs manual API implementation"
}

Write-Host "`n✅ All repositories updated to use remote only!"
Write-Host "⚠️  Note: Dashboard may need additional work"
