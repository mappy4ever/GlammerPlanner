# Barbie Tasks — macOS App Setup

## Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15+

## Project Structure

```
BarbieTasks/
  BarbieTasks/
    App/
      BarbieTasksApp.swift          — @main entry, menus, keyboard commands, URL scheme, menu bar extra
    Models/
      BarbieTask.swift              — Core task model (priority, subtasks, recurrence, attachments)
      BarbieProject.swift           — Project (folder) model
      BarbieTag.swift               — Tag model
      SmartList.swift               — SmartList enum, ViewSelection, SortOption, Quote
      RecurrenceRule.swift           — Daily/weekly/monthly/yearly recurrence
      PomodoroSession.swift         — Focus session tracking
      TaskAttachment.swift          — File/link attachments
      AppSettings.swift             — @Observable settings with @AppStorage
      Store.swift                   — Central @Observable state manager (CRUD, filters, pomodoro, stats)
    Views/
      ContentView.swift             — Root NavigationSplitView + overlays
      SidebarView.swift             — Smart lists, projects, tags
      TaskListView.swift            — Task list with quick-add, sort bar, empty states
      TaskRowView.swift             — Individual task row with meta badges
      DetailView.swift              — Full task editor (due date, recurrence, priority, subtasks, etc.)
      CalendarView.swift            — Month calendar grid with EventKit integration
      StatsView.swift               — Statistics dashboard with Swift Charts
      PomodoroView.swift            — Focus timer with ring, controls, task picker + mini toolbar view
      CommandPalette.swift          — Cmd+K command palette with fuzzy search
      NewProjectView.swift          — New project sheet
      TagEditor.swift               — New tag sheet
      BulkActionBar.swift           — Multi-select action bar
      CelebrationOverlay.swift      — Motivational quote popup + confetti particles
      Settings/
        SettingsView.swift          — Settings window (General, Focus, Integrations, Data)
    Services/
      CalendarService.swift         — EventKit calendar wrapper
      RemindersService.swift        — EventKit reminders wrapper
      NotificationService.swift     — UNUserNotificationCenter wrapper
    Utilities/
      NaturalDateParser.swift       — "Buy milk tomorrow 3pm !!" parser
    Theme/
      BarbieTheme.swift             — Color palette, dark mode, button styles
  BarbieTasksWidget/
    BarbieTasksWidget.swift         — WidgetKit small + medium widgets
```

## Setup

### 1. Create the Main App Target

