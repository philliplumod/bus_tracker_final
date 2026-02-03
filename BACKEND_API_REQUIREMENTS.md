# Backend API Requirements for User Assignments

## Problem

The Flutter app is getting "No bus route assignment found" because the backend API is not returning the data in the expected format with all necessary JOINs.

## Database Schema Structure

Based on your schema:

```
users → user_assignments → bus_routes → buses + routes → terminals
```

### Tables:

1. **users** (id, email, name, role)
2. **user_assignments** (assignment_id, user_id, bus_route_id)
3. **bus_routes** (bus_route_id, bus_id, route_id)
4. **buses** (bus_id, bus_name)
5. **routes** (route_id, route_name, starting_terminal_id, destination_terminal_id)
6. **terminals** (terminal_id, terminal_name, latitude, longitude)

## Required API Response Format

### Endpoint: `GET /api/user-assignments`

**Required SQL Query Structure:**

```sql
SELECT
  ua.assignment_id,
  ua.user_id,
  ua.bus_route_id,
  ua.assigned_at,
  ua.updated_at,

  -- User data
  u.id as user_id,
  u.email as user_email,
  u.name as user_name,
  u.role as user_role,

  -- Bus data
  b.bus_id,
  b.bus_name,

  -- Route data
  r.route_id,
  r.route_name,
  r.distance_km,
  r.duration_minutes,

  -- Starting terminal
  t1.terminal_id as starting_terminal_id,
  t1.terminal_name as starting_terminal_name,
  t1.latitude as starting_terminal_lat,
  t1.longitude as starting_terminal_lng,

  -- Destination terminal
  t2.terminal_id as destination_terminal_id,
  t2.terminal_name as destination_terminal_name,
  t2.latitude as destination_terminal_lat,
  t2.longitude as destination_terminal_lng

FROM user_assignments ua
JOIN users u ON ua.user_id = u.id
JOIN bus_routes br ON ua.bus_route_id = br.bus_route_id
JOIN buses b ON br.bus_id = b.bus_id
JOIN routes r ON br.route_id = r.route_id
JOIN terminals t1 ON r.starting_terminal_id = t1.terminal_id
JOIN terminals t2 ON r.destination_terminal_id = t2.terminal_id
ORDER BY ua.assigned_at DESC;
```

**Required JSON Response Format:**

```json
{
  "userAssignments": [
    {
      "assignment_id": "uuid-here",
      "user_id": "uuid-here",
      "bus_route_id": "uuid-here",
      "assigned_at": "2026-02-04T10:00:00.000Z",
      "updated_at": "2026-02-04T10:00:00.000Z",

      "user": {
        "id": "uuid-here",
        "email": "rider1@example.com",
        "name": "Rider 1",
        "role": "rider",
        "created_at": "2026-01-01T00:00:00.000Z",
        "updated_at": "2026-02-04T10:00:00.000Z"
      },

      "bus_route": {
        "bus_route_id": "uuid-here",
        "bus_id": "uuid-here",
        "route_id": "uuid-here",
        "created_at": "2026-01-01T00:00:00.000Z",
        "updated_at": "2026-02-04T10:00:00.000Z",

        "bus": {
          "bus_id": "uuid-here",
          "bus_name": "Bus 101",
          "created_at": "2026-01-01T00:00:00.000Z",
          "updated_at": "2026-02-04T10:00:00.000Z"
        },

        "route": {
          "route_id": "uuid-here",
          "route_name": "North Loop",
          "starting_terminal_id": "uuid-here",
          "destination_terminal_id": "uuid-here",
          "distance_km": 15.5,
          "duration_minutes": 45,
          "route_data": {},
          "created_at": "2026-01-01T00:00:00.000Z",
          "updated_at": "2026-02-04T10:00:00.000Z",

          "starting_terminal": {
            "terminal_id": "uuid-here",
            "terminal_name": "North Terminal",
            "latitude": 14.5995,
            "longitude": 120.9842,
            "created_at": "2026-01-01T00:00:00.000Z",
            "updated_at": "2026-02-04T10:00:00.000Z"
          },

          "destination_terminal": {
            "terminal_id": "uuid-here",
            "terminal_name": "South Terminal",
            "latitude": 14.5844,
            "longitude": 120.9797,
            "created_at": "2026-01-01T00:00:00.000Z",
            "updated_at": "2026-02-04T10:00:00.000Z"
          }
        }
      }
    }
  ]
}
```

## Backend Implementation Examples

### Option 1: Node.js/Express with PostgreSQL (Recommended)

