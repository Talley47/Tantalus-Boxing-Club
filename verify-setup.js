const fs = require('fs');
const path = require('path');

console.log('🔍 Tantalus Boxing Club - Setup Verification\n');

// Check for .env.local file
const envLocalPath = path.join(__dirname, '.env.local');
if (fs.existsSync(envLocalPath)) {
  console.log('✓ .env.local file exists');
  
  // Read and validate
  const envContent = fs.readFileSync(envLocalPath, 'utf8');
  
  if (envContent.includes('YOUR_SUPABASE_URL_HERE') || envContent.includes('YOUR_ANON_KEY_HERE')) {
    console.log('❌ ERROR: .env.local contains placeholder values');
    console.log('   Please update .env.local with your actual Supabase credentials');
    console.log('   Get them from: https://supabase.com/dashboard → Your Project → Settings → API\n');
  } else if (envContent.includes('REACT_APP_SUPABASE_URL=') && envContent.includes('REACT_APP_SUPABASE_ANON_KEY=')) {
    console.log('✓ .env.local appears to be configured\n');
  } else {
    console.log('❌ ERROR: .env.local is missing required variables');
    console.log('   Required: REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY\n');
  }
} else {
  console.log('❌ ERROR: .env.local file not found');
  console.log('   Create it by copying env.example:');
  console.log('   1. Copy env.example to .env.local');
  console.log('   2. Update with your Supabase credentials\n');
}

// Check for node_modules
const nodeModulesPath = path.join(__dirname, 'node_modules');
if (fs.existsSync(nodeModulesPath)) {
  console.log('✓ node_modules exists');
} else {
  console.log('❌ ERROR: node_modules not found');
  console.log('   Run: npm install\n');
}

// Check for create-admin.js
const createAdminPath = path.join(__dirname, 'create-admin.js');
if (fs.existsSync(createAdminPath)) {
  console.log('✓ create-admin.js script exists');
} else {
  console.log('⚠ WARNING: create-admin.js not found');
  console.log('   You may need to create the admin account manually\n');
}

// Check for database schema
const schemaPath = path.join(__dirname, 'database', 'schema-fixed.sql');
if (fs.existsSync(schemaPath)) {
  console.log('✓ Database schema file exists');
} else {
  console.log('⚠ WARNING: database/schema-fixed.sql not found');
  console.log('   You may need to create the database schema manually\n');
}

console.log('\n📋 Next Steps:');
console.log('1. If .env.local needs configuration, update it with your Supabase credentials');
console.log('2. Run the database schema in Supabase SQL Editor');
console.log('3. Run: node create-admin.js');
console.log('4. Run: npm start');
console.log('5. Test login with admin@tantalusboxing.com / TantalusAdmin2025!');
console.log('6. Test registration flow with a new account\n');
