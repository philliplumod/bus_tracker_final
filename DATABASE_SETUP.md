# Firebase Database Setup Guide

This guide helps you set up the Firebase Realtime Database structure for the improved Bus Tracker app.

## Database Rules

First, set up your Firebase database rules for security:

```json
{
  "rules": {
    "routes": {
      ".read": true,
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'admin'"
    },
    "terminals": {
      ".read": true,
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'admin'"
    },
    "bus_routes": {
      ".read": true,
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'admin'"
    },
    "user_assignments": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'admin'",
      ".indexOn": ["user_id", "bus_route_id"]
    },
    "users": {
      ".read": "auth != null",
      "$uid": {
        ".write": "auth != null && (auth.uid == $uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "buses": {
      ".read": true,
      "$busId": {
        ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'rider'"
      }
    }
  }
}
```

## Sample Data Structure

### 1. Terminals

```json
{
  "terminals": {
    "terminal-001": {
      "terminal_name": "Central Terminal",
      "latitude": 14.5995,
      "longitude": 120.9842,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    },
    "terminal-002": {
      "terminal_name": "North Terminal",
      "latitude": 14.65,
      "longitude": 121.03,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    },
    "terminal-003": {
      "terminal_name": "East Terminal",
      "latitude": 14.61,
      "longitude": 121.05,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### 2. Routes

```json
{
  "routes": {
    "route-001": {
      "route_name": "Route 1",
      "starting_terminal_id": "terminal-001",
      "destination_terminal_id": "terminal-002",
      "distance_km": 15.5,
      "duration_minutes": 45,
      "route_data": null,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    },
    "route-002": {
      "route_name": "Route 2",
      "starting_terminal_id": "terminal-001",
      "destination_terminal_id": "terminal-003",
      "distance_km": 18.2,
      "duration_minutes": 55,
      "route_data": null,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### 3. Buses

```json
{
  "buses": {
    "bus-001": {
      "busNumber": "Bus 101",
      "route": "Route 1",
      "location": {
        "1704067200000": {
          "latitude": 14.605,
          "longitude": 120.99,
          "altitude": 10.5,
          "speed": 12.5
        }
      }
    },
    "bus-002": {
      "busNumber": "Bus 102",
      "route": "Route 1",
      "location": {
        "1704067200000": {
          "latitude": 14.62,
          "longitude": 121.01,
          "altitude": 15.0,
          "speed": 15.0
        }
      }
    }
  }
}
```

### 4. Bus Routes (Junction Table)

```json
{
  "bus_routes": {
    "bus-route-001": {
      "bus_id": "bus-001",
      "route_id": "route-001",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    },
    "bus-route-002": {
      "bus_id": "bus-002",
      "route_id": "route-001",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### 5. Users

```json
{
  "users": {
    "user-001": {
      "email": "rider1@example.com",
      "name": "John Doe",
      "role": "rider",
      "assignedRoute": "Route 1",
      "busName": "Bus 101",
      "busRouteId": "bus-route-001",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    },
    "user-002": {
      "email": "passenger1@example.com",
      "name": "Jane Smith",
      "role": "passenger",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    },
    "user-003": {
      "email": "admin@example.com",
      "name": "Admin User",
      "role": "admin",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### 6. User Assignments

```json
{
  "user_assignments": {
    "assignment-001": {
      "user_id": "user-001",
      "bus_route_id": "bus-route-001",
      "assigned_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

## Setup Steps

### Step 1: Create Terminals

1. Go to Firebase Console → Realtime Database
2. Create a `terminals` node
3. Add terminal entries with unique IDs
4. Include name, latitude, longitude, and timestamps

### Step 2: Create Routes

1. Create a `routes` node
2. Add route entries with unique IDs
3. Link to terminal IDs (starting and destination)
4. Add distance and duration information

### Step 3: Create Buses

1. Create a `buses` node (may already exist)
2. Add or update bus entries
3. Ensure each bus has a `route` field matching route names

### Step 4: Create Bus-Route Assignments

1. Create a `bus_routes` node
2. Link buses to routes using their IDs
3. This allows for many-to-many relationships

### Step 5: Update Users

1. Update existing `users` entries
2. Add `busRouteId` field for riders
3. Ensure role field is set correctly

### Step 6: Create User Assignments

1. Create a `user_assignments` node
2. Link rider users to bus_route entries
3. This connects riders to their assigned routes

## Database Indexes

To optimize queries, create indexes on these fields:

1. **user_assignments**
   - Index on `user_id`
   - Index on `bus_route_id`

2. **bus_routes**
   - Index on `bus_id`
   - Index on `route_id`

Add indexes in Firebase Console → Realtime Database → Rules:

```json
{
  "rules": {
    "user_assignments": {
      ".indexOn": ["user_id", "bus_route_id"]
    },
    "bus_routes": {
      ".indexOn": ["bus_id", "route_id"]
    }
  }
}
```

## Data Validation

Ensure your data meets these constraints:

### Terminals

- `latitude`: -90 to 90
- `longitude`: -180 to 180
- `terminal_name`: Unique

### Routes

- `starting_terminal_id` and `destination_terminal_id`: Must reference valid terminals
- `distance_km`: Positive number
- `duration_minutes`: Positive integer
- `route_name`: Unique

### Users

- `role`: Must be 'admin', 'rider', or 'passenger'
- `email`: Unique
- For riders: `busRouteId` should reference a valid bus_route entry

### User Assignments

- `user_id`: Must reference a valid user
- `bus_route_id`: Must reference a valid bus_route entry
- One assignment per user (for now)

## Migration Script (Optional)

If you're migrating from existing data, use this structure:

```javascript
// Firebase Admin SDK or Firebase Console
const db = admin.database();

// Example: Add a new route
async function addRoute() {
  const routeRef = db.ref("routes").push();
  await routeRef.set({
    route_name: "Route 3",
    starting_terminal_id: "terminal-001",
    destination_terminal_id: "terminal-003",
    distance_km: 20.5,
    duration_minutes: 60,
    route_data: null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
  console.log("Route added:", routeRef.key);
}

// Example: Link bus to route
async function linkBusToRoute(busId, routeId) {
  const busRouteRef = db.ref("bus_routes").push();
  await busRouteRef.set({
    bus_id: busId,
    route_id: routeId,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
  console.log("Bus-Route link created:", busRouteRef.key);
}

// Example: Assign rider to bus route
async function assignRiderToRoute(userId, busRouteId) {
  const assignmentRef = db.ref("user_assignments").push();
  await assignmentRef.set({
    user_id: userId,
    bus_route_id: busRouteId,
    assigned_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
  console.log("User assignment created:", assignmentRef.key);
}
```

## Testing the Setup

After setting up the database, test with these queries:

```dart
// Get all routes
final routesSnapshot = await FirebaseDatabase.instance.ref('routes').get();
print('Routes: ${routesSnapshot.value}');

// Get user assignment
final userId = 'user-001';
final assignmentSnapshot = await FirebaseDatabase.instance
    .ref('user_assignments')
    .orderByChild('user_id')
    .equalTo(userId)
    .get();
print('User assignment: ${assignmentSnapshot.value}');

// Get route details
final routeId = 'route-001';
final routeSnapshot = await FirebaseDatabase.instance
    .ref('routes/$routeId')
    .get();
print('Route details: ${routeSnapshot.value}');
```

## Troubleshooting

### Issue: Routes not loading

- Check if `routes` and `terminals` nodes exist
- Verify terminal IDs in routes match actual terminal entries
- Check Firebase rules allow read access

### Issue: User assignments not found

- Verify `user_assignments` node exists
- Check `user_id` matches the authenticated user's ID
- Ensure `bus_route_id` references a valid entry

### Issue: Buses not showing on routes

- Verify bus `route` field matches `route_name` in routes
- Check bus location data is properly formatted
- Ensure timestamps are recent

## Best Practices

1. **Use Push Keys**: Let Firebase generate unique IDs with `.push()`
2. **Timestamps**: Always use ISO 8601 format
3. **Denormalization**: Store route names in buses for quick access
4. **Soft Deletes**: Add `deleted_at` field instead of removing data
5. **Audit Trail**: Keep `created_at` and `updated_at` for all records
6. **Validation**: Validate data before writing to database

## Next Steps

After setting up the database:

1. Test the app with sample data
2. Verify all screens load correctly
3. Check real-time updates work
4. Add more routes and terminals as needed
5. Assign riders to routes
6. Monitor Firebase usage and optimize queries

---

For more information, see [IMPROVEMENTS_GUIDE.md](IMPROVEMENTS_GUIDE.md)
