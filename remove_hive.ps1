# Remove Hive annotations from all models

$files = @(
    'lib\features\auth\data\models\user_model.dart',
    'lib\features\customer\data\models\customer_model.dart',
    'lib\features\document\data\models\document_item_model.dart',
    'lib\features\document\data\models\document_model.dart',
    'lib\core\utils\init_default_admin.dart',
    'lib\core\utils\database_migration_v2.dart'
)

foreach ($file in $files) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        
        # Remove imports
        $content = $content -replace "import 'package:hive/hive.dart';\r?\n", ""
        $content = $content -replace "import '\.\./constants/hive_boxes\.dart';\r?\n", ""
        $content = $content -replace "part '.+\.g\.dart';\r?\n", ""
        
        # Remove annotations
        $content = $content -replace "@HiveType\(typeId: \d+\)( // .+)?\r?\n", ""
        $content = $content -replace "\s*@HiveField\(\d+\)\r?\n", "`n"
        
        Set-Content $fullPath $content -NoNewline
        Write-Host "✅ Updated: $file"
    }
}

Write-Host "`n🎉 Done! Hive removed from all models."
