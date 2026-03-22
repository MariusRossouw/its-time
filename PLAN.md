# Its Time - Task Management App

A personal TickTick-style productivity app, built incrementally from a solid foundation.

---

## Vision

A cross-platform task management and productivity app that covers: task management, calendar, habit tracking, focus timer, notes, and collaboration — all synced in real time.

---

## Feature Reference (Complete TickTick Parity List)

Everything below is what TickTick offers. We use this as our feature compass — not our Phase 1 scope.

### Task Management

#### Task Creation & Input
- [ ] Quick add button with natural placement
- [ ] Natural language parsing (e.g. "Meeting tomorrow at 3pm" auto-sets date/time)
- [ ] Voice input with smart date recognition
- [ ] Email-to-task (forward emails to create tasks)
- [ ] Browser extension (save pages as tasks)
- [ ] Global keyboard shortcut for quick-add
- [ ] Clipboard import (batch-create tasks from clipboard)
- [ ] Task templates (save & reuse task structures)
- [ ] Batch task creation (multiple tasks at once)

#### Task Properties
- [ ] Title
- [ ] Due date (single date or start + end date range)
- [ ] Time (specific time or all-day)
- [ ] Priority levels: High, Medium, Low, None
- [ ] Subtasks / checklist items (up to 5 levels of nesting)
- [ ] Description with rich text / Markdown support
- [ ] Attachments (images, files, audio)
- [ ] Tags (multiple per task, color-coded, hierarchical)
- [ ] Comments
- [ ] Activity / history log
- [ ] Progress percentage
- [ ] Pin to top
- [ ] Task links (cross-reference between tasks via URL)
- [ ] Task duplication
- [ ] Batch editing (select multiple, edit in bulk)
- [ ] Drag-and-drop reordering
- [ ] "Won't Do" status (distinct from completed)
- [ ] Reopen completed/abandoned tasks
- [ ] Convert between task and note
- [ ] Archive completed tasks

#### Recurring Tasks
- [ ] Fixed-time recurrence (daily, weekly, monthly, yearly, custom)
- [ ] Completion-based recurrence (next starts after previous completes)
- [ ] Skip a cycle without breaking the pattern
- [ ] Custom repeat rules (e.g. "every 2 weeks on Mon and Wed")

#### Reminders & Notifications
- [ ] Multiple reminders per task
- [ ] Custom reminder times (minutes/hours/days before)
- [ ] Default reminder settings for all new tasks
- [ ] Persistent/constant reminder until acknowledged
- [ ] Location-based reminders (arrive/leave geofence)
- [ ] Email reminders
- [ ] Priority-based notification sounds
- [ ] Snooze reminders
- [ ] Daily summary notification (scheduled digest)
- [ ] Countdown mode (days remaining vs. due date)

#### Triggers & Automation
- [ ] Time-based triggers (run action at specific time or relative to task due date)
- [ ] Event-based triggers (on task complete, on task create, on status change, on overdue)
- [ ] Geolocation triggers (enter/leave an area — auto-surface tasks, send reminders, check-in habits)
- [ ] Chained task triggers (completing task A auto-creates or unblocks task B)
- [ ] Conditional triggers (if priority is high AND overdue > 1 day, escalate notification)
- [ ] Recurring trigger schedules (run automation daily/weekly at set time)
- [ ] Webhook triggers (inbound — external event creates/updates a task)
- [ ] Trigger actions: notify, create task, move task, change priority, assign, add tag, start focus timer
- [ ] Trigger log / history (view what fired, when, and what it did)
- [ ] Enable / disable individual triggers

