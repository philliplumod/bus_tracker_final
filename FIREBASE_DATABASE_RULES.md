# Firebase Realtime Database Rules

## Problem

The app is unable to write location data to Firebase Realtime Database because of permission restrictions.

## Solution

You need to configure your Firebase Realtime Database rules to allow writes.

## How to Set Up Rules

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `minibustracker-b2264`
3. **Navigate to**: Realtime Database → Rules
4. **Update the rules** to one of the following options:

### Option 1: Allow Authenticated Users (Recommended for Production)

```json
{
  "rules": {
    "riders": {
      "$userId": {
        "location": {
          ".read": true,
          ".write": "auth != null"
        }
      }
    },
    "test_connection": {
      ".read": true,
      ".write": "auth != null"
    }
  }
}
```

This allows:

- Anyone to read rider locations (needed for passengers)
- Only authenticated users to write location updates

### Option 2: Open Access (For Development/Testing Only)

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

⚠️ **WARNING**: This allows anyone to read/write to your database. Only use this temporarily for testing!

### Option 3: Allow Specific User to Write Their Own Location

```json
{
  "rules": {
    "riders": {
      "$userId": {
        "location": {
          ".read": true,
          ".write": "auth != null && auth.uid == $userId"
        }
      }
    }
  }
}
```

This ensures riders can only update their own location.

## Current Implementation

The app now includes **automatic anonymous authentication** for Firebase. When a rider starts tracking:

1. The app checks if the user is authenticated with Firebase
2. If not, it signs in anonymously
3. This provides the necessary authentication to write to the database (if rules allow authenticated writes)

## Verification

After updating the rules:

1. Run the app
2. Start location tracking as a rider
3. Check the logs for:
   - `✅ Firebase connectivity test successful` - Database is accessible
   - `✅ Signed in anonymously to Firebase` - Authentication succeeded
   - `✅ Firebase updated successfully` - Location data written

If you see errors like:

- `❌ Firebase connectivity test failed: PERMISSION_DENIED` - Rules need updating
- `❌ Error writing to Firebase: PERMISSION_DENIED` - Rules are blocking writes

## Testing the Rules

Once rules are updated, the app will automatically:

1. Test connectivity on startup
2. Attempt anonymous authentication when writing
3. Log detailed error messages if permissions are denied

Check the debug console for detailed information about what's happening with Firebase writes.
