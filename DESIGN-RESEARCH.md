# Design Research: UI/UX Patterns from 5 Productivity Apps

Research conducted 2026-03-21 to inform the visual design direction for Its Time.

---

## 1. TickTick (ticktick.com)

### Layout Pattern
- **Three-column layout** on desktop/iPad: left sidebar (list/folder navigation), middle column (task list), right pane (task detail with notes, images, Markdown).
- On iPhone, collapses to a **navigation stack** -- tap a list to see tasks, tap a task to see detail.
- Multiple view modes accessible from the same navigation: List, Calendar (monthly/weekly/daily/agenda), Kanban Board, Timeline (Gantt-like), Eisenhower Matrix, and Sticky Notes.
- Tab bar on iPhone for switching between major sections (tasks, calendar, habits, focus timer).

### Color Scheme
- Default light theme uses a **clean white background** with a slightly warm off-white sidebar.
- Primary accent color is a **blue** (used for selection highlights, active states, the add button).
- Priority levels are color-coded: red (high), orange (medium), blue (low), none (gray).
- Tags support custom color assignment.
- **40+ themes** available, including dark mode variants. Dark mode uses deep gray/near-black backgrounds with the same accent system.
- List-level background customization (custom wallpapers per list).

### Typography
- Clean **sans-serif** system font (SF Pro on Apple platforms).
- **Bold, larger headings** for list titles and section headers.
- Task titles are medium weight; metadata (dates, tags) is smaller and lighter.
- Markdown support in task descriptions with rendered headings, bold, code blocks.
- Not overly dense -- readable line heights with clear visual separation between tasks.

### Visual Density
- **Moderate density** -- not as spacious as Apple Reminders, not as cramped as Todoist.
- Each task row shows: checkbox, title, due date badge, priority indicator, tag chips -- all on one or two lines.
- Generous padding in the sidebar and detail pane.
- Calendar views are denser by nature; the weekly view packs more information.

### Key UI Components
- **Round checkboxes** with priority-based color fill (red ring for high priority, etc.).
- **Floating action button** (FAB) on mobile for quick-add, positioned bottom-right.
- **Smart Lists** at the top of the sidebar (Today, Next 7 Days, All, Inbox) with count badges.
- **Sections** within lists act as visual dividers/groupings.
- **Kanban columns** with card-style task representations.
- **Pomodoro timer** as a fullscreen or overlay component with circular progress indicator.
- **Habit tracker** with punch-card grid (checkmark grid calendar).
- **Drag-and-drop** throughout -- reorder tasks, move between columns, reschedule on calendar.

### Distinctive Design Choices
- The **view switcher** allowing the same data to be seen as list, kanban, calendar, timeline, or matrix is the defining feature -- one data set, many lenses.
- Heavy investment in **theming** (40+ themes) signals that personalization is core to the brand.
- Integrates **multiple productivity tools** (tasks, calendar, habits, focus timer) without feeling bloated -- each tool has its own tab/space.
- **Subtle animations** on task completion (strikethrough with slight delay, satisfying check animation).

### iOS/macOS Adaptation
- **iPhone**: Navigation stack with bottom tab bar. Lists -> Tasks -> Detail as push navigation. Compact single-column layout. Quick-add via FAB.
- **iPad**: Sidebar (collapsible) + task list + optional detail pane. Supports Split View and Slide Over. Sidebar mirrors the Mac sidebar.
- **Mac**: Full three-column layout with resizable panes. Menu bar integration, global keyboard shortcut for quick-add. Feels like a native Mac app with toolbar buttons and keyboard shortcuts. Window resizing gracefully collapses columns.

---

## 2. Any.do

### Layout Pattern
- **Bottom tab bar** on iPhone with primary sections: My Day, Tasks, Calendar, Settings.
- **Daily Planner** view is the hero feature -- a vertically scrolling timeline of today's tasks and calendar events interleaved.
- On iPad/desktop, expands to a **sidebar + content** layout.
- Calendar view is a full-featured calendar with day/week/month modes.
- Navigation follows iOS conventions closely -- feels like a system app.

