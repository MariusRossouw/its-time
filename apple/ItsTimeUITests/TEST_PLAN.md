# Its Time — Comprehensive UI Test Plan

This document catalogs every testable flow in the app. Each test has a unique ID, status, and description. Update status as tests are implemented.

**Status key:** `[ ]` = not started, `[x]` = implemented & passing

---

## 1. Onboarding (OnboardingUITests — 5/5)

- [x] `OB-01` — Fresh launch shows onboarding (no current user → OnboardingView displayed)
- [x] `OB-02` — Name is required (Get Started button disabled when name empty)
- [x] `OB-03` — Color picker selection (tap a color → checkmark moves)
- [x] `OB-04` — Complete onboarding (enter name → tap Get Started → main app appears)
- [x] `OB-05` — Onboarding creates current user (profile created → main app visible, no onboarding)

---

## 2. Quick Add Task (QuickAddTaskUITests — 8/8)

- [x] `QA-01` — Open quick add sheet (tap + button on Today/Tasks tab)
- [x] `QA-02` — Create task with title only (type title → tap Add → task appears in Inbox)
- [x] `QA-03` — Add button disabled when title empty
- [x] `QA-04` — Set due date via quick date buttons (Today / Tomorrow / Next Week)
- [x] `QA-05` — Set due date via date picker (Pick Date → choose date)
- [x] `QA-06` — Set priority (tap priority menu → select High)
- [x] `QA-07` — Set target list (tap list menu → select a user list)
- [x] `QA-08` — Cancel quick add (tap Cancel → sheet dismissed, no task created)

---

## 3. Quick Add Note (QuickAddNoteUITests — 3/3)

- [x] `QN-01` — Open quick add note sheet (tap + menu → New Note)
- [x] `QN-02` — Create note with title (type title → tap Add → note appears)
- [x] `QN-03` — Cancel note creation

---

## 4. Today View (TodayViewUITests — 9/12)

- [x] `TV-01` — Today tab shows tasks due today
- [x] `TV-02` — Today shows empty state when no tasks
- [x] `TV-03` — Swipe to complete a task
- [x] `TV-04` — Tap task navigates to task detail
- [x] `TV-05` — Show/hide completed toggle exists
- [x] `TV-06` — Inbox tasks with no date appear in Today view
- [x] `TV-07` — Today view navigation bar exists
- [x] `TV-08` — Inbox shows more than 5 tasks (cap removed)
- [x] `TV-09` — Inbox DisclosureGroup shows count when many tasks
- [ ] `TV-10` — Habits section shows today's habits with inline check-in
- [ ] `TV-11` — Hierarchical tasks display with expand/collapse
- [ ] `TV-12` — Child tasks are filtered from top-level lists

---

## 5. Task Lists & Smart Lists (TaskListsUITests — 12/12)

- [x] `TL-01` — Navigate to Inbox smart list
- [x] `TL-02` — Navigate to Today smart list
- [x] `TL-03` — Navigate to Next 7 Days smart list
- [x] `TL-04` — Navigate to All smart list
- [x] `TL-05` — Navigate to Assigned to Me smart list
- [x] `TL-06` — Create a new list (Lists section → New List → type name → Create)
- [x] `TL-07` — Navigate to a user-created list
- [x] `TL-08` — Smart Lists content exists (all 5 items visible)
- [x] `TL-09` — Views content exists (Suggested, Matrix, Kanban, Timeline)
- [x] `TL-10` — Navigate to Suggested view
- [x] `TL-11` — Navigate to Matrix view
- [x] `TL-12` — Navigate to Kanban view

---

## 6. Task Detail (TaskDetailUITests — 25/33)

> **Note:** TaskDetailView was redesigned in March 2026 to use a rich header card
> (status, priority, title, assignment, date, list, tags always visible) with 4 tabs
> (Notes, Children, Subtasks, Activity) and a "More Options" overflow sheet.
> Tests marked with ⚠️ may need UI test updates for the new layout.

**Header card (always visible):**
- [x] `TD-01` — Tap task → detail view opens with title field
- [x] `TD-02` — Edit task title
- [x] `TD-03` — Status picker exists (now a Menu pill in header) ⚠️
- [x] `TD-04` — Priority picker exists (now a Menu badge in header) ⚠️
- [x] `TD-05` — Due Date tappable in header opens date editor sheet ⚠️
- [x] `TD-07` — List picker is reachable (now a Menu in header) ⚠️
- [x] `TD-25` — Parent task picker exists (now in More Options sheet) ⚠️
- [x] `TD-26` — Child task shows parent breadcrumb in detail

