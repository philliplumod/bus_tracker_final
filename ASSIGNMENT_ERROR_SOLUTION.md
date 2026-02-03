# Assignment Error - Complete Solution Guide

## Problem

Getting "No bus route assignment found" error even though data exists in the database.

---

## 🎯 MOST LIKELY CAUSE: Backend API Structure Issue

Based on your database schema, **your backend API is probably not returning the data in the format the Flutter app expects**.

### Your Database Structure

```
users
  ↓
user_assignments (has: user_id, bus_route_id)
  ↓
bus_routes (has: bus_id, route_id)
  ↓ ↓
buses    routes (has: starting_terminal_id, destination_terminal_id)
         ↓
         terminals
```

### What Flutter App Expects

The app expects **nested/joined data** from `/api/user-assignments`:

```json
{
  "userAssignments": [
    {
      "assignment_id": "uuid",
      "user_id": "uuid",
      "bus_route_id": "uuid",
      "user": {
        "id": "uuid",
        "name": "Rider 1",
        "email": "rider1@example.com",
        "role": "rider"
      },
      "bus_route": {
        "bus_route_id": "uuid",
        "bus_id": "uuid",
        "route_id": "uuid",
        "bus": {
          "bus_id": "uuid",
          "bus_name": "Bus 101"
        },
        "route": {
          "route_id": "uuid",
          "route_name": "North Loop",
          "starting_terminal": {
            "terminal_id": "uuid",
            "terminal_name": "North Terminal",
            "latitude": 14.5995,
            "longitude": 120.9842
          },
          "destination_terminal": {
            "terminal_id": "uuid",
            "terminal_name": "South Terminal",
            "latitude": 14.5844,
            "longitude": 120.9797
          }
        }
      }
    }
  ]
}
```

### What Your Backend Might Be Returning (Wrong!)

```json
{
  "userAssignments": [
    {
      "assignment_id": "uuid",
      "user_id": "uuid",
      "bus_route_id": "uuid"
    }
  ]
}
```

**Solution:** See **[BACKEND_API_REQUIREMENTS.md](BACKEND_API_REQUIREMENTS.md)** for:

- Complete SQL query with all JOINs
- Exact response format required
- Backend implementation examples (Node.js/Express, Supabase)

---

## 🔧 Changes Made to Flutter App

I've added extensive debugging to help identify the exact issue:

### Modified Files:

1. **`lib/data/datasources/backend_api_service.dart`**
   - Enhanced `getUserAssignment()` with detailed logging
   - Shows all assignments and compares user IDs
   - Tries case-insensitive matching as fallback

2. **`lib/data/datasources/api_client.dart`**
   - Added token verification warnings
   - Shows if auth token is missing

3. **`lib/presentation/bloc/rider_tracking/rider_tracking_bloc.dart`**
   - Added detailed user info logging
   - Shows user ID format and length

---

## 📋 Diagnostic Steps

### Step 1: Run the Diagnostic Tool

```bash
diagnose_assignment.bat
```

This will:

- Set up ADB port forwarding
- Check if backend is running
- Show you how to view logs

### Step 2: Test Your Backend API Directly

```bash
# Login and get token
curl -X POST http://localhost:3000/api/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"rider1@example.com","password":"password"}'

# Copy the access_token from response

# Test user-assignments endpoint
curl http://localhost:3000/api/user-assignments \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Check the response:**

- ✅ Does it include a `user` object?
- ✅ Does it include a `bus_route` object?
- ✅ Does `bus_route` have nested `bus` and `route` objects?
- ✅ Does `route` have `starting_terminal` and `destination_terminal` objects?

**If any of these are missing, your backend needs to be fixed!**

### Step 3: Run the Flutter App with Debug Logging

```bash
flutter run --verbose
```

Watch for these debug sections in the console:

```
═══════════════════════════════════════
🚀 Starting rider tracking for: Rider 1
   User ID: "bdcca47e-1c3d-41f2-bc95-743ec265c2d7"
═══════════════════════════════════════

🌐 GET http://localhost:3000/api/user-assignments
✅ Auth token present (324 chars)
📥 Response status: 200

═══════════════════════════════════════
🔍 getUserAssignment called
   Looking for userId: "bdcca47e-1c3d-41f2-bc95-743ec265c2d7"
📊 Fetched 3 total assignments from API
📋 All assignments in database:
   [0] userId: "bdcca47e-1c3d-41f2-bc95-743ec265c2d7"
       userName: Rider 1
       busName: Bus 101
       routeName: North Loop
       exact match: true