### Color Scheme
- **Blue as the primary accent** (RGB approximately 0.31, 0.58, 0.97 -- a medium-bright blue).
- Clean **white backgrounds** in light mode.
- Dark mode syncs with system settings automatically via "dynamic theme."
- Minimal use of color in the UI chrome -- color is reserved for accent states, the add button, and calendar event indicators.
- Lists can be assigned individual colors for visual grouping.
- Overall palette is **restrained and professional** -- no loud gradients or heavy use of color.

### Typography
- Follows **Apple's native design language** closely -- users describe it as modeling itself after Apple's own apps.
- System font (SF Pro) with standard iOS sizing conventions.
- Section headers (Morning, Afternoon, Evening in the daily planner) use **bold, uppercase, or semi-bold** treatments.
- Task text is regular weight, secondary info (dates, notes preview) is smaller and gray.
- Some reported inconsistency in font sizes across sections (a known issue).

### Visual Density
- **Spacious and airy** -- generous whitespace, large touch targets.
- The daily planner spreads tasks across time blocks with breathing room.
- Calendar day cells are clean with minimal indicators (dots or short text).
- Task rows are well-spaced with clear separation.
- Feels less information-dense than TickTick -- prioritizes clarity over packing in data.

### Key UI Components
- **Daily Planner** -- the signature component. A vertical timeline merging tasks and calendar events by time of day, with Morning/Afternoon/Evening sections.
- **Round checkboxes** (similar to Apple Reminders style).
- **Floating add button** centered at the bottom of the screen.
- **Calendar integration** showing tasks and events side by side.
- **Widgets** for home screen showing upcoming tasks in a clean card layout.
- **Suggestion chips** for quick scheduling ("Today", "Tomorrow", "Next Week").
- Clean **swipe actions** on task rows (complete, schedule, delete).

### Distinctive Design Choices
- The **Daily Planner merging tasks + calendar** into a single chronological view is the defining UX innovation -- you see your day as one unified stream rather than switching between tasks and calendar.
- **"Moment" feature** -- a daily review prompt that walks you through your day's tasks one by one, asking you to plan each. This is a guided, almost meditative interaction.
- Feels the most **"Apple-native"** of the five apps studied -- minimal custom UI, heavy reliance on system components.
- AI-powered task suggestions and categorization (newer feature).

### iOS/macOS Adaptation
- **iPhone**: Bottom tab bar, navigation stack. Daily planner is the default landing view. Very thumb-friendly with the centered add button.
- **iPad**: Sidebar navigation replaces the tab bar. Split view support. Calendar and task views can be shown side by side.
- **Mac**: Web-based or Catalyst-style app. Less emphasis on the Mac experience compared to TickTick -- mobile-first design adapted upward.

---

## 3. NotePlan (noteplan.co)

### Layout Pattern
- **Three-pane layout** on Mac: left sidebar (folder/note tree), middle (note/task list or calendar sidebar), right (main editor).
- Deeply integrated **calendar + notes + tasks** -- daily notes are the central organizing concept. Each day has a note, and tasks live inside notes.
- **Sidebar** shows: Calendar navigation, Daily Notes, Project Notes (folders), Filters, Templates.
- **Command bar** (Cmd+J) for quick navigation and actions -- similar to VS Code's command palette.
- On iPhone, collapses to a navigation stack. On iPad, uses a sidebar with the editor.

### Color Scheme
- Default light theme uses **warm stone/cream backgrounds** (not pure white -- more like `#faf9f7`).
- **Orange as the primary accent color** (buttons, links, tint -- approximately `#f97316`).
- Rich **theme system** via JSON configuration files -- users can customize every color: background, sidebar, tint, text, toolbar, individual Markdown element colors.
- Dark mode available with deep backgrounds. Sidebar can be independently styled darker than the editor ("sidebarStyleOverride" for dark sidebar on light theme).
- Calendar events are color-coded by source calendar.
- Task priorities and statuses have distinct colors (configurable in themes).

