# Backend Authentication Fix for JWT Bearer Tokens

## Problem

Your Flutter app sends JWT tokens via `Authorization: Bearer <token>` header, but your Next.js API endpoints use `supabase.auth.getUser()` which expects Supabase session cookies instead.

## Root Cause

- **Flutter app**: Sends `Authorization: Bearer eyJhbGc...` (JWT token)
- **Next.js backend**: Uses `supabase.auth.getUser()` which reads session from cookies
- **Result**: Backend can't find the session, returns 401 Unauthorized

---

## Solution Options

### Option 1: Extract and Validate Bearer Token (Recommended)

Modify your API routes to extract the JWT token from the Authorization header and pass it to Supabase.

#### Step 1: Create a middleware utility

Create `lib/auth-middleware.ts`:

```typescript
import { createServerClient } from "@supabase/ssr";
import { NextRequest, NextResponse } from "next/server";

export async function extractUser(req: NextRequest) {
  // Get token from Authorization header
  const authHeader = req.headers.get("authorization");

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { user: null, error: "No authorization token provided" };
  }

  // Extract the token
  const token = authHeader.substring(7); // Remove 'Bearer ' prefix

  // Create Supabase client
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get: () => {},
        set: () => {},
        remove: () => {},
      },
    },
  );

  // Validate the token with Supabase
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);

  if (error || !user) {
    return { user: null, error: error?.message || "Invalid token" };
  }

  return { user, error: null, supabase };
}
```

#### Step 2: Update your API routes

**Before:**

```typescript
export async function GET(req: NextRequest) {
  const supabase = createServerClient(...)
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // ... rest of your code
}
```

**After:**

```typescript
import { extractUser } from "@/lib/auth-middleware";

export async function GET(req: NextRequest) {
  const { user, error, supabase } = await extractUser(req);

  if (!user) {
    return NextResponse.json(
      { error: error || "Unauthorized" },
      { status: 401 },
    );
  }

  // ... rest of your code (use the supabase client from extractUser)
}
```

#### Step 3: Update all protected endpoints

Apply this pattern to ALL your API routes:

- `/api/user-assignments`
- `/api/terminals`
- `/api/buses`
- `/api/routes`
- `/api/bus-routes`
- `/api/riders/[id]/profile`
- Any other protected endpoints

---

### Option 2: Use Supabase JWT Verification

Alternative approach using Supabase's JWT verification:

```typescript
import { createClient } from "@supabase/supabase-js";
import jwt from "jsonwebtoken";

export async function verifyToken(token: string) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );

  try {
    // Verify the JWT token
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error) throw error;
    return { user, error: null };
  } catch (error) {
    return { user: null, error };
  }
}
```

---

## Example: Full API Route Implementation

Here's a complete example for `/api/user-assignments`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";

export async function GET(req: NextRequest) {
  try {
    // Extract Bearer token
    const authHeader = req.headers.get("authorization");

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return NextResponse.json(
        { error: "Missing or invalid authorization header" },
        { status: 401 },
      );
    }

    const token = authHeader.substring(7);

    // Create Supabase client
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get: () => {},
          set: () => {},
          remove: () => {},
        },
      },
    );

    // Validate token and get user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("Auth error:", authError);
      return NextResponse.json(
        { error: "Invalid or expired token" },
        { status: 401 },
      );
    }

    console.log("✅ User authenticated:", user.email);

    // Fetch user assignments
    const { data: assignments, error } = await supabase
      .from("user_assignments")
      .select("*")
      .eq("user_id", user.id);

    if (error) {
      console.error("Database error:", error);
      return NextResponse.json(
        { error: "Failed to fetch assignments" },
        { status: 500 },
      );
    }

    return NextResponse.json({
      userAssignments: assignments || [],
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
```

---

## Testing the Fix

After implementing the changes:

1. **Restart your Next.js backend**:

   ```bash
   npm run dev
   ```

2. **Sign out and sign in again in the Flutter app**

3. **Check the logs** - you should see:
   ```
   ✅ User authenticated: riderexample@gmail.com
   ✅ Auth token present (XXX chars)
   POST /api/auth/sign-in 200
   GET /api/user-assignments 200  ✅ (was 401 before)
   ```

---

## Key Changes Summary

✅ Extract JWT token from `Authorization: Bearer <token>` header
✅ Pass token to `supabase.auth.getUser(token)` instead of relying on cookies  
✅ Return proper error messages for debugging
✅ Apply to ALL protected API endpoints

---

## Additional Notes

- The Flutter app is already correctly sending the token
- The issue is 100% on the backend side
- No changes needed to the Flutter app
- Make sure your Supabase JWT secret is correct in environment variables
