# Fix injection_container.dart

$filePath = 'lib\injection_container.dart'
$fullPath = Join-Path $PSScriptRoot $filePath

if (Test-Path $fullPath) {
    $content = Get-Content $fullPath -Raw
    
    # Remove local datasource imports
    $content = $content -replace "import 'features/\w+/data/datasources/\w+_local_datasource\.dart';\r?\n", ""
    
    # Fix repository registrations - remove localDataSource parameter
    $content = $content -replace "DashboardRepositoryImpl\(localDataSource: sl\(\)\)", "DashboardRepositoryImpl()"
    $content = $content -replace "UserRepositoryImpl\(localDataSource: sl\(\), remoteDataSource: sl\(\)\)", "UserRepositoryImpl(remoteDataSource: sl())"
    $content = $content -replace "CustomerRepositoryImpl\(localDataSource: sl\(\), remoteDataSource: sl\(\)\)", "CustomerRepositoryImpl(remoteDataSource: sl())"
    $content = $content -replace "DocumentRepositoryImpl\(localDataSource: sl\(\), remoteDataSource: sl\(\)\)", "DocumentRepositoryImpl(remoteDataSource: sl())"
    
    # Remove all LocalDataSource registrations (multiline pattern)
    $content = $content -replace "(?s)\s*sl\.registerLazySingleton<\w+LocalDataSource>\(\s*\(\) => \w+LocalDataSourceImpl\(\),\s*\);", ""
    
    Set-Content $fullPath $content -NoNewline
    Write-Host "✅ Fixed: $filePath"
}

Write-Host "`n🎉 injection_container.dart fixed!"