#### Notifications (Delivery Channels & Behavior)
- [ ] In-app notifications (notification center / bell icon)
- [ ] Push notifications (mobile — iOS & Android)
- [ ] Desktop notifications (system-level, web Notification API)
- [ ] Email notifications
- [ ] SMS notifications (opt-in for critical items)
- [ ] Notification grouping / batching (avoid notification fatigue)
- [ ] Quiet hours / Do Not Disturb schedule (global + per-list)
- [ ] Notification preferences per channel (choose what goes where)
- [ ] Notification history (reviewable log of past notifications)
- [ ] Badge counts (app icon, tab bar, per-list unread indicators)
- [ ] Sound customization per notification type
- [ ] Vibration patterns (mobile)
- [ ] Critical alerts that bypass DND (opt-in, for high-priority overdue items)

### Lists & Organization

#### Hierarchy
- [ ] Folders (group lists)
- [ ] Lists (primary containers)
- [ ] Sections (subdivisions within a list)
- [ ] Smart Lists (auto-populated by filter criteria)

#### Built-in Smart Lists
- [ ] Today
- [ ] Next 7 Days
- [ ] All
- [ ] Inbox (default unsorted capture)
- [ ] Assigned to Me

#### Filters & Smart Lists
- [ ] Custom smart lists with combined filters
- [ ] Filter by: list, tag, date, priority, assignee, keyword
- [ ] Multi-condition filters with AND/OR logic
- [ ] Suggested tasks (recently added, postponed, overdue, upcoming)

#### Sorting & Grouping
- [ ] Sort by: date, priority, title, list, tag, assignee, custom order
- [ ] Group by: custom, list, time, priority, assignee
- [ ] Smart sort (automatic intelligent ordering)
- [ ] Manual drag-and-drop sorting

#### Tags
- [ ] Unlimited tags
- [ ] Nested / hierarchical tags
- [ ] Tag-based filtering and search
- [ ] Color-coded tags

### Calendar & Time

#### Calendar Views
- [ ] Monthly view
- [ ] Weekly view
- [ ] 3-day view
- [ ] Daily view
- [ ] Agenda / list view

#### Calendar Features
- [ ] Time blocking (drag tasks onto time slots)
- [ ] Day/night separators in time blocks (visual sunrise/sunset dividers based on location or manual config)
- [ ] Morning / afternoon / evening / night sections with distinct styling
- [ ] Auto-adjust day/night boundaries based on geolocation + season
- [ ] Customizable timeline hours
- [ ] Quick "jump to today" navigation
- [ ] Color-coding by list, tag, or priority
- [ ] Habit display in calendar
- [ ] Focus record visualization in calendar
- [ ] Filter calendar by specific list
- [ ] Drag-and-drop rescheduling
- [ ] Calendar widgets
- [ ] Multiple time zone support (fixed vs floating)
- [ ] Configurable week start day
- [ ] Week number display
- [ ] Third-party calendar subscriptions (Google, Outlook, iCloud, CalDAV)

#### Pomodoro / Focus Timer
- [ ] Pomodoro mode (25min focus + 5min break, long break after 4 cycles)
- [ ] Stopwatch mode (open-ended count-up)
- [ ] Customizable durations
- [ ] Estimated duration / pomodoro count per task
- [ ] Estimated vs actual time comparison
- [ ] White noise / ambient sounds
- [ ] Screen always on option
- [ ] Full-screen focus mode
- [ ] Strict mode (block other apps)
- [ ] App allowlist during strict mode
- [ ] Start focus directly from any task
- [ ] Focus statistics (weekly, monthly, yearly charts)
- [ ] Manual time adjustment for missed records
- [ ] Overtime tracking
- [ ] Focus record management (view/edit past sessions)

#### Habit Tracker
- [ ] Pre-built habit gallery (60+ habits across Life, Health, Exercise, Mentality)
- [ ] Custom habit creation
- [ ] Frequency options (daily, weekly, custom schedules)
- [ ] Goal types (auto, manual, complete-all, reach a target amount)
- [ ] Cumulative habits (log multiple completions, e.g. glasses of water)
- [ ] "Achieve it all" — complete cumulative habits in one gesture
- [ ] Daily check-in interface
- [ ] Streak tracking (current + best streak)
- [ ] "Unachieved" logging (mark what you missed and why)
- [ ] Backfill forgotten check-ins
- [ ] Habit reminders
- [ ] Statistics (weekly, monthly, all-time charts)
- [ ] Punch card calendar view (visual monthly completion grid)
- [ ] Habits appear alongside tasks in Today / Next 7 Days
- [ ] Start focus sessions for habits