1. Open **Xcode** → File → New → Project
2. Choose **macOS → App**
3. Settings:
   - Product Name: `BarbieTasks`
   - Organization Identifier: your reverse domain (e.g. `com.yourname`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests"
4. Save the project to the `BarbieTasks/` folder (where this file is)

5. **Delete** the auto-generated files Xcode created:
   - `ContentView.swift`
   - `BarbieTasksApp.swift`
   - (Right-click → Delete → Move to Trash)

6. **Drag the `BarbieTasks/BarbieTasks/` subfolder** (containing App/, Models/, Views/, etc.) into the Xcode project navigator
   - When prompted: check "Copy items if needed" and "Create groups"
   - Make sure the target `BarbieTasks` is checked

### 2. Add Required Frameworks

In your target's **General → Frameworks, Libraries, and Embedded Content**, add:
- `EventKit.framework` (Calendar + Reminders)
- `WidgetKit.framework` (only needed if adding widget target)

These are also imported at the source level, but adding them explicitly ensures linking.

### 3. Add Entitlements

In **Signing & Capabilities**, add:

| Capability | Purpose |
|-----------|---------|
| **App Sandbox** | Required for App Store (already default) |
| **Calendars** (Read/Write) | Apple Calendar integration |
| **Reminders** (Read/Write) | Apple Reminders sync |
| **User Notifications** | Task reminders and pomodoro alerts |
| **App Groups** | Share data between app and widget |

For the **App Sandbox** entitlements, enable:
- `com.apple.security.personal-information.calendars` — Calendar access
- Outgoing Connections (Client) — if you want any network features later

For **App Groups**, create a group like `group.com.yourname.BarbieTasks`.

### 4. Add the Widget Target (Optional)

1. File → New → Target → **macOS Widget Extension**
2. Product Name: `BarbieTasksWidget`
3. Uncheck "Include Configuration App Intent"
4. Delete the auto-generated widget files
5. Add `BarbieTasksWidget.swift` from the `BarbieTasksWidget/` folder
6. In the widget target's Signing & Capabilities, add the **same App Group** as the main app

> **Note**: For the widget to read task data, you'll need to update `Store.swift` to write to the shared App Group container instead of the regular Application Support directory. Change `FileManager.default.urls(for: .applicationSupportDirectory, ...)` to `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourname.BarbieTasks")` in both the app and widget.

### 5. Info.plist Additions

Add these keys to your `Info.plist` (or target Info tab):

```xml
<key>NSCalendarsUsageDescription</key>
<string>Barbie Tasks shows your calendar events alongside tasks.</string>
<key>NSRemindersUsageDescription</key>
<string>Barbie Tasks can import and sync with Apple Reminders.</string>
```

### 6. Build & Run (Cmd + R)

## Features

### Smart Lists
- **Inbox** — tasks with no project (capture bucket)
- **Today** — due today + overdue
- **Upcoming** — all tasks with due dates, grouped by date
- **Calendar** — month view with EventKit integration
- **All Tasks** — everything
- **Logbook** — completed history
- **Trash** — soft-delete with undo

### Task Properties
- Title, notes, due date & time
- Priority (None / Low / Medium / High)
- Project assignment + tag assignment
- Subtasks with progress tracking
- Recurrence rules (daily/weekly/monthly/yearly)
- File attachments + URL links
- Pomodoro session count
- Reminder offset (5/15/30/60 min before, or at time)
- Calendar event sync (add/remove from Apple Calendar)

### Organization
- Custom projects with color coding
- Custom tags with color coding
- Right-click tasks for quick actions (priority, project, date)
- Sort by: Manual, Due Date, Priority, A-Z, Newest
- Show/hide completed toggle
- Multi-select with Cmd+click, bulk actions (complete, priority, move, trash)
- Drag and drop reordering

### Natural Language Input
- `Buy milk tomorrow 3pm !!` → title: "Buy milk", due: tomorrow 3pm, priority: high
- `Meeting #work @urgent next monday` → assigns project "work", tag "urgent", due: next Monday
- Supports: today, tomorrow, next week, weekday names, time parsing

### Focus Timer (Pomodoro)
- Configurable work/break durations
- Session tracking per task
- Visual progress ring
- Mini toolbar indicator during sessions
- Notifications on phase transitions
- Auto-start breaks option

### Statistics Dashboard
- Current streak, completed today, total completed, daily average
- 14-day completion bar chart (Swift Charts)
- Completion by project horizontal bar chart

### Command Palette (Cmd+K)
- Fuzzy search across tasks, projects, tags
- Quick actions: new task/project/tag, switch views, toggle dark mode, open settings
- Keyboard navigation (arrow keys + Enter)

### Integrations
- **Apple Calendar**: View events alongside tasks in Calendar view, add tasks to calendar
- **Apple Reminders**: Import reminder lists, sync completion status
- **Notifications**: Task reminders with complete/snooze actions

### Widget (WidgetKit)
- **Small**: Today task count + up to 4 task titles with priority dots
- **Medium**: Progress ring (completed/total) + up to 5 tasks
- Blush pink theme, 15-minute auto-refresh

### Menu Bar Quick-Add
- Always-accessible menu bar icon
- Quick text field to add tasks
- Shows today's upcoming tasks

### UX
- Three-panel layout (sidebar / list / detail)
- Dark mode with deep plum palette
- Confetti celebration on task completion
- Motivational Barbie-themed quotes
- Undo toast on delete (5-second window)
- URL scheme: `barbietasks://add?title=...` and `barbietasks://show?view=today`

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd + N | New task (focus quick-add) |
| Cmd + Shift + N | New project |
| Cmd + F | Search |
| Cmd + K | Command palette |
| Cmd + 1 | Switch to Inbox |
| Cmd + 2 | Switch to Today |
| Cmd + 3 | Switch to Upcoming |
| Cmd + 4 | Switch to All Tasks |
| Cmd + , | Settings |
| Escape | Deselect / close palette |
| Cmd + Click | Multi-select tasks |

## Data Storage
- **Location**: `~/Library/Application Support/BarbieTasks/data.json`
- **Format**: JSON (tasks, projects, tags, pomodoro sessions, view state)
- **Backup**: Settings → Data → Export as JSON
- **Restore**: Settings → Data → Import from JSON (replaces all data)
- Auto-saves on every change

## To Distribute
1. Product → Archive in Xcode
2. Distribute App → Copy App (for direct distribution)
3. Drop the .app into /Applications

## Customization
- **Colors**: `Theme/BarbieTheme.swift` — full palette with light/dark variants
- **Quotes**: `Models/SmartList.swift` — `inspirationalQuotes` array
- **App icon**: Add to Assets.xcassets in Xcode (1024x1024 pink icon recommended)
- **Pomodoro defaults**: `Models/AppSettings.swift` — default durations
- **Widget refresh**: `BarbieTasksWidget.swift` — change the 15-minute interval