### Typography
- **Markdown-native** rendering -- the editor shows formatted Markdown in place (WYSIWYG-ish with visible syntax).
- Monospace or sans-serif font options, selectable per theme.
- System fonts available (`.AppleSystemFont`) plus any installed font via PostScript name.
- **Headings are bold and scaled** (H1 largest, H2 medium, etc.) with configurable line spacing and paragraph spacing.
- Task items render with checkboxes inline in the text flow.
- Code blocks render with distinct background color and optional syntax highlighting.
- Typography density is **moderate to dense** -- it's a note-taking app, so text is the primary content.

### Visual Density
- **Medium-high density** -- it's a writing/planning tool, so the editor is text-rich.
- The three-pane layout on Mac can feel busy but each pane is individually scrollable and focusable.
- Calendar sidebar is compact, showing a mini month view and today's events.
- Notes can get long and dense, but configurable line spacing and paragraph spacing help.
- iPhone view is necessarily more focused -- one note at a time.

### Key UI Components
- **Daily Notes** -- auto-generated note for each day. This is the core interaction: open today's note, write tasks and notes for the day.
- **Inline task checkboxes** that live within Markdown text -- tasks are not separate entities but lines in a note prefixed with `- [ ]`.
- **Time blocking** -- drag tasks from notes onto calendar time slots.
- **Bi-directional links** (`[[page name]]`) between notes, wiki-style.
- **Calendar sidebar** showing events alongside the daily note.
- **Filters** for finding tasks across all notes by status, date, tag.
- **Keyboard toolbar** on iPhone for quick Markdown formatting.
- **Command bar** for rapid navigation (Cmd+J / Ctrl+J).

### Distinctive Design Choices
- **"Daily note as the hub"** -- rather than a task list being the primary view, you open today's note and plan your day in prose with embedded tasks. This is fundamentally different from traditional task managers.
- **Markdown-first** with plain text storage -- all data is Markdown files stored locally or in iCloud. No proprietary database.
- **Time blocking by dragging note content to calendar** -- bridging the gap between writing and scheduling.
- The theme system is **remarkably deep** -- JSON-based, controlling individual Markdown element colors, fonts, spacing, borders, and even regex-based custom styles.
- Feels like a **developer's productivity tool** -- command bar, Markdown, plain text files, deep customization.

### iOS/macOS Adaptation
- **Mac**: Full three-pane layout. Command bar, keyboard shortcuts, menu bar items. The most complete experience -- this is a Mac-first app.
- **iPad**: Sidebar + editor. Recent updates added "liquid glass" sidebar styling. Split View support. Calendar sidebar can be toggled.
- **iPhone**: Navigation stack. Redesigned keyboard toolbar for quick formatting. Compact but functional -- you can capture tasks and notes on the go, but the Mac is where deep planning happens.
- Uses **CloudKit/iCloud Drive** for sync across Apple devices (all data is local files).

---

## 4. Notion (notion.com)

### Layout Pattern
- **Sidebar + page content** as the core layout.
- Sidebar (240px default, resizable) contains: workspace switcher, search, favorites, private/shared pages in a **nested tree structure** (infinitely nestable pages).
- Content area is a **block-based editor** -- every line is a block that can be text, heading, toggle, callout, image, embed, database, etc.
- Databases have **multiple view types**: Table, Board (Kanban), Calendar, Gallery, List, Timeline -- switchable on the same data.
- Pages can be **full-width** or **centered** (narrower, more readable).
- No tab bar on mobile -- hamburger menu to access sidebar.

### Color Scheme
- Light mode: **off-white background** (`#fffefc` -- warm, not pure white), dark brown text (`#37352f` -- not pure black).
- Sidebar: slightly darker off-white (`#f9f8f7`) with subtle border (`#f0efed`).
- Dark mode: near-black background (`#191919`) with light text.
- **Muted, earthy color palette** for text and background highlights: light gray, brown, orange, yellow, green, blue, purple, pink, red -- all in soft/muted tones rather than saturated.
- Callout blocks, database tags, and text highlights use this muted palette.
- The overall feel is **warm and bookish** -- more like paper than screen.

