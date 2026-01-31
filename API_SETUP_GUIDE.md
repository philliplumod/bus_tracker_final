# Authentication API Setup Guide

## Important Notes

This Flutter app requires a backend API to handle authentication. **The mobile app does NOT create rider accounts** - riders are created by administrators through a separate web dashboard.

## Required API Endpoints

### Base URL Configuration

Update the `baseUrl` in `lib/data/datasources/auth_remote_data_source.dart`:

```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

### 1. Sign Up (Passenger Only) ✅

**Endpoint:** `POST /api/auth/sign-up`

**Purpose:** Register new passenger accounts ONLY

**Request Body:**

```json
{
  "email": "string (required, valid email)",
  "password": "string (required, min 6 characters)",
  "name": "string (required)"
}
```

**Backend Requirements:**

- MUST force `role = "passenger"` on the server side
- MUST reject any attempts to specify a different role
- MUST validate email uniqueness
- MUST hash passwords securely

**Response (201 Created):**

```json
{
  "user": {
    "id": "string (uuid)",
    "email": "string",
    "name": "string",
    "role": "passenger"
  },
  "success": true
}
```

**Error Responses:**

- `400` - Missing fields or validation failure
- `409` - Email already exists
- `500` - Internal server error

---

### 2. Sign In (All Roles) ✅

**Endpoint:** `POST /api/auth/sign-in`

**Purpose:** Authenticate passengers, riders, and admins

**Request Body:**

```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Response (200 OK):**

```json
{
  "user": {
    "id": "string (uuid)",
    "email": "string",
    "name": "string",
    "role": "admin | rider | passenger",
    "assignedRoute": "string (rider only, optional)",
    "busName": "string (rider only, optional)"
  },
  "success": true
}
```

**Post-Login App Behavior:**

- **Passenger** → Main menu with trip planning and bus search
- **Rider** → Map view showing current location and assigned route
- **Admin** → Main menu (admin features to be implemented)

**Error Responses:**

- `400` - Missing email or password
- `401` - Invalid credentials
- `500` - Internal server error

---

### 3. Sign Out ✅

**Endpoint:** `POST /api/auth/sign-out`

**Purpose:** Sign out the currently authenticated user

**Authentication:** Required (any role)

**Response (200 OK):**

```json
{
  "success": true
}
```

---

## User Roles & Access Control

### Passenger

- ✅ Can self-register through mobile app signup
- ✅ Access to trip planning features
- ✅ Can search for buses
- ✅ View bus routes and locations
- ❌ No access to rider features

### Rider (Driver)

- ❌ CANNOT self-register through mobile app
- ✅ Created ONLY by Admin through web dashboard
- ✅ Upon login, immediately sees map with:
  - Current location
  - Assigned route/destination
  - Real-time GPS tracking
- ❌ No access to passenger planning features

### Admin

- ❌ CANNOT self-register through mobile app
- ✅ Created through secure admin process
- ✅ Can create rider accounts via web dashboard
- ✅ Assigns routes and bus names to riders

---

## Database Schema

### User Table

| Column         | Type        | Required | Description                      |
| -------------- | ----------- | -------- | -------------------------------- |
| id             | uuid        | Yes      | Primary key                      |
| email          | text        | Yes      | Unique email address             |
| name           | text        | Yes      | Full name                        |
| role           | text        | Yes      | `admin`, `rider`, or `passenger` |
| assigned_route | text        | No       | Route assignment (riders only)   |
| bus_name       | text        | No       | Bus identifier (riders only)     |
| created_at     | timestamptz | Yes      | Account creation timestamp       |
| updated_at     | timestamptz | Yes      | Last update timestamp            |

**Constraints:**

- `email` must be unique
- `role` must be one of: `admin`, `rider`, `passenger`
- `assigned_route` and `bus_name` should only have values when `role = 'rider'`

---

## Security Requirements

### Password Security

- Minimum 6 characters (enforced in app)
- Must be hashed using bcrypt or similar before storage
- Never store plain text passwords

### Session Management

- Currently using local storage (SharedPreferences)
- Consider implementing JWT tokens for production
- Implement token refresh mechanism
- Add session timeout

### API Security

- Use HTTPS in production
- Implement rate limiting
- Add CORS policies
- Validate all inputs on server side
- Sanitize user inputs to prevent SQL injection

---

## Testing the Integration

### Test Credentials Setup

Create test accounts in your database:

**Test Passenger:**

```
Email: passenger@test.com
Password: test123
Role: passenger
```

**Test Rider:**

```
Email: rider@test.com
Password: test123
Role: rider
Assigned Route: "Route 1: Downtown - Airport"
Bus Name: "Bus A-101"
```

**Test Admin:**

```
Email: admin@test.com
Password: test123
Role: admin
```

### Testing Flow

1. **Test Signup (Passenger):**
   - Open app → Should show Login page
   - Tap "Sign Up"
   - Fill in email, password, name
   - Submit → Should create passenger account and redirect to main menu

2. **Test Login (Rider):**
   - Enter rider credentials
   - Should redirect to map page showing rider's location and assigned route

3. **Test Login (Passenger):**
   - Enter passenger credentials
   - Should redirect to main menu with trip planning options

---

## Development Tips

### API URL Configuration

For local development:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';

// For Physical Device (use your computer's IP)
static const String baseUrl = 'http://192.168.1.xxx:3000/api';
```

### Troubleshooting

**Issue:** Cannot connect to API

- Check if backend server is running
- Verify the baseUrl is correct
- Check network permissions in AndroidManifest.xml / Info.plist

**Issue:** Signup returns error

- Verify backend is enforcing role = "passenger"
- Check if email already exists
- Ensure password meets minimum requirements

**Issue:** Rider login shows wrong page

- Verify backend returns correct role
- Check that assignedRoute and busName are included in response
- Ensure main.dart routing logic is correct

---

## Next Steps

1. **Set up your backend API** with the endpoints described above
2. **Update the baseUrl** in `auth_remote_data_source.dart`
3. **Create test accounts** in your database
4. **Test the authentication flow** with all three roles
5. **Implement additional security** (JWT, rate limiting, etc.)
6. **Create web dashboard** for admin to manage riders

---

## Admin Web Dashboard Requirements

The web dashboard should allow admins to:

- ✅ Create new rider accounts
- ✅ Assign routes to riders
- ✅ Assign bus names/numbers to riders
- ✅ View all users and their roles
- ✅ Edit rider information
- ✅ Deactivate/delete accounts
- ✅ View rider activity logs

This dashboard is separate from the mobile app and should be built as a web application.
