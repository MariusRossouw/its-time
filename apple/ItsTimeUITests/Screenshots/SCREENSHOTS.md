# Screenshot Library

Screenshots are captured automatically during UI tests and saved to `/tmp/ItsTimeScreenshots/`.

## Naming Convention

```
{TestID}_{screen_name}.png
```

Test IDs map directly to entries in `TEST_PLAN.md`.

## How to Capture

Screenshots are captured by calling `takeScreenshot("name")` in any test that inherits from `ItsTimeUITestBase`. This:
1. Attaches the screenshot to the `.xcresult` bundle (viewable in Xcode Test Report)
2. Saves a PNG to `/tmp/ItsTimeScreenshots/{name}.png` (readable by Claude)

## Directories

- `Screens/` — Manual reference screenshots (what the UI *should* look like)
- `Captures/` — Auto-captured by tests (gitignored, regenerated on each run)

## Auto-Captured Screenshots

These tests include `takeScreenshot` calls:

| Screenshot | Test | Screen |
|-----------|------|--------|
| `OB-01_onboarding.png` | OB-01 | Onboarding welcome |
| `QA-01_quick_add_sheet.png` | QA-01 | Quick add task sheet |
| `TV-01_today_view.png` | TV-01 | Today view with greeting + productivity card |
| `TV-02_today_empty.png` | TV-02 | Today empty state |
| `TL-01_tasks_tab.png` | TL-01 | Tasks tab (lists/smart lists) |
| `TD-01_task_detail_top.png` | TD-01 | Task detail (top section) |
| `TD-09_task_detail_mid.png` | TD-09 | Task detail (mid — reminders) |
| `TD-16_task_detail_bottom.png` | TD-16 | Task detail (bottom — info) |
| `TD-23_child_tasks_section.png` | TD-23 | Child tasks section with progress bar |
| `TD-24_child_task_added.png` | TD-24 | Child task with progress header (0% 0/1) |
| `TD-25_parent_task_picker.png` | TD-25 | Parent task picker |
| `TD-26_child_with_parent_breadcrumb.png` | TD-26 | Child detail with parent breadcrumb |
| `CV-01_calendar_month.png` | CV-01 | Calendar month view |
| `FT-01_focus_timer.png` | FT-01 | Focus timer |
| `HB-02_habits_empty.png` | HB-02 | Habits empty state |
| `CH-01_chat.png` | CH-01 | Chat channels |
| `SE-01_settings.png` | SE-01 | Settings |
| `SR-01_search.png` | SR-01 | Search view |
| `AV-02_eisenhower_matrix.png` | AV-02 | Eisenhower matrix |
| `AV-04_kanban_board.png` | AV-04 | Kanban board |
| `AV-08_timeline_view.png` | AV-08 | Timeline/Gantt view |

## UI Refinements (design-reference driven)

Based on 15+ reference design images, the following refinements were applied:

### TaskRowView
- **Mini progress bars** for subtasks (green) and child tasks (blue) with icon + count + capsule bar
- **Priority badge pills** — "High" (red) and "Medium" (orange) shown as colored capsule chips
- Progress bars turn green when all items complete
- **Hierarchical display** — HierarchicalTaskRowView with recursive accordion expand/collapse

### TodayView
- **Productivity summary card** — blue-to-cyan gradient card with white progress bar
- Shows contextual message: "X tasks to complete today" / "X tasks remaining" / "All done!"
- Card turns green-to-mint gradient when all tasks are complete
- Greeting personalized with user's first name + time-of-day greeting
- **Habits section** — today's habits with inline check-in (toggle/increment), streak, progress ring
- **Child task filtering** — only root-level tasks shown; children accessed via hierarchy

### TaskDetailView (redesigned March 2026)
- **Rich header card** (always visible above tabs):
  - Status pill (colored capsule with dropdown menu)
  - Priority badge (colored badge with icon, e.g. "! HIGH")
  - Editable title
  - Assignment avatars (circular with initials, dashed "+" add button)
  - Due date with time preference icon (sun/moon/clock)
  - List badge with icon and name
  - Tag chips (FlowLayout with remove buttons and "+" add)
- **4 tabs**: Notes, Children, Subtasks, Activity
- **More Options sheet** (toolbar ⋯): section, parent, recurrence, start date, reminders, nudge, location, convert
- **Comprehensive activity tracking** — 21 action types automatically logged

### ChildTasksSectionView
- **Progress header** — percentage + count + progress bar (e.g., "Child Tasks 0% 0/1 ━")
- Includes linked habits with habit badge, streak, frequency

## Running Screenshot Tests

To capture all screenshots, run the tagged tests:

```bash
# All screens at once (select one test per suite)
xcodebuild test -scheme ItsTime_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
  -only-testing:"ItsTimeUITests/OnboardingUITests/testFreshLaunchShowsOnboarding" \
  -only-testing:"ItsTimeUITests/QuickAddTaskUITests/testOpenQuickAddSheet" \
  -only-testing:"ItsTimeUITests/TodayViewUITests/testTodayTabShowsTasksDueToday" \
  -only-testing:"ItsTimeUITests/TaskListsUITests/testNavigateToInbox" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testDetailViewOpens" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testRemindersSectionExists" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testInfoSectionExists" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testChildTasksSectionExists" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testAddChildTaskInline" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testParentTaskPickerExists" \
  -only-testing:"ItsTimeUITests/TaskDetailUITests/testChildTaskShowsParentBreadcrumb" \
  -only-testing:"ItsTimeUITests/CalendarUITests/testNavigateToCalendar" \
  -only-testing:"ItsTimeUITests/FocusTimerUITests/testNavigateToFocus" \
  -only-testing:"ItsTimeUITests/HabitsUITests/testEmptyState" \
  -only-testing:"ItsTimeUITests/ChatUITests/testNavigateToChat" \
  -only-testing:"ItsTimeUITests/SettingsUITests/testNavigateToSettings" \
  -only-testing:"ItsTimeUITests/SearchUITests/testOpenSearch" \
  -only-testing:"ItsTimeUITests/AdvancedViewsUITests/testMatrixShowsQuadrants" \
  -only-testing:"ItsTimeUITests/AdvancedViewsUITests/testKanbanColumns" \
  -only-testing:"ItsTimeUITests/AdvancedViewsUITests/testTimelineViewLoads"
```

Screenshots will be at `/tmp/ItsTimeScreenshots/`.
