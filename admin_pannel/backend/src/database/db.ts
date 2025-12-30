import { Pool, PoolClient } from 'pg';

// PostgreSQL connection using DATABASE_URL from environment
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }, // Required for Render PostgreSQL
});

class Database {
  private pool: Pool;

  constructor() {
    this.pool = pool;
    this.pool.on('connect', () => {
      console.log('✅ Connected to PostgreSQL database');
    });
    this.pool.on('error', (err: Error) => {
      console.error('❌ PostgreSQL pool error:', err);
    });
  }

  // Get all users
  async getAllUsers(): Promise<any[]> {
    try {
      const result = await this.pool.query('SELECT * FROM users ORDER BY "createdAt" DESC');
      return result.rows || [];
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  }

  // Get user by ID
  async getUserById(id: string): Promise<any | null> {
    try {
      const result = await this.pool.query('SELECT * FROM users WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error fetching user:', error);
      throw error;
    }
  }

  // Get user by email
  async getUserByEmail(email: string): Promise<any | null> {
    try {
      const result = await this.pool.query('SELECT * FROM users WHERE email = $1', [email]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error fetching user by email:', error);
      throw error;
    }
  }

  // Get all incidents
  async getAllIncidents(): Promise<any[]> {
    try {
      const result = await this.pool.query('SELECT * FROM incidents ORDER BY "createdAt" DESC');
      return result.rows || [];
    } catch (error) {
      console.error('Error fetching incidents:', error);
      throw error;
    }
  }

  // Get incident by ID
  async getIncidentById(id: string): Promise<any | null> {
    try {
      const result = await this.pool.query('SELECT * FROM incidents WHERE id = $1', [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error fetching incident:', error);
      throw error;
    }
  }

  // Get SOS incidents (incidents with title = 'SOS Alert')
  async getSOSIncidents(): Promise<any[]> {
    try {
      const result = await this.pool.query(
        "SELECT * FROM incidents WHERE title = 'SOS Alert' ORDER BY \"createdAt\" DESC"
      );
      return result.rows || [];
    } catch (error) {
      console.error('Error fetching SOS incidents:', error);
      throw error;
    }
  }

  // Update incident status (for SOS events)
  // Store status in description as JSON
  async updateIncidentStatus(id: string, status: string): Promise<boolean> {
    try {
      const incident = await this.getIncidentById(id);
      if (!incident) return false;

      // Parse existing description or create new object
      let descObj: any = {};
      try {
        if (typeof incident.description === 'string') {
          descObj = JSON.parse(incident.description);
        } else if (incident.description) {
          descObj = incident.description;
        }
      } catch {
        // If description is plain text, preserve it
        descObj = { originalMessage: incident.description, status };
      }

      // Update status
      descObj.status = status;
      if (status === 'acknowledged') {
        descObj.acknowledgedAt = new Date().toISOString();
      }
      if (status === 'resolved') {
        descObj.resolvedAt = new Date().toISOString();
      }

      // Update description with new JSON
      await this.pool.query('UPDATE incidents SET description = $1 WHERE id = $2', [
        JSON.stringify(descObj),
        id,
      ]);
      return true;
    } catch (error) {
      console.error('Error updating incident status:', error);
      return false;
    }
  }

  // Close database connection
  async close(): Promise<void> {
    try {
      await this.pool.end();
      console.log('Database connection closed');
    } catch (err) {
      console.error('Error closing database:', err);
    }
  }
}

export default new Database();