```javascript
// routes/user-assignments.js
const express = require("express");
const router = express.Router();
const pool = require("../db/pool"); // Your PostgreSQL pool

router.get("/user-assignments", async (req, res) => {
  try {
    const query = `
      SELECT 
        ua.assignment_id,
        ua.user_id,
        ua.bus_route_id,
        ua.assigned_at,
        ua.updated_at,
        
        -- User data
        jsonb_build_object(
          'id', u.id,
          'email', u.email,
          'name', u.name,
          'role', u.role,
          'created_at', u.created_at,
          'updated_at', u.updated_at
        ) as user,
        
        -- Bus route with nested bus and route
        jsonb_build_object(
          'bus_route_id', br.bus_route_id,
          'bus_id', br.bus_id,
          'route_id', br.route_id,
          'created_at', br.created_at,
          'updated_at', br.updated_at,
          'bus', jsonb_build_object(
            'bus_id', b.bus_id,
            'bus_name', b.bus_name,
            'created_at', b.created_at,
            'updated_at', b.updated_at
          ),
          'route', jsonb_build_object(
            'route_id', r.route_id,
            'route_name', r.route_name,
            'starting_terminal_id', r.starting_terminal_id,
            'destination_terminal_id', r.destination_terminal_id,
            'distance_km', r.distance_km,
            'duration_minutes', r.duration_minutes,
            'route_data', r.route_data,
            'created_at', r.created_at,
            'updated_at', r.updated_at,
            'starting_terminal', jsonb_build_object(
              'terminal_id', t1.terminal_id,
              'terminal_name', t1.terminal_name,
              'latitude', t1.latitude,
              'longitude', t1.longitude,
              'created_at', t1.created_at,
              'updated_at', t1.updated_at
            ),
            'destination_terminal', jsonb_build_object(
              'terminal_id', t2.terminal_id,
              'terminal_name', t2.terminal_name,
              'latitude', t2.latitude,
              'longitude', t2.longitude,
              'created_at', t2.created_at,
              'updated_at', t2.updated_at
            )
          )
        ) as bus_route
        
      FROM user_assignments ua
      JOIN users u ON ua.user_id = u.id
      JOIN bus_routes br ON ua.bus_route_id = br.bus_route_id
      JOIN buses b ON br.bus_id = b.bus_id
      JOIN routes r ON br.route_id = r.route_id
      JOIN terminals t1 ON r.starting_terminal_id = t1.terminal_id
      JOIN terminals t2 ON r.destination_terminal_id = t2.terminal_id
      ORDER BY ua.assigned_at DESC
    `;

    const result = await pool.query(query);

    res.json({
      userAssignments: result.rows,
    });
  } catch (error) {
    console.error("Error fetching user assignments:", error);
    res.status(500).json({ error: "Failed to fetch user assignments" });
  }
});

// Get specific user assignment
router.get("/user-assignments/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const query = `
      SELECT 
        ua.assignment_id,
        ua.user_id,
        ua.bus_route_id,
        ua.assigned_at,
        ua.updated_at,
        
        jsonb_build_object(
          'id', u.id,
          'email', u.email,
          'name', u.name,
          'role', u.role,
          'created_at', u.created_at,
          'updated_at', u.updated_at
        ) as user,
        
        jsonb_build_object(
          'bus_route_id', br.bus_route_id,
          'bus_id', br.bus_id,
          'route_id', br.route_id,
          'created_at', br.created_at,
          'updated_at', br.updated_at,
          'bus', jsonb_build_object(
            'bus_id', b.bus_id,
            'bus_name', b.bus_name,
            'created_at', b.created_at,
            'updated_at', b.updated_at
          ),
          'route', jsonb_build_object(
            'route_id', r.route_id,
            'route_name', r.route_name,
            'starting_terminal_id', r.starting_terminal_id,
            'destination_terminal_id', r.destination_terminal_id,
            'distance_km', r.distance_km,
            'duration_minutes', r.duration_minutes,
            'route_data', r.route_data,
            'created_at', r.created_at,
            'updated_at', r.updated_at,
            'starting_terminal', jsonb_build_object(
              'terminal_id', t1.terminal_id,
              'terminal_name', t1.terminal_name,
              'latitude', t1.latitude,
              'longitude', t1.longitude,
              'created_at', t1.created_at,
              'updated_at', t1.updated_at
            ),
            'destination_terminal', jsonb_build_object(
              'terminal_id', t2.terminal_id,
              'terminal_name', t2.terminal_name,
              'latitude', t2.latitude,
              'longitude', t2.longitude,
              'created_at', t2.created_at,
              'updated_at', t2.updated_at
            )
          )
        ) as bus_route
        
      FROM user_assignments ua
      JOIN users u ON ua.user_id = u.id
      JOIN bus_routes br ON ua.bus_route_id = br.bus_route_id
      JOIN buses b ON br.bus_id = b.bus_id
      JOIN routes r ON br.route_id = r.route_id
      JOIN terminals t1 ON r.starting_terminal_id = t1.terminal_id
      JOIN terminals t2 ON r.destination_terminal_id = t2.terminal_id
      WHERE ua.user_id = $1
      LIMIT 1
    `;

    const result = await pool.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Assignment not found" });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error("Error fetching user assignment:", error);
    res.status(500).json({ error: "Failed to fetch user assignment" });
  }
});

module.exports = router;
```

### Option 2: Supabase Edge Function

