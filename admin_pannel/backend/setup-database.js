/**
 * Database setup script with PostgreSQL 15+ permissions fix
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const POSTGRES_PASSWORD = process.argv[2] || 'postgres';

async function setupDatabase() {
    console.log('🔧 Setting up Community Safety Platform database...\n');

    // Step 1: Connect to postgres database to create our database
    console.log('📦 Step 1: Creating database and user...');
    const adminClient = new Client({
        host: 'localhost',
        port: 5432,
        database: 'postgres',
        user: 'postgres',
        password: POSTGRES_PASSWORD,
    });

    try {
        await adminClient.connect();

        // Create database
        try {
            await adminClient.query('CREATE DATABASE sos_platform');
            console.log('   ✅ Database "sos_platform" created');
        } catch (err) {
            if (err.code === '42P04') {
                console.log('   ⚠️  Database "sos_platform" already exists');
            } else {
                throw err;
            }
        }

        // Create user
        try {
            await adminClient.query("CREATE USER sos_user WITH PASSWORD 'sos_password'");
            console.log('   ✅ User "sos_user" created');
        } catch (err) {
            if (err.code === '42710') {
                console.log('   ⚠️  User "sos_user" already exists');
            } else {
                throw err;
            }
        }

        // Grant database privileges
        await adminClient.query('GRANT ALL PRIVILEGES ON DATABASE sos_platform TO sos_user');
        console.log('   ✅ Database privileges granted');

        await adminClient.end();

        // Step 1.5: Grant schema permissions (PostgreSQL 15+ requirement)
        console.log('   🔐 Granting schema permissions...');
        const dbAdminClient = new Client({
            host: 'localhost',
            port: 5432,
            database: 'sos_platform',
            user: 'postgres',
            password: POSTGRES_PASSWORD,
        });

        await dbAdminClient.connect();
        await dbAdminClient.query('GRANT ALL ON SCHEMA public TO sos_user');
        await dbAdminClient.query('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sos_user');
        await dbAdminClient.query('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sos_user');
        await dbAdminClient.query('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO sos_user');
        await dbAdminClient.query('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO sos_user');
        console.log('   ✅ Schema permissions granted\n');
        await dbAdminClient.end();

        // Step 2: Run migrations
        console.log('📋 Step 2: Running migrations...');
        const appClient = new Client({
            host: 'localhost',
            port: 5432,
            database: 'sos_platform',
            user: 'sos_user',
            password: 'sos_password',
        });

        await appClient.connect();

        // Run schema migration
        const schemaPath = path.join(__dirname, 'migrations', '001_create_schema.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');
        await appClient.query(schemaSql);
        console.log('   ✅ Schema created (users, sos_events, audit_logs)');

        // Ensure latest schema additions (safe no-op if already present)
        await appClient.query('ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS external_id TEXT UNIQUE');
        await appClient.query(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_external_id ON users(external_id) WHERE external_id IS NOT NULL'
        );
        console.log('   ✅ external_id column verified on users table');

        // Run seed data
        const seedPath = path.join(__dirname, 'migrations', 'seed.sql');
        const seedSql = fs.readFileSync(seedPath, 'utf8');
        await appClient.query(seedSql);
        console.log('   ✅ Sample data seeded (2 admins, 3 users, 3 SOS events)\n');

        await appClient.end();

        // Step 3: Create .env file if it doesn't exist
        console.log('📝 Step 3: Setting up environment...');
        const envPath = path.join(__dirname, '.env');
        if (!fs.existsSync(envPath)) {
            const envContent = `DATABASE_URL=postgresql://sos_user:sos_password@localhost:5432/sos_platform
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
PORT=5000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
INTEGRATION_KEY=change-me-to-a-secure-random-string
EXTERNAL_USER_PASSWORD=external-sync-placeholder
DISABLE_ADMIN_AUTH=true
`;
            fs.writeFileSync(envPath, envContent);
            console.log('   ✅ Created .env file\n');
        } else {
            console.log('   ⚠️  .env file already exists\n');
        }

        console.log('✅ Database setup complete!\n');
        console.log('Next steps:');
        console.log('1. Start backend:  npm run dev');
        console.log('2. Start frontend: cd ../frontend && npm install && npm run dev');
        console.log('3. Open browser:   http://localhost:3000');
        console.log('4. Login with:     admin@safety.com / password123\n');

    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error('\nTroubleshooting:');
        console.error('- Make sure PostgreSQL is installed and running');
        console.error('- Check that you provided the correct postgres password');
        console.error('- Try: node setup-database.js <your-postgres-password>');
        process.exit(1);
    }
}

setupDatabase();
