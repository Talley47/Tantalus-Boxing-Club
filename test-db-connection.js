const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials in .env.local');
    console.log('Please check your .env.local file contains:');
    console.log('REACT_APP_SUPABASE_URL=your_url');
    console.log('REACT_APP_SUPABASE_ANON_KEY=your_key');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
    console.log('🔍 Testing Supabase connection...');
    
    try {
        // Test basic connection
        const { data, error } = await supabase
            .from('tiers')
            .select('*')
            .limit(1);
            
        if (error) {
            console.error('❌ Connection failed:', error.message);
            return;
        }
        
        console.log('✅ Connection successful!');
        
        // Test if tables exist
        const tables = [
            'tiers',
            'fighter_profiles', 
            'fight_records',
            'rankings',
            'tournaments',
            'notifications',
            'system_settings'
        ];
        
        console.log('\n🔍 Checking table existence...');
        for (const table of tables) {
            try {
                const { error } = await supabase
                    .from(table)
                    .select('*')
                    .limit(1);
                    
                if (error) {
                    console.log(`❌ Table ${table}: ${error.message}`);
                } else {
                    console.log(`✅ Table ${table}: exists`);
                }
            } catch (err) {
                console.log(`❌ Table ${table}: ${err.message}`);
            }
        }
        
        // Test admin user
        console.log('\n🔍 Checking admin user...');
        const { data: adminData, error: adminError } = await supabase
            .from('fighter_profiles')
            .select('*')
            .eq('handle', 'admin')
            .single();
            
        if (adminError) {
            console.log('❌ Admin user not found:', adminError.message);
        } else {
            console.log('✅ Admin user found:', adminData.name);
        }
        
        console.log('\n🎉 Database setup verification complete!');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

testConnection();
