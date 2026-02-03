# Quick Fix Reference Card

## The Problem

```
Flutter App → Authorization: Bearer <JWT>
                    ↓
Next.js API → supabase.auth.getUser() → Looks for cookies ❌
                    ↓
            Returns 401 Unauthorized
```

## The Solution

```
Flutter App → Authorization: Bearer <JWT>
                    ↓
Next.js API → Extract token from header
            → supabase.auth.getUser(token) → Validates JWT ✅
                    ↓
            Returns 200 OK
```

---

## Quick Implementation (Copy-Paste Ready)

### 1. Add this to EVERY protected API route:

```typescript
export async function GET(req: NextRequest) {
  // Extract Bearer token
  const authHeader = req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const token = authHeader.substring(7); // Remove 'Bearer '

  // Create Supabase client
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { get: () => {}, set: () => {}, remove: () => {} } },
  );

  // Validate token
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);
  if (error || !user) {
    return NextResponse.json({ error: "Invalid token" }, { status: 401 });
  }

  // ✅ User is authenticated - continue with your logic
  console.log("✅ Authenticated:", user.email);

  // ... rest of your code
}
```

### 2. Endpoints to Update

- [ ] `/api/user-assignments` ← **Most urgent!**
- [ ] `/api/terminals`
- [ ] `/api/buses`
- [ ] `/api/routes`
- [ ] `/api/bus-routes`
- [ ] `/api/riders/[id]/profile`
- [ ] Any other protected endpoints

### 3. Test

```bash
# Restart backend
npm run dev

# In Flutter app: Sign out → Sign in
# Check logs for "GET /api/user-assignments 200" ✅
```

---

## Key Points

✅ Flutter app is **already correct** - no changes needed
✅ Problem is **100% backend** - need to extract Bearer token
✅ Change from `supabase.auth.getUser()` → `supabase.auth.getUser(token)`
✅ Apply to **ALL** protected endpoints

---

## Full Implementation Guide

See [BACKEND_AUTH_FIX.md](./BACKEND_AUTH_FIX.md) for:

- Complete code examples
- Middleware approach
- Error handling
- Testing steps
