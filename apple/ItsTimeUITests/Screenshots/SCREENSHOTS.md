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
| `TV-01_today_view.png` | TV-01 | Today view with task |
| `TL-01_tasks_tab.png` | TL-01 | Tasks tab (lists/smart lists) |
| `TD-01_task_detail_top.png` | TD-01 | Task detail (top section) |
| `TD-09_task_detail_mid.png` | TD-09 | Task detail (mid — reminders) |
| `TD-16_task_detail_bottom.png` | TD-16 | Task detail (bottom — info) |
| `TD-23_child_tasks_section.png` | TD-23 | Child tasks section |
| `TD-24_child_task_added.png` | TD-24 | Child task created inline |
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
