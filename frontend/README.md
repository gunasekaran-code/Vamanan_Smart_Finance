# SmartFinance — SPA-style Flutter starter

A frontend-only Flutter app demonstrating:

- **SPA-style client-side routing** with [go_router](https://pub.dev/packages/go_router)'s
  `StatefulShellRoute` — the header and bottom nav are built **once** and stay
  mounted; only the active tab's content swaps underneath them. No full-screen
  reloads, and each tab keeps its own navigation/scroll state when you switch
  away and back.
- **Role-based access control** for four roles — `SUPERADMIN`, `ADMIN`,
  `STAFF`, `CUSTOMER` — driven by one config file, with unauthorized nav items
  hidden/disabled and unauthorized deep links redirected.
- A clean, scalable folder structure that's ready to plug a real backend into.

## Getting started

This zip ships the `lib/` source and `pubspec.yaml` only (no platform
folders), so it can drop into an existing Flutter project or become a new one:

```bash
# Option A — new project
flutter create smartfinance_app
# then replace the generated lib/ and pubspec.yaml with the ones in this zip

# Option B — inside this folder
flutter create .        # generates android/ios/web/... around the existing lib/
flutter pub get
flutter run
```

Demo accounts (no backend — any password works): `superadmin`, `admin`,
`staff`, `customer`. Sign in with one, then use the **Switch demo role** chips
on the Profile tab to see the nav/pages change live.

## Folder structure

```
lib/
  main.dart                     # MaterialApp.router entry point
  models/
    user_role.dart              # UserRole enum (SUPERADMIN/ADMIN/STAFF/CUSTOMER)
    app_user.dart                # AppUser, with a fromJson() ready for a real API
  routes/
    app_routes.dart             # path string constants
    app_router.dart             # GoRouter config: StatefulShellRoute + RBAC redirect
  services/
    session_service.dart        # mock auth/session (ChangeNotifier)
    permission_service.dart     # SINGLE SOURCE OF TRUTH for RBAC + nav entries
  theme/
    app_theme.dart              # AppColors + ThemeData
  widgets/
    app_shell.dart              # persistent Scaffold: header + drawer + bottom nav
    app_header.dart             # persistent AppBar
    app_bottom_nav.dart         # bottom tabs — disallowed items are HIDDEN
    app_drawer.dart             # side drawer — disallowed items are DISABLED
    app_page.dart               # shared content wrapper used by every tab
    stat_card.dart              # small reusable dashboard metric card
  screens/
    splash_screen.dart          # restores session, then redirects
    login_screen.dart
    unauthorized_screen.dart    # shown when a role hits a page it can't use
    not_found_screen.dart       # shown for unmatched routes
    dashboard/dashboard_screen.dart
    members/members_screen.dart
    verify/verify_screen.dart
    reports/reports_screen.dart
    profile/profile_screen.dart
```

## How the persistent layout works

`AppRouter` wraps the five tab routes in a `StatefulShellRoute.indexedStack`.
Its `builder` returns `AppShell`, which contains the real `Scaffold` — the
`AppHeader` (AppBar) and `AppBottomNav` live there, **outside** of what
changes on navigation. The `navigationShell` parameter is used as the
`Scaffold.body`; go_router swaps the active branch's Navigator inside it,
so tapping a tab never rebuilds the header or loses the other tabs' state.

```
AppRouter
 └─ StatefulShellRoute.indexedStack
     ├─ builder: (context, state, navigationShell) => AppShell(navigationShell)
     └─ branches: [dashboard], [members], [verify], [reports], [profile]

AppShell
 └─ Scaffold
     ├─ appBar: AppHeader            <- persistent
     ├─ drawer: AppDrawer            <- persistent
     ├─ body: navigationShell        <- only this part changes
     └─ bottomNavigationBar: AppBottomNav  <- persistent
```

## How role-based access control works

Everything is driven by `PermissionService.navEntries` in
`services/permission_service.dart`:

```dart
static const List<NavEntry> navEntries = [
  NavEntry(route: AppRoutes.dashboard, ..., allowedRoles: _everyone),
  NavEntry(route: AppRoutes.members,   ..., allowedRoles: _staffAndUp),
  NavEntry(route: AppRoutes.verify,    ..., allowedRoles: _staffAndUp),
  NavEntry(route: AppRoutes.reports,   ..., allowedRoles: _adminAndUp),
  NavEntry(route: AppRoutes.profile,   ..., allowedRoles: _everyone),
];
```

| Page      | Super Admin | Admin | Staff | Customer |
|-----------|:-----------:|:-----:|:-----:|:--------:|
| Dashboard | ✅ | ✅ | ✅ | ✅ |
| Members   | ✅ | ✅ | ✅ | ❌ |
| Verify    | ✅ | ✅ | ✅ | ❌ |
| Reports   | ✅ | ✅ | ❌ | ❌ |
| Profile   | ✅ | ✅ | ✅ | ✅ |

This one list feeds three things, so there's nowhere else a permission needs
to be duplicated:

1. **`AppBottomNav`** — filters to only the entries the current role can see
   (disallowed tabs are removed).
2. **`AppDrawer`** — shows every entry, but disables the ones the role can't
   open (greyed out, lock icon, "Restricted" label) — useful when you want
   people to know a feature exists without being able to use it.
3. **`AppRouter._redirect`** — on every navigation (including a typed-in URL
   or deep link on web), checks `PermissionService.canAccess(path, role)` and
   redirects to `/unauthorized` if the role isn't allowed. This is the real
   guard — the nav-hiding above is just UX polish, since a user could always
   type a URL directly.

To add a new tab: add one `NavEntry`, one `StatefulShellBranch` in
`app_router.dart`, and one screen file. Nothing else changes.

## Invalid navigation handling

- `/` redirects to `/splash`.
- Any unmatched path renders `NotFoundScreen` (`errorBuilder`).
- Unauthenticated users hitting any non-public route are sent to `/login`.
- Authenticated users hitting a route their role can't use are sent to
  `/unauthorized`.
- Authenticated users hitting `/login` are sent to their role's landing page.

## Wiring up a real backend later

- `SessionService.login()` / `restoreFromStorage()` are the two methods to
  replace with real API calls — everything else (router redirects, nav
  visibility, RBAC) already reacts to `SessionService` via `ChangeNotifier`.
- `AppUser.fromJson()` is ready to parse a login/profile response.
- `UserRole.fromApiValue()` / `.apiValue` map the enum to/from the
  `SUPERADMIN` / `ADMIN` / `STAFF` / `CUSTOMER` strings a backend would send.
- Each screen has a `// TODO:` marking where static demo data should be
  replaced with a real API call.
