import SwiftUI

// MARK: - Custom Barbie Icons

/// Bespoke icon set for Barbie Tasks.
/// Each icon is a small SwiftUI composition with gradient fills,
/// layered shapes, or custom paths for a cohesive, polished look.
enum BarbieIcon {

    // MARK: - Sidebar / Smart List Icons

    /// Inbox — layered tray with gradient
    struct Inbox: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Image(systemName: "tray.fill")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.barbieRose, Color.barbiePink],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Today — stylised star with pink core
    struct Today: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Image(systemName: "sparkle")
                    .font(.system(size: size + 2, weight: .medium))
                    .foregroundStyle(Color.petal.opacity(0.5))
                    .offset(x: 1, y: 1)
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.barbiePink, Color.barbieDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Upcoming — clock with gradient hand
    struct Upcoming: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Image(systemName: "clock")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(Color.barbieRose)
                Circle()
                    .fill(Color.barbiePink)
                    .frame(width: size * 0.2, height: size * 0.2)
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Calendar — custom layered calendar page
    struct CalendarIcon: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(Color.blushMid)
                    .frame(width: size, height: size)
                RoundedRectangle(cornerRadius: size * 0.15)
                    .stroke(Color.barbieRose, lineWidth: 1.2)
                    .frame(width: size, height: size)
                // Top bar
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.barbiePink)
                    .frame(width: size, height: size * 0.22)
                    .offset(y: -size * 0.39)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
                // Dots grid
                HStack(spacing: size * 0.08) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.barbieRose.opacity(0.5))
                            .frame(width: size * 0.12, height: size * 0.12)
                    }
                }
                .offset(y: size * 0.12)
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// All Tasks — stylised list with gradient bullets
    struct AllTasks: View {
        var size: CGFloat = 16
        var body: some View {
            VStack(alignment: .leading, spacing: size * 0.12) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: size * 0.12) {
                        Circle()
                            .fill(
                                [Color.barbiePink, Color.barbieRose, Color.petal][i]
                            )
                            .frame(width: size * 0.18, height: size * 0.18)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.inkMuted.opacity(0.3))
                            .frame(width: size * [0.6, 0.45, 0.55][i], height: size * 0.1)
                    }
                }
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Logbook — elegant book with spine
    struct Logbook: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.barbieRose, Color.roseGold],
                                       startPoint: .leading, endPoint: .trailing)
                    )
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Trash — refined trash can
    struct Trash: View {
        var size: CGFloat = 16
        var body: some View {
            Image(systemName: "trash")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(Color.inkMuted)
                .frame(width: size + 4, height: size + 4)
                .accessibilityHidden(true)
        }
    }

    /// Statistics — chart with gradient bars
    struct Stats: View {
        var size: CGFloat = 16
        var body: some View {
            HStack(alignment: .bottom, spacing: size * 0.1) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: size * 0.06)
                        .fill(
                            LinearGradient(
                                colors: [Color.barbiePink.opacity(0.5), Color.barbiePink],
                                startPoint: .bottom, endPoint: .top
                            )
                        )
                        .frame(
                            width: size * 0.2,
                            height: size * [0.4, 0.7, 0.55][i]
                        )
                }
            }
            .frame(width: size + 4, height: size + 4, alignment: .bottom)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Project / Tag Icons

    /// Project folder with colored accent
    struct Project: View {
        var color: Color = .barbiePink
        var size: CGFloat = 14
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "folder.fill")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(color.opacity(0.8))
                Circle()
                    .fill(color)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: size * 0.05, y: -size * 0.05)
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Tag — filled with color
    struct Tag: View {
        var color: Color = .barbieRose
        var size: CGFloat = 14
        var body: some View {
            Image(systemName: "tag.fill")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(color.opacity(0.8))
                .frame(width: size + 4, height: size + 4)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Priority Icons

    /// Priority indicator — a diamond shape filled with priority color
    struct Priority: View {
        var priority: BarbieTask.Priority
        var size: CGFloat = 10
        var body: some View {
            Group {
                switch priority {
                case .high:
                    Image(systemName: "chevron.up.2")
                        .font(.system(size: size, weight: .bold))
                        .foregroundStyle(Color.priHigh)
                case .medium:
                    Image(systemName: "chevron.up")
                        .font(.system(size: size, weight: .bold))
                        .foregroundStyle(Color.priMed)
                case .low:
                    Image(systemName: "minus")
                        .font(.system(size: size, weight: .bold))
                        .foregroundStyle(Color.priLow)
                case .none:
                    EmptyView()
                }
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: - Action Icons

    /// Quick add — plus in a gradient circle
    struct QuickAdd: View {
        var size: CGFloat = 18
        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.barbiePink, Color.barbieDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: size, height: size)
                Image(systemName: "plus")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
        }
    }

    /// Checkmark — completion badge
    struct Completed: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.barbiePink, Color.barbieDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: size, height: size)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
        }
    }

    /// Timer — pomodoro with gradient
    struct Timer: View {
        var size: CGFloat = 16
        var body: some View {
            Image(systemName: "timer")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: [Color.barbiePink, Color.barbieRose],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size + 4, height: size + 4)
                .accessibilityHidden(true)
        }
    }

    /// Template — layered doc
    struct Template: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: size * 0.9, weight: .medium))
                    .foregroundStyle(Color.petal)
                    .offset(x: 1.5, y: 1.5)
                Image(systemName: "doc.fill")
                    .font(.system(size: size * 0.85, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.barbieRose, Color.barbiePink],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Routines — repeat circle with gradient
    struct Routines: View {
        var size: CGFloat = 16
        var body: some View {
            ZStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.barbiePink, Color.barbieRose],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
        }
    }

    /// Command palette — magnifying glass with gradient
    struct Search: View {
        var size: CGFloat = 16
        var body: some View {
            Image(systemName: "magnifyingglass")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(colors: [Color.barbiePink, Color.barbieRose],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: size + 4, height: size + 4)
                .accessibilityHidden(true)
        }
    }

    /// Kanban board — three columns
    struct Kanban: View {
        var size: CGFloat = 16
        var body: some View {
            HStack(spacing: size * 0.06) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: size * 0.08)
                        .fill(
                            [Color.petal, Color.barbiePink, Color.barbieRose][i]
                        )
                        .frame(width: size * 0.25, height: size * [0.7, 0.85, 0.55][i])
                }
            }
            .frame(width: size + 4, height: size + 4, alignment: .center)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Empty State Icons

    /// Large decorative icon for empty states
    struct EmptyState: View {
        let systemName: String
        var size: CGFloat = 40

        var body: some View {
            ZStack {
                // Soft glow behind
                Circle()
                    .fill(Color.barbiePink.opacity(0.08))
                    .frame(width: size * 1.8, height: size * 1.8)

                // Ring
                Circle()
                    .stroke(Color.petal, lineWidth: 1)
                    .frame(width: size * 1.4, height: size * 1.4)

                // Icon
                Image(systemName: systemName)
                    .font(.system(size: size, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.barbiePink.opacity(0.6), Color.barbieRose.opacity(0.4)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            .accessibilityHidden(true)
        }
    }
}