### Collaboration
- [ ] Shared lists (share any list with others)
- [ ] Permission levels (edit, comment, read-only)
- [ ] Invitation by email or shareable link
- [ ] Task assignment to team members
- [ ] Task comments (threaded discussion)
- [ ] Activity log (full change history)
- [ ] @mention team members in comments
- [ ] Do Not Disturb per shared list
- [ ] Group/sort by assignee

### Productivity Views
- [ ] Eisenhower Matrix (4-quadrant urgent/important grid)
  - [ ] Automatic color-coding per quadrant
  - [ ] Drag tasks between quadrants
  - [ ] Customizable placement rules
- [ ] Kanban Board
  - [ ] Column-based visualization
  - [ ] Group by: status, section, priority, assignee, list, tag, custom
  - [ ] Drag-and-drop between columns
- [ ] Timeline View (Gantt-like)
  - [ ] Tasks displayed by duration on horizontal timeline
  - [ ] Drag to adjust start times and durations

### Notes
- [ ] Standalone notes (separate from tasks, not scheduled/completable)
- [ ] Notes and tasks coexist in same list
- [ ] Bidirectional conversion between task and note
- [ ] Markdown support (15+ syntax elements)
- [ ] Rich text formatting
- [ ] Attachments in notes
- [ ] Dates, reminders, and tags on notes

### Reports & Summaries
- [ ] Task summary / report generation
- [ ] Filter summaries by list, tag, or date range
- [ ] Export / share / print summaries

### Integrations
- [ ] Google Calendar (bidirectional sync)
- [ ] Outlook Calendar sync
- [ ] iCloud Calendar sync
- [ ] CalDAV subscriptions
- [ ] Gmail add-on
- [ ] Outlook add-in
- [ ] Email forwarding to create tasks
- [ ] Siri / Apple Shortcuts
- [ ] Alexa skill
- [ ] Google Assistant
- [ ] Zapier / IFTTT / automation platforms
- [ ] Slack integration
- [ ] REST API (OAuth 2.0)
- [ ] URL scheme / deep linking
- [ ] Webhooks

### Platform Support
- [ ] Web app (PWA)
- [ ] iOS app
- [ ] Android app
- [ ] macOS desktop app
- [ ] Windows desktop app
- [ ] Linux desktop app
- [ ] Apple Watch app
- [ ] Browser extensions (Chrome, Firefox, Edge, Safari)
- [ ] Real-time cross-platform sync
- [ ] Offline mode with sync-on-reconnect

### Settings & Customization
- [ ] Themes (light, dark, custom)
- [ ] Font size adjustment
- [ ] App icon badge count
- [ ] Customizable tab bar / navigation
- [ ] Custom notification sounds
- [ ] Priority-based notification differentiation
- [ ] Default list for new tasks
- [ ] Default date for new tasks
- [ ] Default priority
- [ ] Default reminder
- [ ] Smart recognition toggle (NLP on/off)
- [ ] Customizable swipe actions
- [ ] Keyboard shortcuts
- [ ] Command palette
- [ ] Week start day configuration
- [ ] Time zone mode (fixed vs floating)
- [ ] 12h / 24h time format
- [ ] Account management (password, deletion, backup/restore)
- [ ] Achievement / gamification system

---

## Design Direction

> Full research in [DESIGN-RESEARCH.md](DESIGN-RESEARCH.md) — analysis of TickTick, Any.do, NotePlan, Notion, and Due.

**Aesthetic:** "Warm minimalism" — off-white backgrounds (not clinical white), muted color palette, blue accent, feels inviting not sterile.

