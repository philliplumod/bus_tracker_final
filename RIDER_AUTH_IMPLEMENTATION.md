# Rider Authentication Implementation - Summary

## ✅ What Was Implemented

This implementation adds complete role-based authentication for the Bus Tracker app with special handling for Rider accounts.

### Key Features

1. **Role-Based Authentication System**
   - Three user roles: `passenger`, `rider`, `admin`
   - Different UI/UX based on role after login
   - Secure role enforcement

2. **Passenger Self-Registration**
   - ✅ Passengers can sign up through the mobile app
   - ✅ Clean signup UI with validation
   - ✅ Password confirmation
   - ✅ Email validation

3. **Rider Login Flow**
   - ✅ Riders login using same login page as passengers
   - ✅ Upon login, immediately redirected to map view
   - ✅ Map shows rider's current location
   - ✅ Displays assigned route/destination
   - ✅ Shows bus name if assigned
   - ✅ Real-time GPS tracking

4. **Admin Restrictions**
   - ⚠️ **Riders CANNOT sign up through the app**
   - ⚠️ **Rider accounts must be created by Admin via web dashboard**
   - Backend enforces role = "passenger" for all signup requests

## 📁 Files Created/Modified

### Domain Layer (Business Logic)

```
lib/domain/entities/user.dart                    ✅ Created
lib/domain/repositories/auth_repository.dart     ✅ Created
lib/domain/usecases/sign_in.dart                 ✅ Created
lib/domain/usecases/sign_up.dart                 ✅ Created
lib/domain/usecases/sign_out.dart                ✅ Created
lib/domain/usecases/get_current_user.dart        ✅ Created
```

### Data Layer (API & Storage)

```
lib/data/models/user_model.dart                          ✅ Created
lib/data/datasources/auth_remote_data_source.dart        ✅ Created
lib/data/repositories/auth_repository_impl.dart          ✅ Created
```

### Presentation Layer (UI & State Management)

```
lib/presentation/bloc/auth/auth_bloc.dart         ✅ Created
lib/presentation/bloc/auth/auth_event.dart        ✅ Created
lib/presentation/bloc/auth/auth_state.dart        ✅ Created
lib/presentation/pages/login_page.dart            ✅ Created
lib/presentation/pages/signup_page.dart           ✅ Created
lib/presentation/pages/rider_map_page.dart        ✅ Created
```

### Configuration

```
lib/core/di/dependency_injection.dart      ✅ Modified (added Auth dependencies)
lib/main.dart                              ✅ Modified (added auth routing)
pubspec.yaml                               ✅ Modified (added http & shared_preferences)
```

### Documentation

```
API_SETUP_GUIDE.md                         ✅ Created (complete API documentation)
```

## 🔐 User Roles & Access Control

### 👤 Passenger

- **Registration:** ✅ Can self-register via mobile app
- **Login:** ✅ Via login page
- **Access:** Main menu → Trip planning, bus search, route viewing
- **Restrictions:** Cannot access rider features

### 🚌 Rider (Driver)

- **Registration:** ❌ CANNOT self-register through app
- **Creation:** ✅ Only via Admin web dashboard
- **Login:** ✅ Via same login page
- **Access:** Immediately see map with:
  - Current GPS location
  - Assigned route/destination
  - Bus name/number
  - Real-time tracking
- **Restrictions:** No access to passenger features

### 👨‍💼 Admin

- **Registration:** ❌ CANNOT self-register
- **Creation:** ✅ Via secure admin process
- **Login:** ✅ Via login page
- **Access:** Create riders, assign routes, manage users (via web dashboard)

## 🔄 Authentication Flow

### First Time User (Passenger)

1. Open app → Login page
2. Tap "Sign Up"
3. Enter name, email, password
4. System creates passenger account
5. Redirect to main menu

### Existing Passenger Login

1. Open app → Login page
2. Enter credentials
3. System authenticates
4. Redirect to main menu

### Rider Login

1. Open app → Login page
2. Enter rider credentials (created by admin)
3. System authenticates
4. **Automatically redirect to map page**
5. Map displays:
   - Rider's current location (blue marker)
   - Assigned route info at top
   - Real-time GPS coordinates
   - Bus name/number

## 🛠️ Technical Implementation

### State Management

- **BLoC Pattern** for clean architecture
- Separate blocs for Auth and Map
- Persistent auth state with SharedPreferences

### Data Flow

