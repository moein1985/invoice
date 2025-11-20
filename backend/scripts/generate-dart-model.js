const fs = require('fs').promises;
const path = require('path');

async function generateDartModel(tableName) {
  try {
    if (!tableName) {
      console.error('❌ Please provide a table name');
      console.log('Usage: node scripts/generate-dart-model.js <table_name>');
      process.exit(1);
    }

    console.log(`🚀 Generating Dart model for table: ${tableName}...`);

    // Read schema
    const schemaPath = path.join(__dirname, '..', 'docs', 'database-schema.json');
    const schemaContent = await fs.readFile(schemaPath, 'utf8');
    const schema = JSON.parse(schemaContent);

    if (!schema.tables[tableName]) {
      console.error(`❌ Table '${tableName}' not found in schema`);
      process.exit(1);
    }

    const table = schema.tables[tableName];
    const modelContent = generateModelContent(tableName, table);
    
    // Determine output path (assuming standard structure)
    // lib/features/<feature>/data/models/<model>.dart
    // For now, we'll put it in a 'generated_models' folder in root for the user to move
    const outputDir = path.join(__dirname, '..', '..', 'lib', 'generated_models');
    await fs.mkdir(outputDir, { recursive: true });
    
    const modelName = tableName.endsWith('s') ? tableName.slice(0, -1) : tableName;
    const fileName = `${modelName}_model.dart`;
    const outputPath = path.join(outputDir, fileName);
    
    await fs.writeFile(outputPath, modelContent);

    console.log(`✅ Dart model generated: lib/generated_models/${fileName}`);

  } catch (error) {
    console.error('❌ Error generating Dart model:', error.message);
    process.exit(1);
  }
}

function generateModelContent(tableName, table) {
  const className = toPascalCase(tableName.endsWith('s') ? tableName.slice(0, -1) : tableName) + 'Model';
  const columns = table.columns;

  // Fields
  const fields = columns.map(c => {
    const type = mysqlTypeToDartType(c.fullType);
    const name = toCamelCase(c.name);
    const nullable = c.nullable ? '?' : '';
    return `  final ${type}${nullable} ${name};`;
  }).join('\n');

  // Constructor
  const constructorParams = columns.map(c => {
    const name = toCamelCase(c.name);
    const required = !c.nullable ? 'required ' : '';
    return `    ${required}this.${name},`;
  }).join('\n');

  // fromJson
  const fromJsonBody = columns.map(c => {
    const name = toCamelCase(c.name);
    const jsonKey = name; // Assuming API returns camelCase
    const type = mysqlTypeToDartType(c.fullType);
    
    let parsingLogic = `json['${jsonKey}']`;
    
    if (type === 'bool') {
      parsingLogic = `_parseBool(json['${jsonKey}'])`;
    } else if (type === 'double') {
      parsingLogic = `_parseDouble(json['${jsonKey}'])`;
    } else if (type === 'DateTime') {
      parsingLogic = `json['${jsonKey}'] != null ? DateTime.parse(json['${jsonKey}']) : null`;
      if (!c.nullable) parsingLogic += ' ?? DateTime.now()';
    } else if (type === 'int') {
       parsingLogic = `json['${jsonKey}'] as int${c.nullable ? '?' : ''}`;
    }

    return `      ${name}: ${parsingLogic},`;
  }).join('\n');

  // toJson
  const toJsonBody = columns.map(c => {
    const name = toCamelCase(c.name);
    let value = name;
    const type = mysqlTypeToDartType(c.fullType);

    if (type === 'DateTime') {
      value = `${name}${c.nullable ? '?' : ''}.toIso8601String()`;
    }

    return `      '${name}': ${value},`;
  }).join('\n');

  // copyWith
  const copyWithParams = columns.map(c => {
    const type = mysqlTypeToDartType(c.fullType);
    const name = toCamelCase(c.name);
    return `    ${type}? ${name},`;
  }).join('\n');

  const copyWithBody = columns.map(c => {
    const name = toCamelCase(c.name);
    return `      ${name}: ${name} ?? this.${name},`;
  }).join('\n');

  // Props
  const props = columns.map(c => toCamelCase(c.name)).join(', ');

  return `import 'package:equatable/equatable.dart';

class ${className} extends Equatable {
${fields}

  const ${className}({
${constructorParams}
  });

  factory ${className}.fromJson(Map<String, dynamic> json) {
    return ${className}(
${fromJsonBody}
    );
  }

  Map<String, dynamic> toJson() {
    return {
${toJsonBody}
    };
  }

  ${className} copyWith({
${copyWithParams}
  }) {
    return ${className}(
${copyWithBody}
    );
  }

  @override
  List<Object?> get props => [${props}];

  // Helper methods for type conversion
  static bool${columns.some(c => c.nullable && mysqlTypeToDartType(c.fullType) === 'bool') ? '?' : ''} _parseBool(dynamic value) {
    if (value == null) return ${columns.some(c => c.nullable && mysqlTypeToDartType(c.fullType) === 'bool') ? 'null' : 'false'};
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static double${columns.some(c => c.nullable && mysqlTypeToDartType(c.fullType) === 'double') ? '?' : ''} _parseDouble(dynamic value) {
    if (value == null) return ${columns.some(c => c.nullable && mysqlTypeToDartType(c.fullType) === 'double') ? 'null' : '0.0'};
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
`;
}

function toCamelCase(str) {
  return str.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
}

function toPascalCase(str) {
  const camel = toCamelCase(str);
  return camel.charAt(0).toUpperCase() + camel.slice(1);
}

function mysqlTypeToDartType(mysqlType) {
  const type = mysqlType.toLowerCase();
  if (type.includes('tinyint(1)')) return 'bool';
  if (type.includes('int')) return 'int';
  if (type.includes('decimal') || type.includes('double') || type.includes('float')) return 'double';
  if (type.includes('datetime') || type.includes('timestamp') || type.includes('date')) return 'DateTime';
  return 'String';
}

// Run if called directly
if (require.main === module) {
  const tableName = process.argv[2];
  generateDartModel(tableName);
}

module.exports = generateDartModel;