### Typography
- **Three font choices per page**: Default (sans-serif system font), Serif (Georgia-like), Mono (monospaced).
- A **"Small text" toggle** reduces font size across the entire page for denser layouts.
- Headings are **bold and clearly scaled** (H1/H2/H3 with significant size differences).
- Body text is comfortable reading size with good line height.
- Toggle lists, bullet lists, and numbered lists have consistent indentation.
- The serif option gives pages a distinctly editorial/literary feel.
- Code blocks use monospace with syntax highlighting.

### Visual Density
- **Spacious by default** -- generous margins, comfortable line heights, centered content that doesn't stretch to full width.
- Full-width mode increases density by using the entire viewport.
- "Small text" mode further increases density.
- Database table views can be quite **dense** -- resembling spreadsheets with compact rows.
- Overall, Notion leans **spacious for documents, dense for databases** -- and users control the balance.

### Key UI Components
- **Block-based editor** -- the "/" command opens an insert menu for any block type. This is the core interaction pattern.
- **Inline databases** -- tables, boards, calendars embedded directly in pages.
- **Database views** with filters, sorts, and grouping -- each view is a saved configuration.
- **Page icons and covers** -- every page can have an emoji/custom icon and a banner image.
- **Callout blocks** -- colored boxes with icons for highlighting information.
- **Toggle blocks** -- collapsible content sections.
- **Breadcrumb navigation** showing the page hierarchy.
- **Slash command** ("/") for inserting blocks -- the power-user interaction.
- **@-mentions** for linking to pages, people, or dates.
- **Skeleton loading screens** with shimmer animations during page loads.

### Distinctive Design Choices
- **"Everything is a block"** -- the block-based editor is infinitely composable. A page can contain any combination of text, media, databases, embeds, etc.
- **Warm, not-quite-white color palette** gives Notion a distinctive "paper-like" feel that stands out from the clinical white of most productivity apps.
- **Page icons (emoji)** in the sidebar create a colorful, scannable navigation tree.
- **Templates and template databases** -- rich starting points that show off the flexibility.
- The design is **maximally flexible** but can feel overwhelming -- Notion trades opinionated structure for user freedom.
- **Smooth animations** and loading states (shimmer effects) give a polished feel despite the complexity.

### iOS/macOS Adaptation
- **Mac**: Electron-based app (not native SwiftUI). Full sidebar + content. Keyboard shortcuts, but not deeply integrated with macOS conventions. Feels like a web app in a window.
- **iPad**: Sidebar (toggleable) + content. Works well but loses some of the multi-column database views on smaller screens.
- **iPhone**: Hamburger menu for navigation, full-width content. Pages scroll vertically. Databases switch to card/list views on narrow screens. Editing is functional but the desktop is the power environment.
- The gap between desktop and mobile is more noticeable in Notion than in the other apps studied -- the block editor's full flexibility is harder to replicate on small screens.

---

## 5. Due (dueapp.com)

### Layout Pattern
- **Single-screen flat list** of reminders -- no sidebar, no nested navigation, no tabs on desktop.
- iPhone uses a **simple list view** as the primary and nearly only screen. Reminders are shown in chronological order.
- A **hamburger menu** (or minimal navigation) provides access to settings, timers, and logbook.
- **Countdown timers** are a secondary feature with their own dedicated view.
- The app is intentionally **minimal in navigation** -- there is essentially one screen to manage.

### Color Scheme
- Multiple built-in themes including **Light** and **Ash** (a mid-tone gray theme).
- Dark mode support, including a **"Midnight Glass"** dark theme with Apple's Liquid Glass aesthetic.
- The default light theme uses **white/very light backgrounds** with a single accent color for interactive elements.
- Color usage is **extremely restrained** -- the UI is almost monochromatic with one accent color.
- Overdue reminders are highlighted with a distinct color (typically red or orange) to create urgency.
- Timers may use a different accent from reminders to distinguish the two features.

