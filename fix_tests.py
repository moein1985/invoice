#!/usr/bin/env python3
"""Fix test files to use UserRole enum instead of string"""

import os
import re

def fix_file(filepath):
    """Fix a single test file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Check if UserRole import is needed
    if "role: 'user'" in content or 'role: "user"' in content:
        # Add import if not present
        if 'import' in content and 'user_role.dart' not in content:
            # Find the last import line
            import_pattern = r'(import.*?;)'
            imports = list(re.finditer(import_pattern, content))
            if imports:
                last_import = imports[-1]
                insert_pos = last_import.end()
                content = (content[:insert_pos] + 
                          "\nimport 'package:invoice/core/enums/user_role.dart';" +
                          content[insert_pos:])
    
    # Fix UserEntity constructors: role: 'user' -> role: UserRole.employee
    content = re.sub(
        r"UserEntity\([^)]*role: '(user|employee|supervisor|manager|admin)'",
        lambda m: m.group(0).replace(f"role: '{m.group(1)}'", f"role: UserRole.{m.group(1) if m.group(1) != 'user' else 'employee'}"),
        content
    )
    
    # Fix createUser calls and UserModel: role: 'user' -> role: 'employee'
    content = re.sub(
        r"(createUser|UserModel)\([^)]*role: '(user|employee|supervisor|manager|admin)'",
        lambda m: m.group(0).replace(f"role: '{m.group(2)}'", f"role: '{m.group(2) if m.group(2) != 'user' else 'employee'}'"),
        content
    )
    
    # Special case: CreateUser event
    content = re.sub(
        r"CreateUser\([^)]*role: '(user|employee|supervisor|manager|admin)'",
        lambda m: m.group(0).replace(f"role: '{m.group(1)}'", f"role: '{m.group(1) if m.group(1) != 'user' else 'employee'}'"),
        content
    )
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Fixed: {filepath}")
        return True
    return False

def main():
    """Fix all test files"""
    test_files = [
        'test/features/user_management/user_bloc_test.dart',
        'test/widgets/login_page_widget_test.dart',
        'test/widgets/dashboard_page_widget_test.dart',
        'test/features/auth/user_model_test.dart',
        'test/features/auth/auth_repository_impl_test.dart',
        'test/features/auth/auth_local_datasource_test.dart',
        'test/features/user_management/user_local_datasource_test.dart',
        'test/features/user_management/user_repository_impl_test.dart',
    ]
    
    fixed_count = 0
    for filepath in test_files:
        if os.path.exists(filepath):
            if fix_file(filepath):
                fixed_count += 1
        else:
            print(f"⚠️  Not found: {filepath}")
    
    print(f"\n✨ Fixed {fixed_count} files")

if __name__ == '__main__':
    main()