**Tab: Notes**
- [x] `TD-12` — Description/notes section exists

**Tab: Children**
- [x] `TD-23` — Child Tasks section exists with add field
- [x] `TD-24` — Add child task inline creates it
- [ ] `TD-27` — Link existing task/note as child
- [ ] `TD-28` — Link habit as child
- [ ] `TD-29` — Unlink child task via swipe

**Tab: Subtasks**
- [x] `TD-10` — Subtasks section with add field exists
- [x] `TD-11` — Add subtask field works (type text)

**Tab: Activity**
- [x] `TD-13` — Activity & Comments navigation link exists
- [x] `TD-14` — Activity & Comments link reachable from description section
- [x] `TD-15` — Info section shows created/updated dates
- [x] `TD-16` — Navigate to unified Activity view (comments + events)
- [x] `TD-17` — Navigate to Activity view
- [ ] `TD-30` — Activity log records status change
- [ ] `TD-31` — Activity log records tag add/remove
- [ ] `TD-32` — Activity log records child add/remove

**More Options sheet (toolbar ⋯):**
- [x] `TD-06` — Start Date toggle exists (now in More Options) ⚠️
- [x] `TD-08` — Reminders section exists when due date set (now in More Options) ⚠️
- [x] `TD-09` — Location Reminder section exists (now in More Options) ⚠️
- [ ] `TD-19` — Convert task to note (now in More Options)
- [x] `TD-20` — Nudge toggle exists (now in More Options) ⚠️
- [x] `TD-21` — Nudge toggle coexists with due-date reminders (now in More Options) ⚠️
- [x] `TD-22` — Remind Me section exists with toggle (now in More Options) ⚠️
- [ ] `TD-33` — Recurrence picker exists in More Options
- [x] `TD-18` — Due Date and Start Date toggles coexist (now in separate locations) ⚠️

---

## 7. Notes (NotesUITests — 7/7)

- [x] `NE-01` — Open note → NoteEditorView displayed
- [x] `NE-02` — Note title field exists
- [x] `NE-03` — Note has content area
- [x] `NE-04` — Note toolbar has buttons
- [x] `NE-05` — Note appears in search
- [x] `NE-06` — Note appears in Inbox
- [x] `NE-07` — Quick add note cancel works

---

## 8. Subtasks (SubtasksUITests — 8/8)

- [x] `ST-01` — Add subtask field exists in task detail
- [x] `ST-02` — Type text into add subtask field
- [x] `ST-03` — Submit subtask creates it via return key
- [x] `ST-04` — Subtask field has placeholder text
- [x] `ST-05` — Subtask plus icon / section exists
- [x] `ST-06` — Subtask notes toggle button exists
- [x] `ST-07` — Tap notes toggle expands notes field
- [x] `ST-08` — Type text into subtask notes field

---

## 9. Tags (TagsUITests — 5/5)

- [x] `TG-01` — Tag manager opens from Tasks menu
- [x] `TG-02` — Create new tag from tag manager
- [x] `TG-03` — Tag appears in list after creation
- [x] `TG-04` — Tag manager Done button dismisses
- [x] `TG-05` — Add tag button exists in task detail

---

## 10. Recurrence (RecurrenceUITests — 4/4)

- [x] `RC-01` — Repeat picker exists in task detail
- [x] `RC-02` — Default recurrence is None
- [x] `RC-03` — Recurrence section visible
- [x] `RC-04` — Based on completion toggle area reachable

---

## 11. Calendar Views (CalendarUITests — 10/10)

- [x] `CV-01` — Navigate to Calendar tab
- [x] `CV-02` — Switch between Month / Week / Day / Agenda modes
- [x] `CV-03` — Monthly: navigate forward/backward months
- [x] `CV-04` — Monthly view shows calendar content
- [x] `CV-05` — Today button exists in Calendar toolbar
- [x] `CV-06` — Calendar has mode picker
- [x] `CV-07` — Switch to Week mode
- [x] `CV-08` — Switch to Day mode
- [x] `CV-09` — Switch to Agenda mode
- [x] `CV-10` — Calendar tab is accessible

---

## 12. Focus Timer (FocusTimerUITests — 9/9)

