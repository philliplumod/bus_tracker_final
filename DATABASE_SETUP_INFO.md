# Database Storage - Current Setup

## 🔍 Current Status: DEMO MODE (Local Storage)

Your app is currently running in **Demo Mode**, which means:

### ✅ What's Working Now:

- Accounts ARE being stored when you sign up
- Data is saved in **local device storage** (SharedPreferences)
- Accounts persist after closing and reopening the app
- Works completely offline (no internet needed)

### ⚠️ Limitations:

- Data is stored ONLY on the device (not in a central database)
- Accounts are NOT shared across different devices
- If you uninstall the app, all data is lost
- No server-side validation or security

### 📱 Test Accounts Already Available:

You can sign in with these pre-configured demo accounts:

1. **Passenger Account:**
   - Email: `passenger@test.com`
   - Password: `password123`

2. **Rider Account:**
   - Email: `rider@test.com`
   - Password: `password123`
   - Assigned to Bus 101, Route: SM Cebu - Ayala Center

3. **Admin Account:**
   - Email: `admin@test.com`
   - Password: `password123`

---

## 🚀 To Store in a REAL Database (Backend Required)

If you want accounts stored in a central database (PostgreSQL, MySQL, etc.), follow these steps:

### Step 1: Set Up a Backend Server

You need a backend API server. Choose one:

#### Option A: Node.js + Express + PostgreSQL

**Quick Start:**

```bash
# 1. Create backend folder
mkdir bus-tracker-backend
cd bus-tracker-backend

# 2. Initialize Node.js project
npm init -y

# 3. Install dependencies
npm install express pg bcrypt jsonwebtoken cors dotenv

# 4. Create server.js (see example below)
```

**Example server.js:**

```javascript
const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");
const bcrypt = require("bcrypt");

const app = express();
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  host: "localhost",
  database: "bus_tracker",
  user: "postgres",
  password: "your_password",
  port: 5432,
});

// Sign up endpoint
app.post("/api/auth/sign-up", async (req, res) => {
  try {
    const { email, password, name } = req.body;

    // Check if user exists
    const existingUser = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email],
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: "Email already exists" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user (always passenger)
    const result = await pool.query(
      "INSERT INTO users (email, password, name, role) VALUES ($1, $2, $3, $4) RETURNING id, email, name, role",
      [email, hashedPassword, name, "passenger"],
    );

    res.status(201).json({
      user: result.rows[0],
      success: true,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Server error" });
  }
});

// Sign in endpoint
app.post("/api/auth/sign-in", async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);

    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Don't send password back
    delete user.password;

    res.json({
      user,
      success: true,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Server error" });
  }
});

// Sign out endpoint
app.post("/api/auth/sign-out", (req, res) => {
  res.json({ success: true });
});

app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
```

**Database Schema:**

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'passenger',
  assigned_route VARCHAR(255),
  bus_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Option B: Python + Flask + PostgreSQL

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import bcrypt

app = Flask(__name__)
CORS(app)

# Database connection
def get_db():
    return psycopg2.connect(
        host="localhost",
        database="bus_tracker",
        user="postgres",
        password="your_password"
    )

@app.route('/api/auth/sign-up', methods=['POST'])
def sign_up():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    name = data.get('name')

    conn = get_db()
    cur = conn.cursor()

    # Check if user exists
    cur.execute('SELECT * FROM users WHERE email = %s', (email,))
    if cur.fetchone():
        return jsonify({'error': 'Email already exists'}), 409

    # Hash password
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    # Create user
    cur.execute(
        'INSERT INTO users (email, password, name, role) VALUES (%s, %s, %s, %s) RETURNING id, email, name, role',
        (email, hashed, name, 'passenger')
    )
    user = cur.fetchone()
    conn.commit()

    return jsonify({
        'user': {
            'id': user[0],
            'email': user[1],
            'name': user[2],
            'role': user[3]
        },
        'success': True
    }), 201

@app.route('/api/auth/sign-in', methods=['POST'])
def sign_in():
    data = request.json
    # ... similar implementation
    pass

if __name__ == '__main__':
    app.run(port=3000, debug=True)
```

### Step 2: Update Flutter App

In `lib/data/datasources/auth_remote_data_source.dart`:

```dart
// Change this line:
static const bool useDemoMode = false;  // Changed from true to false
```

### Step 3: Run Your Backend

```bash
# For Node.js
node server.js

# For Python
python app.py
```

Your backend should now be running at `http://localhost:3000`

### Step 4: Test the App

1. Run your Flutter app
2. Try signing up with a new account
3. The account will now be stored in your PostgreSQL database!

---

## 📚 More Information

- **Full API Documentation:** See [API_SETUP_GUIDE.md](API_SETUP_GUIDE.md)
- **Demo Mode Details:** Accounts stored in device's SharedPreferences
- **Production Ready:** For production, use HTTPS and add JWT authentication

---

## 🤔 Which Option Should You Choose?

### Choose DEMO MODE if:

- ✅ You're just testing the app
- ✅ You don't have a backend yet
- ✅ You want to quickly see how the app works
- ✅ You're doing local development

### Choose REAL DATABASE if:

- ✅ You need accounts accessible across devices
- ✅ You're deploying to production
- ✅ You need centralized user management
- ✅ You want proper security and validation