**Layout:** Adaptive three-column using `NavigationSplitView`
- **iPhone:** Tab bar (Today, Tasks, Calendar, Focus, More) + navigation stack
- **iPad:** Collapsible sidebar + content, optional detail pane
- **Mac:** Full three-column (sidebar + list + detail) with resizable panes

**Key Design Principles (ranked):**
1. Speed of capture — task from head to app in under 3 seconds
2. Glanceability — see what matters today in under 2 seconds
3. Progressive disclosure — simple surface, powerful underneath
4. Native feel — system controls, Dynamic Type, Dark Mode, accessibility from day one
5. Warm and personal — not corporate, this is your space

**Borrowed from each reference app:**
- **TickTick:** Multi-view switcher (list, kanban, calendar, matrix), priority-colored checkboxes
- **Any.do:** Daily planner merging tasks + calendar events, Apple-native feel
- **NotePlan:** Markdown-first content, command palette, deep theming
- **Notion:** Warm off-white backgrounds, muted earthy palette, block-style flexibility
- **Due:** Quick date buttons for rapid scheduling, persistent nagging reminders

---

## Architecture Decisions

### Storage: Local-First with GitHub Sync (BYO Repo)
No backend server. No shared infrastructure. Each user/household/group provides their own private GitHub repo.

**Ownership model:**
- Every user (or household/group) creates their own private GitHub repo
- Every user generates their own GitHub personal access token (fine-grained, scoped to their repo only)
- The app has zero central servers, zero shared API keys, zero shared rate limits
- A household can share one repo for shared task lists; individuals use their own
- GitHub's 5,000 req/hr rate limit applies per-user, so each person has their own quota

**How it works:**
- All data lives on-device (SwiftData on Apple, SQLite on Android/Windows)
- Data is serialized to a portable format (JSON files) in a known directory structure
- The app commits and pushes changes to the user's own private GitHub repo, and pulls from it
- Git handles history, versioning, and acts as the sync transport layer

**Data directory structure in the sync repo:**
```
data/
├── tasks/
│   ├── {uuid}.json          # one file per task (includes subtasks inline)
│   └── ...
├── lists/
│   ├── {uuid}.json          # list metadata, section definitions, task ordering
│   └── ...
├── folders/
│   ├── {uuid}.json          # folder metadata, list ordering
│   └── ...
├── tags/
│   └── tags.json            # all tags in one file (small dataset)
├── habits/
│   ├── {uuid}.json          # habit definition + check-in log
│   └── ...
├── notes/
│   ├── {uuid}.json          # standalone notes
│   └── ...
├── focus/
│   └── sessions.json        # focus/pomodoro session log
├── triggers/
│   ├── {uuid}.json          # trigger definitions
│   └── ...
├── settings/
│   └── preferences.json     # user preferences, defaults, theme
└── sync_meta.json            # last sync timestamp, device ID, conflict markers
```

**Key considerations:**
- **Conflict resolution:** File-per-entity means most edits won't conflict. When they do, use last-write-wins with a merge strategy (timestamp-based). Keep both versions in conflict cases for manual resolution.
- **Sync frequency:** On app launch, on app background/foreground, and on manual pull-to-refresh. Debounce rapid edits (batch commits every ~30s of idle).
- **GitHub auth:** User's own personal access token (fine-grained, scoped to their repo only) stored in device Keychain.
- **Offline-first:** App is fully functional offline. Changes queue locally and sync when connectivity returns.
- **Schema versioning:** Include a `schema_version` field in every JSON file. Migration logic runs on read if version is outdated.
- **Privacy:** Data only ever goes to the user's own private repo. The app itself has no server, no analytics, no telemetry.
- **Sharing / household use:** Multiple people can sync to the same repo for shared lists. Each person adds the repo on their device with their own GitHub token.

### Platform Strategy: 100% Native Per Platform