- [x] `FT-01` — Navigate to Focus tab
- [x] `FT-02` — Start Pomodoro timer (tap play)
- [x] `FT-03` — Pause timer (tap pause)
- [x] `FT-04` — Reset timer (tap reset)
- [x] `FT-05` — Skip to next session (tap forward)
- [x] `FT-06` — Switch to Stopwatch mode
- [x] `FT-07` — Link a task button exists
- [x] `FT-08` — Timer display shows time in MM:SS format
- [x] `FT-09` — Focus stats button exists

---

## 13. Habits (HabitsUITests — 6/6, HabitDetailUITests — 6/6)

- [x] `HB-01` — Navigate to Habits
- [x] `HB-02` — Empty state shows when no habits
- [x] `HB-03` — Plus menu exists with New Habit
- [x] `HB-04` — Browse Gallery option exists
- [x] `HB-05` — Create new habit (tap + → fill form → name field appears)
- [x] `HB-06` — Habits tab is accessible
- [x] `HB-07` — Navigate to habit detail (shows habit name as title)
- [x] `HB-08` — Check-in button exists in habit detail
- [x] `HB-09` — Habit detail shows stats cards (Current, Best, Total)
- [x] `HB-10` — Edit habit opens from detail menu
- [x] `HB-11` — Archive option exists in detail menu
- [x] `HB-12` — Punch card section exists

---

## 14. Chat (ChatUITests — 8/8)

- [x] `CH-01` — Navigate to Chat tab/section
- [x] `CH-02` — General channel appears in channel list
- [x] `CH-03` — Tap channel → ChatRoomView opens
- [x] `CH-04` — Type and send a message
- [x] `CH-05` — Send button disabled when empty
- [x] `CH-06` — Chat reachable via More tab
- [x] `CH-07` — Chat room has compose bar elements
- [x] `CH-08` — Chat room has message input field

---

## 15. Collaboration (CollaborationUITests — 12/12)

- [x] `CL-01` — Open Collaborators manager
- [x] `CL-02` — Current user profile shows
- [x] `CL-03` — "You" badge shows for current user
- [x] `CL-04` — Add collaborator button exists
- [x] `CL-05` — Add collaborator opens editor
- [x] `CL-06` — Editor has name field
- [x] `CL-07` — Editor has email field
- [x] `CL-08` — Save disabled when fields empty
- [x] `CL-09` — Create collaborator with name
- [x] `CL-10` — Back button navigates away from collaborators
- [x] `CL-11` — Unified Activity & Comments view accessible from task detail
- [x] `CL-12` — Activity view accessible from task detail

---

## 16. Sync Profiles (SyncProfilesUITests — 7/7)

- [x] `SP-01` — Navigate to Settings > Sync Profiles
- [x] `SP-02` — Empty state description shows
- [x] `SP-03` — Add Sync Profile button exists
- [x] `SP-04` — Tap Add opens new profile form
- [x] `SP-05` — New profile form has name and repo fields
- [x] `SP-06` — Create button disabled when fields empty
- [x] `SP-07` — Cancel button exists and works

---

## 17. Settings (SettingsUITests — 15/15)

- [x] `SE-01` — Navigate to Settings tab
- [x] `SE-02` — Theme picker exists
- [x] `SE-03` — Week Starts On picker exists
- [x] `SE-04` — Time Format picker exists
- [x] `SE-05` — Default Priority picker exists
- [x] `SE-06` — Focus timer steppers exist
- [x] `SE-07` — Daily Summary toggle exists
- [x] `SE-08` — Quiet Hours toggle exists
- [x] `SE-09` — Badge Count toggle exists
- [x] `SE-10` — Sync Profiles navigation link exists
- [x] `SE-11` — Auto-Sync toggle exists
- [x] `SE-12` — Calendar Accounts section exists
- [x] `SE-13` — Collaborators navigation link exists
- [x] `SE-14` — Automations navigation link exists
- [x] `SE-15` — Version and build info displayed

---

## 18. Search (SearchUITests — 6/6)

- [x] `SR-01` — Open search (toolbar button)
- [x] `SR-02` — Empty search shows prompt
- [x] `SR-03` — Search finds task by title
- [x] `SR-04` — No results state for non-matching query
- [x] `SR-05` — Tap search result navigates to detail
- [x] `SR-06` — Search field exists and is focusable

---

## 19. Custom Filters (CustomFilterUITests — 5/5)

- [x] `CF-01` — New Filter option exists in Tasks menu
- [x] `CF-02` — Open new filter form
- [x] `CF-03` — New filter form has name field
- [x] `CF-04` — Create button disabled when name empty
- [x] `CF-05` — Cancel button works

