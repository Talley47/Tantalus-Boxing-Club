#!/usr/bin/env node

/**
 * Security Audit Script
 * Checks for common security issues before deployment
 */

const fs = require('fs');
const path = require('path');

const checks = {
  envFile: {
    name: 'Environment Variables',
    check: () => {
      const envPath = path.join(process.cwd(), '.env.local');
      if (!fs.existsSync(envPath)) {
        return { passed: false, message: '❌ .env.local file not found' };
      }
      
      const envContent = fs.readFileSync(envPath, 'utf8');
      if (!envContent.includes('REACT_APP_SUPABASE_URL')) {
        return { passed: false, message: '❌ REACT_APP_SUPABASE_URL not found in .env.local' };
      }
      if (!envContent.includes('REACT_APP_SUPABASE_ANON_KEY')) {
        return { passed: false, message: '❌ REACT_APP_SUPABASE_ANON_KEY not found in .env.local' };
      }
      
      return { passed: true, message: '✅ Environment variables configured' };
    }
  },
  
  gitignore: {
    name: 'Git Ignore',
    check: () => {
      const gitignorePath = path.join(process.cwd(), '.gitignore');
      if (!fs.existsSync(gitignorePath)) {
        return { passed: false, message: '❌ .gitignore file not found' };
      }
      
      const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
      if (!gitignoreContent.includes('.env.local')) {
        return { passed: false, message: '❌ .env.local not in .gitignore' };
      }
      
      return { passed: true, message: '✅ .gitignore configured correctly' };
    }
  },
  
  securityHeaders: {
    name: 'Security Headers',
    check: () => {
      const headersPath = path.join(process.cwd(), 'public', '_headers');
      const vercelPath = path.join(process.cwd(), 'vercel.json');
      
      if (fs.existsSync(headersPath)) {
        return { passed: true, message: '✅ Security headers file (_headers) found' };
      }
      if (fs.existsSync(vercelPath)) {
        const vercelContent = fs.readFileSync(vercelPath, 'utf8');
        if (vercelContent.includes('X-Frame-Options')) {
          return { passed: true, message: '✅ Security headers configured in vercel.json' };
        }
      }
      
      return { passed: false, message: '⚠️  Security headers not configured' };
    }
  },
  
  hardcodedKeys: {
    name: 'Hardcoded API Keys',
    check: () => {
      const supabasePath = path.join(process.cwd(), 'src', 'services', 'supabase.ts');
      if (!fs.existsSync(supabasePath)) {
        return { passed: false, message: '❌ supabase.ts not found' };
      }
      
      const content = fs.readFileSync(supabasePath, 'utf8');
      // Check for hardcoded Supabase URLs/keys
      if (content.includes('https://andmtvsqqomgwphotdwf.supabase.co') && 
          !content.includes('process.env.REACT_APP_SUPABASE_URL')) {
        return { passed: false, message: '⚠️  Hardcoded Supabase URL found' };
      }
      if (content.includes('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9') && 
          !content.includes('process.env.REACT_APP_SUPABASE_ANON_KEY')) {
        return { passed: false, message: '⚠️  Hardcoded API key found' };
      }
      
      return { passed: true, message: '✅ No hardcoded keys detected' };
    }
  },
  
  securityUtils: {
    name: 'Security Utilities',
    check: () => {
      const utilsPath = path.join(process.cwd(), 'src', 'utils', 'securityUtils.ts');
      if (!fs.existsSync(utilsPath)) {
        return { passed: false, message: '❌ securityUtils.ts not found' };
      }
      return { passed: true, message: '✅ Security utilities exist' };
    }
  },
  
  packageAudit: {
    name: 'Dependencies',
    check: () => {
      const packagePath = path.join(process.cwd(), 'package.json');
      if (!fs.existsSync(packagePath)) {
        return { passed: false, message: '❌ package.json not found' };
      }
      
      const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
      const hasDompurify = packageJson.dependencies?.dompurify || packageJson.devDependencies?.dompurify;
      const hasValidator = packageJson.dependencies?.validator || packageJson.devDependencies?.validator;
      
      if (!hasDompurify) {
        return { passed: false, message: '⚠️  dompurify not installed' };
      }
      if (!hasValidator) {
        return { passed: false, message: '⚠️  validator not installed' };
      }
      
      return { passed: true, message: '✅ Security packages installed' };
    }
  }
};

console.log('🔒 Security Audit Report\n');
console.log('='.repeat(50));

let passed = 0;
let failed = 0;

for (const [key, check] of Object.entries(checks)) {
  try {
    const result = check.check();
    console.log(`\n${check.name}:`);
    console.log(`  ${result.message}`);
    
    if (result.passed) {
      passed++;
    } else {
      failed++;
    }
  } catch (error) {
    console.log(`\n${check.name}:`);
    console.log(`  ❌ Error: ${error.message}`);
    failed++;
  }
}

console.log('\n' + '='.repeat(50));
console.log(`\nSummary: ${passed} passed, ${failed} failed`);

if (failed === 0) {
  console.log('\n✅ All security checks passed!');
  process.exit(0);
} else {
  console.log('\n⚠️  Some security checks failed. Please review the issues above.');
  console.log('\nSee PRE_PRODUCTION_SECURITY_GUIDE.md for detailed instructions.');
  process.exit(1);
}