| Platform | Tech | Folder | Targets |
|----------|------|--------|---------|
| **Apple** | Swift + SwiftUI + SwiftData | `/apple/` | iOS, iPadOS, macOS (Apple Silicon) — single multiplatform app |
| **Android** | Kotlin + Jetpack Compose | `/android/` | Phones & tablets |
| **Windows** | WinUI 3 / .NET MAUI | `/windows/` | Windows 10/11 desktop |

**Apple app — fully native, zero third-party UI frameworks:**
- **Language:** Swift (Apple's native language)
- **UI:** SwiftUI (Apple's native declarative UI framework)
- **Data:** SwiftData (Apple's native persistence, successor to Core Data)
- **Notifications:** UserNotifications framework (Apple native)
- **Location:** Core Location (Apple native geofencing)
- **Calendar:** EventKit (Apple native calendar integration)
- **Security:** Keychain Services (Apple native secure storage)
- **Build:** Xcode, single multiplatform target → compiles to iPhone, iPad, and Mac (Apple Silicon)
- No React Native, no Flutter, no Electron, no web views

**Why native per platform (not cross-platform)?**
- Best performance and UX on each platform
- Full access to platform APIs (widgets, notifications, shortcuts, Keychain, geofencing)
- SwiftUI multiplatform already covers 3 Apple devices in one codebase
- The shared data format (JSON + Git sync) is the cross-platform layer — not the UI

### Shared Across All Platforms
- **Data schema:** Identical JSON structures defined once in `/shared/schema/`
- **Sync logic spec:** Git operations documented in `/shared/sync-protocol.md`
- **Test fixtures:** Shared test data in `/shared/fixtures/`

### Repo Structure
```
its-time/
├── PLAN.md                   # this file
├── shared/
│   ├── schema/               # canonical JSON schemas for all entities
│   │   ├── task.schema.json
│   │   ├── list.schema.json
│   │   ├── folder.schema.json
│   │   ├── tag.schema.json
│   │   ├── habit.schema.json
│   │   ├── note.schema.json
│   │   ├── trigger.schema.json
│   │   ├── focus-session.schema.json
│   │   └── preferences.schema.json
│   ├── sync-protocol.md      # how sync works (commit, push, pull, conflict resolution)
│   └── fixtures/             # test data for all platforms
├── apple/                    # SwiftUI multiplatform app
│   └── ItsTime/
│       ├── ItsTime.xcodeproj
│       ├── Shared/           # shared Swift code (models, sync, logic)
│       ├── iOS/              # iOS/iPadOS-specific views & assets
│       └── macOS/            # macOS-specific views & assets
├── android/                  # Kotlin + Jetpack Compose (future)
│   └── ...
└── windows/                  # WinUI 3 / .NET MAUI (future)
    └── ...
```

---

## Phased Build Plan

> Starting with the Apple app. Android and Windows come later.

### Phase 1 — Foundation (Apple MVP)
**Goal:** Core task management running on iPhone, iPad, and Mac from a single SwiftUI codebase.

**Tech Stack:**
- SwiftUI multiplatform (iOS 17+, macOS 14+)
- SwiftData for local persistence
- Git sync via GitHub REST API (or libgit2/swift-git wrapper)
- Keychain for GitHub token storage

**Features:**
- [ ] Define shared JSON schemas (`/shared/schema/`)
- [ ] Scaffold SwiftUI multiplatform Xcode project
- [ ] SwiftData models (Task, List, Folder, Tag)
- [ ] Inbox — default task capture
- [ ] Task CRUD (create, read, update, delete)
- [ ] Task properties: title, description, due date, time, priority
- [ ] Lists — create, rename, delete, reorder
- [ ] Move tasks between lists
- [ ] Task completion (mark done / undo / won't do)
- [ ] Basic sorting (by date, priority, manual drag-and-drop)
- [ ] In-app notifications (local notifications for reminders)
- [ ] Adaptive UI (iPhone compact, iPad sidebar + detail, Mac full window)
- [ ] Settings screen (basic preferences)

### Phase 2 — GitHub Sync & Organization
**Goal:** Data syncs across devices. Richer task organization.

- [ ] Document sync protocol (`/shared/sync-protocol.md`)
- [x] JSON serialization/deserialization of all models
- [x] GitHub sync engine (commit, push, pull via GitHub API)
- [x] GitHub token setup flow (onboarding, keychain storage)
- [x] Conflict detection & resolution (last-write-wins + manual merge)
- [x] Sync status indicator in UI
- [x] Subtasks / checklist items (nested, up to 5 levels)
- [x] Tags (create, assign, color-code, filter by)
- [x] Sections within lists
- [x] Folders (group lists)
- [x] Search (full-text across tasks)
- [x] Batch editing (select multiple, bulk actions)
- [x] Task descriptions with Markdown rendering

### Phase 3 — Recurring Tasks & Reminders
**Goal:** Time-aware task management.

- [x] Recurring tasks (daily, weekly, monthly, yearly, custom rules)
- [x] Completion-based recurrence
- [x] Skip a cycle without breaking the pattern
- [x] Multiple reminders per task (local notifications)
- [x] Default reminder settings
- [x] Snooze reminders
- [x] Daily summary notification (scheduled digest)
- [x] Notification preferences & quiet hours
- [x] Badge counts on app icon

### Phase 4 — Calendar & Time Blocking
**Goal:** Visual scheduling and focus tools.

- [x] Calendar views (monthly, weekly, daily, agenda)
- [x] Time blocking (drag tasks onto time slots)
- [x] Day/night separators (sunrise/sunset visual dividers)
- [x] Morning / afternoon / evening / night section styling
- [x] Drag-and-drop rescheduling
- [x] Start + end dates (duration tasks)
- [x] Pomodoro / focus timer (pomodoro + stopwatch modes)
- [x] Customizable timer durations
- [x] Focus statistics (charts)
- [ ] White noise / ambient sounds during focus
- [x] EventKit integration (show Apple Calendar events alongside tasks)

### Phase 5 — Habits & Notes
**Goal:** Expand beyond tasks.

- [x] Habit tracker (create, daily check-in, streaks, stats)
- [x] Habit gallery with pre-built templates
- [x] Cumulative habits (e.g. glasses of water)
- [x] Habit reminders
- [x] Punch card calendar view
- [x] Standalone notes with Markdown
- [x] Notes and tasks coexist in lists
- [x] Convert between task and note
- [ ] Attachments (images, files via system share sheet)

### Phase 6 — Views & Productivity
**Goal:** Multiple ways to see and manage work.

- [x] Smart Lists / custom filters (AND/OR logic)
- [x] Built-in smart lists (Today, Next 7 Days, All, Inbox)
- [x] Eisenhower Matrix view
- [x] Kanban board view
- [x] Timeline / Gantt view
- [x] Suggested tasks (overdue, postponed, upcoming)
- [x] Widgets (iOS home screen, iPadOS, macOS notification center)

### Phase 7 — Triggers & Automation
**Goal:** Smart triggers that act on your behalf.

- [x] Time-based triggers (fire action at specific time or relative to due date)
- [x] Event-based triggers (on task complete, create, status change, overdue)
- [x] Geolocation triggers (Core Location — enter/leave area)
- [x] Chained task triggers (completing A unblocks or creates B)
- [x] Conditional triggers (combine conditions with AND/OR)
- [x] Trigger actions: notify, create task, move, change priority, tag, start timer
- [x] Trigger log / history
- [x] Apple Shortcuts integration (expose actions to Shortcuts app)
- [x] Siri integration

### Phase 8 — Collaboration
**Goal:** Multi-user via shared GitHub repos.

- [x] Shared lists (invite others to a shared sync repo or branch)
- [x] Task assignment
- [x] Comments on tasks (threaded)
- [x] Activity log / change history (derived from git log)
- [x] Assigned to Me smart list
- [x] Conflict resolution UI for multi-user edits

### Phase 9 — Polish & Power Features
**Goal:** Delight and retain.

- [ ] Natural language input parsing
- [ ] Themes (light, dark, system, custom accent colors)
- [ ] Keyboard shortcuts (Mac) & command palette
- [ ] Customizable swipe actions (iOS)
- [x] Location-based reminders (arrive/leave geofence)
- [x] Auto-adjust day/night separators by geolocation + season
- [ ] Achievement / gamification system
- [ ] Reports & summaries with export
- [ ] Data management (backup, restore, export to JSON)
- [ ] Apple Watch companion app

### Phase 10 — Android App
**Goal:** Bring the full experience to Android.

- [ ] Scaffold Kotlin + Jetpack Compose project in `/android/`
- [ ] Implement shared data models from JSON schemas
- [ ] GitHub sync engine (Kotlin)
- [ ] Port all features phases 1–9
- [ ] Material You theming
- [ ] Android widgets
- [ ] Wear OS companion (stretch)

### Phase 11 — Windows App
**Goal:** Desktop experience for Windows users.

- [ ] Scaffold WinUI 3 / .NET MAUI project in `/windows/`
- [ ] Implement shared data models from JSON schemas
- [ ] GitHub sync engine (.NET)
- [ ] Port all features phases 1–9
- [ ] Windows notification integration
- [ ] Taskbar/system tray integration

---

## Current Status

**Phase:** Phase 8 complete — Collaboration
**Next Step:** Phase 9 — Polish & Power Features (NLP input, themes, keyboard shortcuts, gamification)

---

## Decisions Log

| Date | Decision | Notes |
|------|----------|-------|
| 2026-03-21 | Created project plan | Comprehensive feature reference based on TickTick analysis |
| 2026-03-21 | Local-first + GitHub sync | No backend server. JSON files in a private GitHub repo as sync layer |
| 2026-03-21 | Native per platform | SwiftUI (Apple), Kotlin (Android), WinUI/.NET (Windows) |
| 2026-03-21 | Apple first | Single SwiftUI multiplatform app for iOS, iPadOS, macOS (Apple Silicon) |
| 2026-03-21 | Repo structure | `/shared/`, `/apple/`, `/android/`, `/windows/` |
| 2026-03-21 | App name | "Its Time" confirmed |
| 2026-03-21 | Design direction | "Warm minimalism" — inspired by TickTick, Any.do, NotePlan, Notion, Due. See DESIGN-RESEARCH.md |
| 2026-03-21 | Sync repo | github.com/MariusRossouw/its-time-sync |

---

## Key Risks & Open Questions

| Risk / Question | Notes |
|-----------------|-------|
| **GitHub API rate limits** | 5,000 req/hr per user (each person has their own token + quota). No shared bottleneck. Batch operations to minimize calls. |
| **Git sync performance** | Large repos with thousands of task files could slow down. Mitigate: shallow clone, sparse checkout, or only sync changed files via API. |
| **Conflict resolution UX** | Need a clear UI for when two devices edit the same task offline. Start with last-write-wins, add manual merge later. |
| **GitHub token management** | Fine-grained PAT stored in keychain. Need a smooth onboarding flow. Consider GitHub OAuth device flow for better UX. |
| **Offline sync queue** | Must queue commits when offline and replay them on reconnect. Order matters. |
| **SwiftUI maturity** | Some advanced views (Kanban, Gantt) may need UIKit/AppKit bridging. Evaluate per-feature. |
| **File-per-entity scaling** | 10,000+ tasks = 10,000+ files. Git handles this but sync could be slow. May need to batch small entities. |

---

## Notes

- Each phase should result in a shippable, usable increment
- Prioritize features that make the app useful for personal daily use first
- The shared JSON schema is the contract between platforms — define it carefully
- Collaboration and cross-platform come after the Apple app is solid
- Keep the architecture extensible — the feature list is long but we're building incrementally