✅ MATCH FOUND!
═══════════════════════════════════════
```

---

## 🚨 Error Scenarios and Solutions

### Scenario 1: API Call Fails with Error

**Logs show:**

```
❌ API GET error: ApiException: POST request failed: ...
```

**Possible Causes:**

1. **Backend not running** - Start your backend server
2. **Wrong URL** - Check `lib/core/di/dependency_injection.dart` line 129
3. **Network not configured** - Run `adb reverse tcp:3000 tcp:3000`

**Fix:**

```bash
# For physical device:
adb reverse tcp:3000 tcp:3000

# Or update base URL to your computer's IP:
# Edit lib/core/di/dependency_injection.dart
apiClient = ApiClient(
  baseUrl: 'http://192.168.1.XXX:3000',  // Your IP
```

### Scenario 2: API Returns Empty Array

**Logs show:**

```
📊 Fetched 0 total assignments from API
❌ No assignments exist in database at all!
```

**Cause:** No assignments created in the database yet.

**Fix:** Create assignments in your backend admin panel or database:

```sql
-- Example: Create assignment for a rider
INSERT INTO user_assignments (user_id, bus_route_id)
VALUES (
  'user-uuid-here',
  'bus-route-uuid-here'
);
```

### Scenario 3: API Returns Data But No Match Found

**Logs show:**

```
📊 Fetched 3 total assignments from API
   [0] userId: "abc-123"
       exact match: false
❌ NO MATCH FOUND!
   Searched for userId: "xyz-789"
```

**Cause:** User ID mismatch between login and database.

**Fix:**

1. Check what user ID is returned from login
2. Verify it matches the user_id in your database
3. Update the assignment in the database to use the correct user_id

### Scenario 4: API Returns Data But Flutter Crashes

**Error:**

```
StateError: User and bus route must be loaded to convert to entity
```

**Cause:** Backend is returning flat data without nested objects.

**Fix:** Update your backend to return nested data structure. See **[BACKEND_API_REQUIREMENTS.md](BACKEND_API_REQUIREMENTS.md)**

---

## ✅ Checklist

Go through these in order:

### Backend Checklist

- [ ] Backend server is running (`curl http://localhost:3000/api/health`)
- [ ] `/api/user-assignments` endpoint exists
- [ ] Endpoint requires authentication (token in header)
- [ ] Response includes nested `user` object
- [ ] Response includes nested `bus_route` object with `bus` and `route`
- [ ] Response includes terminals with coordinates
- [ ] At least one assignment exists in database
- [ ] User ID in database matches user ID from login

### Network Checklist

- [ ] Physical device: `adb reverse tcp:3000 tcp:3000` is running
- [ ] OR baseUrl updated to computer's IP address
- [ ] Backend is accessible from the device

### Flutter App Checklist

- [ ] User can login successfully
- [ ] Auth token is saved after login
- [ ] Modified debug code is in place
- [ ] App is running with `flutter run --verbose`

---

## 📚 Related Documents

- **[BACKEND_API_REQUIREMENTS.md](BACKEND_API_REQUIREMENTS.md)** - Complete backend API specification with SQL queries
- **[diagnose_assignment.bat](diagnose_assignment.bat)** - Automated diagnostic script
- **[TROUBLESHOOTING_ASSIGNMENTS.md](TROUBLESHOOTING_ASSIGNMENTS.md)** - General troubleshooting guide
- **[NETWORK_CONFIGURATION.md](NETWORK_CONFIGURATION.md)** - Network setup for physical devices

---

## 🎯 Quick Solution Summary

**If you see the assignment error:**

1. **First, test your backend API directly** using curl (see Step 2 above)
   - If the response doesn't have nested objects → Fix your backend (see BACKEND_API_REQUIREMENTS.md)
   - If the response looks good → Continue to step 2

2. **Check network configuration**

   ```bash
   adb reverse tcp:3000 tcp:3000
   ```

3. **Run the app with debug logging**

   ```bash
   flutter run --verbose
   ```

4. **Read the console output** - it will tell you exactly what's wrong:
   - Token missing? → Logout and login again
   - No assignments? → Create assignments in backend
   - User ID mismatch? → Fix user_id in database
   - Backend error? → Fix backend API structure

The enhanced logging makes the problem obvious. Share the console output if you need more help!