### Typography
- **Clean, readable sans-serif** (system font).
- Reminder titles are the dominant text element -- relatively large and readable.
- Due dates/times are shown as **secondary text** below or beside the title.
- **Auto-scaling text size** that respects system accessibility settings.
- Overall typography is **bold and clear** -- optimized for glanceability. You should be able to read your next reminder at arm's length.

### Visual Density
- **Moderate density** -- each reminder gets a comfortable row height with title and time clearly separated.
- Not as spacious as Any.do but not cramped either.
- The single-screen design means everything important is visible without drilling down.
- **Checklist-style widget** allows even denser at-a-glance information on the home screen.
- Timers are displayed with a large, prominent countdown number.

### Key UI Components
- **12 customizable quick-add time buttons** -- the signature UI component. Instead of a date/time picker, you get a grid of preset times ("In 1 hour", "Tomorrow 9am", "Next Monday", etc.) that you configure to match your patterns. This makes setting due times almost instant.
- **Auto-snooze** -- reminders automatically repeat at intervals until acknowledged. The notification keeps coming back. This is the core product concept.
- **Notification-level interactions** -- you can complete, snooze, or reschedule reminders directly from the notification without opening the app.
- **Countdown timers** as a separate feature with large, bold countdown display.
- **Logbook** for completed reminders.
- **Simple flat list** -- no folders, no projects, no tags. Just reminders with times.

### Distinctive Design Choices
- **Radical simplicity** -- Due is deliberately NOT a task manager. It's a reminders app. No lists, no projects, no tags, no subtasks. Just things with times.
- The **12 quick-time buttons** are a brilliant UX innovation -- they replace the standard time picker with one-tap scheduling based on your personal patterns.
- **Persistent nagging** (auto-snooze) is the core value proposition -- the app will not let you forget. This aggressive notification behavior is the defining feature.
- The UI is **almost brutally minimal** -- the designers removed everything that isn't essential to "remind me of this at that time."
- Feels like a **native Apple utility** -- simple, focused, well-crafted, doing one thing exceptionally well.

### iOS/macOS Adaptation
- **iPhone**: The primary platform. Single list view, quick-add with time buttons, notification interactions. The app is designed to be used in 5-second bursts.
- **iPad**: Expanded layout but fundamentally the same single-list interface. More screen real estate for the quick-time button grid.
- **Mac**: Native Mac app (not Catalyst). Menu bar presence. Same minimal interface adapted to the Mac window. Keyboard-friendly for quick entry.
- The adaptation is **minimal by design** -- the same simple interface works on all screen sizes because there's not much to rearrange. The quick-time buttons may expand into a wider grid on larger screens.

---

## Synthesis: Common Patterns and Recommended Design Direction

### Common Patterns Across All 5 Apps

**1. Layout Convergence**
- Every app uses some form of **sidebar + content** on larger screens (iPad/Mac) and **navigation stack** or **tab bar** on iPhone.
- Three-column layouts (sidebar, list, detail) are standard for task-heavy apps (TickTick, NotePlan, Notion).
- Simpler apps (Due, Any.do) use fewer columns, proving that complexity should match the feature set.

**2. Color Philosophy**
- All five apps use **restrained color palettes** -- white or off-white backgrounds with a single accent color. None of them use loud, multi-color interfaces.
- Blue is the most common accent (TickTick, Any.do, Notion). Orange is used by NotePlan. Due is theme-dependent.
- Color is reserved for **meaning**: priority levels, calendar sources, tags, overdue states. Decorative color is avoided.
- Every app supports **dark mode**, most syncing with the system setting.
- Multiple theme options are common (TickTick: 40+, Due: several, NotePlan: fully customizable via JSON).