```typescript
// supabase/functions/user-assignments/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  // Get user ID from query params or get all
  const url = new URL(req.url);
  const userId = url.searchParams.get("user_id");

  let query = supabase.from("user_assignments").select(`
      assignment_id,
      user_id,
      bus_route_id,
      assigned_at,
      updated_at,
      user:users!user_id (
        id,
        email,
        name,
        role,
        created_at,
        updated_at
      ),
      bus_route:bus_routes!bus_route_id (
        bus_route_id,
        bus_id,
        route_id,
        created_at,
        updated_at,
        bus:buses!bus_id (
          bus_id,
          bus_name,
          created_at,
          updated_at
        ),
        route:routes!route_id (
          route_id,
          route_name,
          starting_terminal_id,
          destination_terminal_id,
          distance_km,
          duration_minutes,
          route_data,
          created_at,
          updated_at,
          starting_terminal:terminals!starting_terminal_id (
            terminal_id,
            terminal_name,
            latitude,
            longitude,
            created_at,
            updated_at
          ),
          destination_terminal:terminals!destination_terminal_id (
            terminal_id,
            terminal_name,
            latitude,
            longitude,
            created_at,
            updated_at
          )
        )
      )
    `);

  if (userId) {
    query = query.eq("user_id", userId).single();
  }

  const { data, error } = await query;

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify(userId ? data : { userAssignments: data }),
    { headers: { "Content-Type": "application/json" } },
  );
});
```

## Testing Your Backend API

### Test 1: Check if API returns nested data

```bash
# Get all assignments
curl http://localhost:3000/api/user-assignments \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response Structure:**

```json
{
  "userAssignments": [
    {
      "assignment_id": "...",
      "user": { "id": "...", "name": "..." },
      "bus_route": {
        "bus": { "bus_name": "..." },
        "route": {
          "route_name": "...",
          "starting_terminal": { "terminal_name": "..." },
          "destination_terminal": { "terminal_name": "..." }
        }
      }
    }
  ]
}
```

### Test 2: Verify all required fields are present

Check that each assignment includes:

- ✅ `user` object with `id`, `name`, `email`, `role`
- ✅ `bus_route` object
- ✅ `bus_route.bus` with `bus_id` and `bus_name`
- ✅ `bus_route.route` with `route_id` and `route_name`
- ✅ `bus_route.route.starting_terminal` with coordinates
- ✅ `bus_route.route.destination_terminal` with coordinates

## Common Backend Mistakes

### ❌ Mistake 1: Returning Flat Data

```json
{
  "userAssignments": [
    {
      "assignment_id": "...",
      "user_id": "...",
      "bus_route_id": "..."
    }
  ]
}
```

**Problem:** No nested objects, Flutter app can't access bus/route names.

### ❌ Mistake 2: Missing Nested Objects

```json
{
  "userAssignments": [
    {
      "assignment_id": "...",
      "user_id": "...",
      "bus_id": "...",
      "route_id": "..."
      // Missing: user, bus_route objects
    }
  ]
}
```

**Problem:** Flutter expects nested `user` and `bus_route` objects.

### ❌ Mistake 3: Incomplete JOINs

```json
{
  "userAssignments": [
    {
      "assignment_id": "...",
      "user": { "id": "..." },
      "bus_route": {
        "bus_route_id": "..."
        // Missing: bus and route objects
      }
    }
  ]
}
```

**Problem:** Missing the full chain of JOINs.

## Quick Fix Checklist

1. ✅ Backend performs JOIN on all 6 tables
2. ✅ Response includes nested `user` object
3. ✅ Response includes nested `bus_route` object
4. ✅ `bus_route` includes nested `bus` object
5. ✅ `bus_route` includes nested `route` object
6. ✅ `route` includes both `starting_terminal` and `destination_terminal`
7. ✅ All IDs and names are present (not null)
8. ✅ Terminal coordinates are included

## Debugging Your Backend

Add logging to your backend to verify the query results:

```javascript
// After executing the query
console.log("📊 Fetched assignments:", result.rows.length);
result.rows.forEach((assignment, i) => {
  console.log(`[${i}] Assignment ID: ${assignment.assignment_id}`);
  console.log(`    User: ${assignment.user?.name} (${assignment.user?.id})`);
  console.log(`    Bus: ${assignment.bus_route?.bus?.bus_name}`);
  console.log(`    Route: ${assignment.bus_route?.route?.route_name}`);
  console.log(
    `    Start: ${assignment.bus_route?.route?.starting_terminal?.terminal_name}`,
  );
  console.log(
    `    Dest: ${assignment.bus_route?.route?.destination_terminal?.terminal_name}`,
  );
});
```

## Next Steps

1. **Update your backend API** to return the nested structure shown above
2. **Test the API** using curl to verify the response format
3. **Re-run the Flutter app** - it should now find the assignments
4. **Check the Flutter logs** - should show "✅ MATCH FOUND!"

The Flutter app is already correctly configured - it just needs the backend to return the proper nested/joined data structure!