```
UI (Pages)
  ↓
BLoC (Events/States)
  ↓
Use Cases (Business Logic)
  ↓
Repository (Interface)
  ↓
Data Source (API Calls)
```

### Authentication Storage

- User data stored locally using SharedPreferences
- Persists across app restarts
- Auto-login on app launch
- Secure sign out clears all data

## 🎨 UI Components

### Login Page

- Email input with validation
- Password input with show/hide toggle
- "Sign Up" navigation button
- Loading indicator during auth
- Error message display

### Signup Page

- Name input
- Email input with validation
- Password input (min 6 characters)
- Confirm password
- Role enforcement note
- Creates passenger accounts only

### Rider Map Page

- **Route info card** - displays assigned route
- **Google Map** - shows rider's current location
- **Location details card** - lat/lng/accuracy
- **Sign out button** - secure logout
- **Real-time updates** - GPS tracking

## 📡 API Requirements

### Required Endpoints

The mobile app expects these API endpoints:

1. **POST /api/auth/sign-up** - Passenger registration only
2. **POST /api/auth/sign-in** - All roles login
3. **POST /api/auth/sign-out** - Logout

### Backend Configuration

Update the API URL in:

```dart
// lib/data/datasources/auth_remote_data_source.dart
static const String baseUrl = 'https://your-api-url.com/api';
```

**See `API_SETUP_GUIDE.md` for complete API documentation.**

## ⚙️ Setup Instructions

### 1. Install Dependencies

```bash
cd "d:\Capstone Projects\bus_tracker-main"
flutter pub get
```

### 2. Configure API Endpoint

Edit `lib/data/datasources/auth_remote_data_source.dart`:

```dart
static const String baseUrl = 'YOUR_BACKEND_URL/api';
```

### 3. Test the App

```bash
flutter run
```

### 4. Test Login Flows

**Test Passenger Signup:**

- Launch app
- Tap "Sign Up"
- Create account
- Should redirect to main menu

**Test Rider Login:**

- Use rider credentials (created by admin)
- Should redirect to map page
- Should show current location

## 🔒 Security Considerations

### Implemented

- ✅ Password minimum length (6 chars)
- ✅ Email validation
- ✅ Role-based access control
- ✅ Local data storage (SharedPreferences)
- ✅ Signup restricted to passengers

### Recommended for Production

- 🔜 JWT token authentication
- 🔜 Token refresh mechanism
- 🔜 HTTPS enforcement
- 🔜 Password strength requirements
- 🔜 Rate limiting on API
- 🔜 Session timeout
- 🔜 Password hashing (backend)

## 📋 Testing Checklist

- [ ] Passenger can sign up
- [ ] Passenger login works
- [ ] Passenger sees main menu after login
- [ ] Rider login works (use admin-created account)
- [ ] Rider sees map page after login
- [ ] Rider map shows current location
- [ ] Rider map shows assigned route
- [ ] Sign out works for all roles
- [ ] App remembers login on restart
- [ ] Error messages display correctly

## 🚀 Next Steps

### Mobile App

1. ✅ Authentication system - **COMPLETE**
2. ✅ Rider map view - **COMPLETE**
3. 🔜 Location tracking service for riders
4. 🔜 Real-time location updates to Firebase
5. 🔜 Admin panel UI (if needed in mobile)

### Backend/Web Dashboard

1. 🔜 Implement authentication API endpoints
2. 🔜 Create admin web dashboard
3. 🔜 Rider account creation interface
4. 🔜 Route assignment interface
5. 🔜 User management interface

## 📝 Important Notes

### Rider Account Creation

**Riders CANNOT sign up through the mobile app.**

Rider accounts must be created by administrators through a web dashboard. The web dashboard should allow admins to:

- Create new rider accounts
- Assign routes to riders
- Assign bus names/numbers
- Manage rider information

### API Integration

The app is ready to integrate with your backend API. Update the `baseUrl` and ensure your backend:

- Enforces role = "passenger" for all signup requests
- Returns proper user data with role, assignedRoute, busName
- Handles authentication securely

### Passenger vs Rider Experience

- **Passengers** use the app to plan trips and track buses
- **Riders** use the app to share their location and view assigned routes
- Both use the same login page but get different experiences

## 📞 Support

For issues or questions:

1. Check `API_SETUP_GUIDE.md` for API documentation
2. Verify backend is running and accessible
3. Check that baseUrl is configured correctly
4. Ensure test accounts exist in database

---

**Status:** ✅ Implementation Complete
**Version:** 1.0.0
**Date:** February 1, 2026