**3. Typography Consensus**
- System fonts (SF Pro on Apple) are the baseline across all apps.
- **Bold headings with clear hierarchy** are universal.
- Task/reminder text is regular weight; metadata (dates, tags) is smaller and lighter-colored.
- None of the apps use unusual or decorative fonts -- readability is the priority.
- Notion stands out by offering serif and monospace options per page.

**4. Density Spectrum**
- The apps form a clear spectrum: **Due (minimal) -> Any.do (spacious) -> TickTick (moderate) -> Notion (variable) -> NotePlan (dense)**.
- The trend: simple apps are more spacious, complex apps are denser.
- All apps give the primary content (task title, note text) the most visual weight.

**5. Interaction Patterns**
- **Floating action button** (FAB) or prominent add button for quick capture (TickTick, Any.do).
- **Swipe actions** on list rows (complete, schedule, delete) are universal on iOS.
- **Drag-and-drop** for reordering and rescheduling (TickTick, NotePlan, Notion).
- **Checkboxes** (round, not square) for task completion are the overwhelming standard on iOS.

**6. Platform Adaptation Strategy**
- iPhone: Navigation stack + tab bar. Single-column. Thumb-friendly bottom actions.
- iPad: Sidebar (collapsible) + content. Split View support. Sometimes three columns.
- Mac: Full multi-column layout. Keyboard shortcuts. Menu bar/toolbar integration.
- The sidebar is the key adaptive element -- it appears on iPad/Mac and hides on iPhone.

### Recommended Design Direction for Its Time

Based on this research, here is a unified design direction that takes the best from each app and is optimized for SwiftUI with adaptive layouts:

#### Core Layout: Adaptive Three-Column

```
iPhone:          iPad:                    Mac:
[Tab Bar]        [Sidebar | Content]      [Sidebar | List | Detail]
[Content ]       [        | Detail  ]     [        |      |       ]
[        ]       [        |         ]     [        |      |       ]
```

- Use SwiftUI's `NavigationSplitView` with two or three columns.
- **iPhone**: `NavigationStack` with a bottom `TabView` for major sections (Today, Tasks, Calendar, Focus, More).
- **iPad**: Two-column `NavigationSplitView` (sidebar + content). Detail appears as a push or third column depending on size class.
- **Mac**: Three-column `NavigationSplitView` (sidebar + list + detail) with resizable panes.
- The sidebar should be **collapsible** on iPad and Mac (SwiftUI handles this natively).

**Borrowed from**: TickTick (three-column flexibility), Any.do (tab bar simplicity on iPhone), NotePlan (sidebar structure).

#### Color System: Warm Minimalism

