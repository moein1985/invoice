# Fix all repositories to remove localDataSource

$repos = @(
    'lib\features\customer\data\repositories\customer_repository_impl.dart',
    'lib\features\dashboard\data\repositories\dashboard_repository_impl.dart',
    'lib\features\document\data\repositories\document_repository_impl.dart',
    'lib\features\user_management\data\repositories\user_repository_impl.dart'
)

foreach ($repo in $repos) {
    $fullPath = Join-Path $PSScriptRoot $repo
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        
        # Remove local datasource import
        $content = $content -replace "import '\.\./datasources/\w+_local_datasource\.dart';\r?\n", ""
        
        # Remove localDataSource field
        $content = $content -replace "\s*final \w+LocalDataSource localDataSource;\r?\n", ""
        
        # Remove localDataSource from constructor
        $content = $content -replace "required this\.localDataSource,\s*", ""
        $content = $content -replace ",\s*required this\.localDataSource", ""
        $content = $content -replace "localDataSource:\s*sl\(\),\s*", ""
        $content = $content -replace ",\s*localDataSource:\s*sl\(\)", ""
        
        Set-Content $fullPath $content -NoNewline
        Write-Host "✅ Fixed: $repo"
    }
}

Write-Host "`n🎉 All repositories fixed!"