---

## 20. Batch Edit (BatchEditUITests — 3/3)

- [x] `BE-01` — Select button exists in list view toolbar
- [x] `BE-02` — Tapping Select enters edit mode (Done button appears)
- [x] `BE-03` — Exit edit mode (Select button reappears)

---

## 21. Advanced Views (AdvancedViewsUITests — 10/10)

- [x] `AV-01` — Navigate to Eisenhower Matrix view
- [x] `AV-02` — Matrix view loads with quadrants
- [x] `AV-03` — Navigate to Kanban board
- [x] `AV-04` — Kanban shows column headers (To Do, Done)
- [x] `AV-05` — Navigate to Timeline/Gantt view
- [x] `AV-06` — Navigate to Suggested tasks view
- [x] `AV-07` — Suggested view shows sections
- [x] `AV-08` — Timeline view loads with tasks
- [x] `AV-09` — Tap kanban card navigates to task detail
- [x] `AV-10` — Tap timeline task navigates to task detail

---

## 22. Automations / Triggers (AutomationsUITests — 6/6)

- [x] `TR-01` — Navigate to Automations from Settings
- [x] `TR-02` — Empty state shows when no automations
- [x] `TR-03` — New automation button exists in toolbar
- [x] `TR-04` — Tap plus opens new automation form
- [x] `TR-05` — New automation form has name field
- [x] `TR-06` — Log button exists in automations toolbar

---

## 23. Folders (FoldersUITests — 5/5)

- [x] `FO-01` — Create folder via Tasks menu
- [x] `FO-02` — New Folder option in menu
- [x] `FO-03` — New List option in menu
- [x] `FO-04` — Folder cancel button works
- [x] `FO-05` — Lists section has New List button

---

## 24. Daily Retrospective (DailyRetrospectiveUITests — 5/5)

- [x] `DR-01` — Daily Review button exists in Today toolbar
- [x] `DR-02` — Opens as sheet with nav title "Daily Review"
- [x] `DR-03` — Stats section exists
- [x] `DR-04` — Completed task appears in retrospective
- [x] `DR-05` — Done button dismisses

---

## 25. List Management (ListManagementUITests — 7/7)

- [x] `LM-01` — Create a new list
- [x] `LM-02` — Navigate to user-created list
- [x] `LM-03` — List view has Select button
- [x] `LM-04` — Sort menu exists in list view
- [x] `LM-05` — Add Section option in sort menu
- [x] `LM-06` — Tasks appear in list view
- [x] `LM-07` — Swipe to complete task in list

---

## Test Count Summary

| Category | Implemented / Total | Test File |
|----------|---------------------|-----------|
| Onboarding | 5/5 | OnboardingUITests |
| Quick Add Task | 8/8 | QuickAddTaskUITests |
| Quick Add Note | 3/3 | QuickAddNoteUITests |
| Today View | 9/12 | TodayViewUITests |
| Task Lists | 12/12 | TaskListsUITests |
| Task Detail | 25/33 | TaskDetailUITests |
| Notes | 7/7 | NotesUITests |
| Subtasks | 8/8 | SubtasksUITests |
| Tags | 5/5 | TagsUITests |
| Recurrence | 4/4 | RecurrenceUITests |
| Calendar | 10/10 | CalendarUITests |
| Focus Timer | 9/9 | FocusTimerUITests |
| Habits | 12/12 | HabitsUITests + HabitDetailUITests |
| Chat | 8/8 | ChatUITests |
| Collaboration | 12/12 | CollaborationUITests |
| Sync Profiles | 7/7 | SyncProfilesUITests |
| Settings | 15/15 | SettingsUITests |
| Search | 6/6 | SearchUITests |
| Custom Filters | 5/5 | CustomFilterUITests |
| Batch Edit | 3/3 | BatchEditUITests |
| Advanced Views | 10/10 | AdvancedViewsUITests |
| Automations | 6/6 | AutomationsUITests |
| Folders | 5/5 | FoldersUITests |
| List Management | 7/7 | ListManagementUITests |
| **TOTAL** | **199/210** | **24 test files** |

> **Note:** 11 new test cases added for hierarchical tasks, habits in Today, activity logging,
> and the tabbed TaskDetailView. Some existing Task Detail tests (marked ⚠️) need UI test
> updates due to the header card + tabs redesign.