- **Background**: Warm off-white (`#FAFAF8` light / `#1A1A1A` dark) -- take Notion's warm approach rather than clinical pure white. This reduces eye strain and feels more refined.
- **Sidebar background**: Slightly darker/cooler than content (`#F5F5F3` light / `#141414` dark).
- **Primary accent**: A **blue** (like TickTick/Any.do) for interactive elements, selections, and the add button. Blue is the most universally trusted accent for productivity apps.
- **Semantic colors**: Red for high priority/overdue, orange for medium priority, blue for low priority, green for completed. These are universal across the apps studied.
- **Tag/list colors**: Offer a palette of 10-12 muted colors (follow Notion's soft palette rather than saturated colors).
- **Dark mode**: Full system-aware dark mode from day one. Use SwiftUI's `Color` assets with automatic light/dark variants.
- **Future theming**: Plan the architecture for custom themes (like TickTick/NotePlan) but ship with Light, Dark, and one or two accent color options initially.

**Borrowed from**: Notion (warm backgrounds), TickTick (blue accent, priority colors), NotePlan (theme architecture for future).

#### Typography: Clear Hierarchy with SF Pro

- Use **SF Pro** (the system font) exclusively -- it's what users expect on Apple platforms and SwiftUI makes it effortless.
- **Title style**: `.title2` or `.title3` with `.bold` for section/list headers.
- **Task title**: `.body` weight regular. This is the most-read text and should be comfortable.
- **Metadata** (due dates, tags, counts): `.caption` or `.footnote` in `.secondary` color.
- **Detail view headings**: `.title` with `.bold`.
- **Markdown rendering** in descriptions: Support bold, italic, headings, code, lists -- like TickTick and NotePlan.
- Consider offering a **compact text size** toggle (like Notion's "Small text") for power users who want denser views.

**Borrowed from**: Any.do (Apple-native feel), Notion (text size toggle), NotePlan (Markdown rendering).

#### Visual Density: Moderate with Adaptive Spacing

- Target **TickTick's moderate density** as the default -- not as spacious as Any.do, not as dense as NotePlan.
- Task rows should show: checkbox + title + due date badge + priority indicator on one line, with optional second line for tags/list name.
- Row height: approximately 44-52pt on iPhone (comfortable touch targets), can be tighter on Mac where mouse precision allows.
- Use `LazyVStack` with consistent spacing (8-12pt between rows).
- **Calendar views** will naturally be denser -- that's expected and acceptable.
- **Sidebar items**: Compact rows (36-40pt) with icon + label + count badge.

**Borrowed from**: TickTick (balance of info and space), Due (clarity of each row), Any.do (touch-friendly sizing on mobile).

#### Key UI Components

1. **Task Row** (the most important component):
   - Round checkbox (filled with priority color when set, gray outline when no priority).
   - Task title (regular weight, strikethrough with animation on completion).
   - Due date chip (color-coded: overdue = red, today = blue, upcoming = gray).
   - Priority dot or ring on the checkbox.
   - Tag chips (small, rounded, muted colors).
   - Swipe actions: left-swipe to complete, right-swipe to schedule.
   - **Borrowed from**: TickTick (checkbox + priority color), Due (clear time display), Any.do (swipe gestures).

2. **Quick Add**:
   - **FAB** on iPhone (bottom-right, blue circle with "+"), converting to a text field that slides up from the bottom.
   - **Toolbar button** on Mac.
   - Natural language parsing: "Buy milk tomorrow at 5pm #errands !high".
   - **Quick date buttons** below the text field (Today, Tomorrow, Next Week, custom -- inspired by Due's 12-button grid but simplified to 4-6 presets).
   - **Borrowed from**: TickTick (FAB placement), Due (quick date buttons), Any.do (suggestion chips).

3. **Sidebar**:
   - Smart Lists at top: Inbox (with count badge), Today, Next 7 Days, All.
   - Divider.
   - Folders (collapsible) containing Lists.
   - Each list has: color dot + name + task count.
   - Tags section (collapsible).
   - Settings at bottom.
   - **Borrowed from**: TickTick (smart list organization), Notion (nested tree structure), NotePlan (command bar for quick jump).

4. **Calendar View**:
   - Monthly view as a grid with dot indicators for tasks on each day.
   - Weekly view as a time-blocked vertical timeline (like Any.do's daily planner but for the week).
   - Daily view merging tasks + calendar events (the Any.do Daily Planner concept).
   - Color-code by list, priority, or calendar source.
   - Drag-and-drop tasks onto time slots for time blocking.
   - **Borrowed from**: Any.do (daily planner merge), TickTick (multiple calendar modes), NotePlan (time blocking).

5. **Detail View**:
   - Full task detail with all properties.
   - Markdown-capable description editor.
   - Subtask list (checkboxes, nestable).
   - Metadata section: due date picker, priority selector, list/tag assignment, reminders.
   - Activity log / history.
   - **Borrowed from**: TickTick (rich detail pane), NotePlan (Markdown editor), Notion (block-style content).

6. **Focus Timer**:
   - Circular progress ring (large, centered).
   - Task name displayed above the timer.
   - Minimal controls: start/pause, skip, stop.
   - Statistics as simple bar/line charts.
   - **Borrowed from**: TickTick (Pomodoro integration), Due (countdown display).

#### Distinctive Design Identity for Its Time

Rather than copying any single app, Its Time should aim for a **"refined utility"** aesthetic:

1. **Warm minimalism** (from Notion): Off-white backgrounds, muted color palette, not clinical. The app should feel inviting, not sterile.

2. **One data set, many views** (from TickTick): The same tasks can be viewed as a list, kanban board, calendar, or matrix. The view switcher should be prominent and easy to discover.

3. **Daily planning as first-class** (from Any.do): The "Today" view should merge tasks and calendar events into a single chronological daily plan, not just a filtered task list.

4. **Quick capture, aggressive reminders** (from Due): The quick-add flow should be under 3 seconds. Reminder behavior should be persistent by default (keep nagging until acknowledged).

5. **Depth for power users** (from NotePlan): Markdown support, keyboard shortcuts, command palette, customizable themes -- these should be discoverable but not required.

6. **Native Apple feel** (from Any.do + Due): Use system components wherever possible. `NavigationSplitView`, `TabView`, `.searchable`, `Menu`, `ToolbarItem`. The app should feel like it belongs on Apple platforms, not like a cross-platform port.

#### SwiftUI Implementation Notes

- Use `NavigationSplitView` (iOS 16+/macOS 13+) as the root layout container.
- Use `@Environment(\.horizontalSizeClass)` for adaptive layouts.
- Use SwiftUI's built-in `List` with `.listStyle(.sidebar)` for the sidebar.
- Use `.swipeActions` for task row gestures.
- Use `Color` asset catalogs with light/dark variants for the color system.
- Use `@AppStorage` for user preferences (theme, density, default list).
- Use `DynamicTypeSize` environment value to respect accessibility text sizes.
- Use `.sensoryFeedback` (iOS 17+) for haptic feedback on task completion.
- Use `ContentUnavailableView` for empty states.
- Use `TipKit` for progressive disclosure of power features.

#### Design Principles (Ranked)

1. **Speed of capture**: Getting a task from your head into the app should take under 3 seconds.
2. **Glanceability**: You should be able to see what matters today in under 2 seconds.
3. **Progressive disclosure**: Simple on the surface, powerful underneath. New users see a clean task list; power users discover keyboard shortcuts, filters, views.
4. **Native feel**: Respect platform conventions. Use system controls. Support Dynamic Type, Dark Mode, and accessibility from day one.
5. **Warm and personal**: Not clinical or corporate. This is a personal productivity tool. The warm color palette and potential for theming should make it feel like *your* space.

---

## Appendix: Quick Reference Comparison

| Aspect | TickTick | Any.do | NotePlan | Notion | Due |
|--------|----------|--------|----------|--------|-----|
| **Primary layout** | 3-column | Tab bar + content | 3-pane | Sidebar + page | Flat list |
| **Accent color** | Blue | Blue | Orange | None (muted palette) | Theme-dependent |
| **Background** | White | White | Warm stone | Warm off-white | White |
| **Dark mode** | Yes (40+ themes) | Yes (system sync) | Yes (custom themes) | Yes | Yes (Midnight Glass) |
| **Typography** | SF Pro, clean | SF Pro, Apple-native | Configurable, Markdown | 3 options per page | SF Pro, bold/clear |
| **Density** | Moderate | Spacious | Medium-high | Variable | Moderate |
| **Task display** | Checkbox + metadata | Checkbox + time sections | Inline in Markdown | Database rows/cards | Simple list rows |
| **Signature feature** | Multi-view switcher | Daily Planner | Daily notes as hub | Block editor | Auto-snooze + quick times |
| **iPhone nav** | Tab bar + stack | Tab bar + stack | Navigation stack | Hamburger + stack | Single screen |
| **iPad nav** | Sidebar + detail | Sidebar + content | Sidebar + editor | Sidebar + page | Expanded list |
| **Mac nav** | 3-column window | Web/Catalyst | 3-pane native | Electron sidebar + page | Native minimal |
| **Platform feel** | Near-native | Most Apple-native | Mac-first native | Web-first | Fully native |
