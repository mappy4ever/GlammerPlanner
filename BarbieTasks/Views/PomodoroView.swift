import SwiftUI

// MARK: - Pomodoro Full View

struct PomodoroView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @State private var selectedTaskId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 20)
            timerRing
            Spacer(minLength: 16)
            phaseLabel
            Spacer(minLength: 8)
            sessionCounter
            Spacer(minLength: 24)
            controls
            Spacer(minLength: 24)
            taskPicker
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blush)
        .onAppear {
            selectedTaskId = store.pomodoroTaskId
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.barbiePink)
                Text("Focus Timer")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
            }

            if let task = associatedTask {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        let totalSeconds = totalSecondsForCurrentPhase
        let progress: Double = totalSeconds > 0
            ? Double(totalSeconds - store.pomodoroSecondsRemaining) / Double(totalSeconds)
            : 0

        return ZStack {
            // Track
            Circle()
                .stroke(Color.petalLight, lineWidth: 10)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.barbiePink, .barbieDeep, .barbiePink]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Inner glow circle
            Circle()
                .fill(Color.blushMid.opacity(0.4))
                .padding(18)

            // Time display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: store.pomodoroSecondsRemaining)
            }
        }
        .frame(width: 220, height: 220)
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            Text(phaseName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blushMid, in: Capsule())
    }

    // MARK: - Session Counter

    private var sessionCounter: some View {
        Group {
            if store.pomodoroPhase != .idle {
                HStack(spacing: 6) {
                    ForEach(0..<settings.pomSessionsBeforeLong, id: \.self) { i in
                        Circle()
                            .fill(i < store.pomodoroSessionCount % settings.pomSessionsBeforeLong
                                  ? Color.barbiePink
                                  : Color.petal)
                            .frame(width: 10, height: 10)
                    }
                }

                Text("Session \(currentSessionDisplay) of \(settings.pomSessionsBeforeLong)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .padding(.top, 4)
            } else {
                Text("\(settings.pomWorkMinutes) min focus \u{00B7} \(settings.pomShortBreak) min break")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            if store.pomodoroPhase == .idle {
                // Start button
                Button {
                    store.startPomodoro(taskId: selectedTaskId, settings: settings)
                } label: {
                    Label("Start Focus", systemImage: "play.fill")
                }
                .buttonStyle(ChicButtonStyle())
            } else {
                // Stop button
                Button {
                    store.stopPomodoro()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(ChicSecondaryButtonStyle())

                // Skip phase button
                Button {
                    store.skipPomodoroPhase(settings: settings)
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(ChicSecondaryButtonStyle())
            }
        }
    }

    // MARK: - Task Picker

    private var taskPicker: some View {
        VStack(spacing: 8) {
            Text("Associated Task")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)

            Menu {
                Button {
                    selectedTaskId = nil
                    if store.pomodoroPhase != .idle {
                        store.pomodoroTaskId = nil
                    }
                } label: {
                    Text("No Task")
                }

                Divider()

                ForEach(store.incompleteTasks) { task in
                    Button {
                        selectedTaskId = task.id
                        if store.pomodoroPhase != .idle {
                            store.pomodoroTaskId = task.id
                        }
                    } label: {
                        HStack {
                            Text(task.title)
                            if task.id == selectedTaskId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.barbiePink)

                    Text(selectedTaskLabel)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.inkMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.petal, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: 280)
        }
    }

    // MARK: - Helpers

    private var associatedTask: BarbieTask? {
        guard let id = store.pomodoroTaskId else { return nil }
        return store.tasks.first { $0.id == id }
    }

    private var selectedTaskLabel: String {
        if let id = selectedTaskId,
           let task = store.tasks.first(where: { $0.id == id }) {
            return task.title
        }
        return "No task selected"
    }

    private var formattedTime: String {
        let secs = store.pomodoroPhase == .idle
            ? settings.pomWorkMinutes * 60
            : store.pomodoroSecondsRemaining
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var phaseName: String {
        switch store.pomodoroPhase {
        case .idle:       "Ready"
        case .working:    "Focus"
        case .shortBreak: "Short Break"
        case .longBreak:  "Long Break"
        }
    }

    private var phaseColor: Color {
        switch store.pomodoroPhase {
        case .idle:       .inkMuted
        case .working:    .barbiePink
        case .shortBreak: .barbieRose
        case .longBreak:  .gold
        }
    }

    private var totalSecondsForCurrentPhase: Int {
        switch store.pomodoroPhase {
        case .idle:       settings.pomWorkMinutes * 60
        case .working:    settings.pomWorkMinutes * 60
        case .shortBreak: settings.pomShortBreak * 60
        case .longBreak:  settings.pomLongBreak * 60
        }
    }

    private var currentSessionDisplay: Int {
        let mod = store.pomodoroSessionCount % settings.pomSessionsBeforeLong
        return store.pomodoroPhase == .working ? mod + 1 : mod
    }
}

// MARK: - Pomodoro Mini View (Toolbar Compact)

struct PomodoroMiniView: View {
    @Environment(Store.self) private var store
    @State private var showPopover = false

    var body: some View {
        if store.pomodoroPhase != .idle {
            Button {
                showPopover.toggle()
            } label: {
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.petalLight, lineWidth: 3)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: miniProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.barbiePink, .barbieDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: miniProgress)
                }
                .frame(width: 30, height: 30)
                .overlay {
                    Text(abbreviatedTime)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .monospacedDigit()
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                PomodoroView()
                    .frame(width: 360, height: 520)
            }
            .help("Focus Timer — \(abbreviatedTime) remaining")
        }
    }

    // MARK: - Helpers

    private var miniProgress: Double {
        let total = totalSecondsForPhase
        guard total > 0 else { return 0 }
        return Double(total - store.pomodoroSecondsRemaining) / Double(total)
    }

    private var totalSecondsForPhase: Int {
        // We need settings but mini view may not always have it injected;
        // fall back to reading from the environment at call site.
        // Since this view is always within the app hierarchy, settings is available.
        switch store.pomodoroPhase {
        case .idle:       0
        case .working:    store.pomodoroSecondsRemaining // approximate: use remaining as denominator fallback
        case .shortBreak: store.pomodoroSecondsRemaining
        case .longBreak:  store.pomodoroSecondsRemaining
        }
    }

    private var abbreviatedTime: String {
        let m = store.pomodoroSecondsRemaining / 60
        let s = store.pomodoroSecondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Settings-aware Mini View

/// A wrapper that provides AppSettings for accurate progress calculation.
struct PomodoroMiniViewWithSettings: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        if store.pomodoroPhase != .idle {
            PomodoroMiniContent(
                phase: store.pomodoroPhase,
                secondsRemaining: store.pomodoroSecondsRemaining,
                totalSeconds: totalSecondsForCurrentPhase
            )
        }
    }

    private var totalSecondsForCurrentPhase: Int {
        switch store.pomodoroPhase {
        case .idle:       0
        case .working:    settings.pomWorkMinutes * 60
        case .shortBreak: settings.pomShortBreak * 60
        case .longBreak:  settings.pomLongBreak * 60
        }
    }
}

private struct PomodoroMiniContent: View {
    let phase: PomodoroPhase
    let secondsRemaining: Int
    let totalSeconds: Int
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.petalLight, lineWidth: 3)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.barbiePink, .barbieDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            .frame(width: 30, height: 30)
            .overlay {
                Text(abbreviatedTime)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                    .monospacedDigit()
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            PomodoroView()
                .frame(width: 360, height: 520)
        }
        .help("Focus Timer — \(abbreviatedTime) remaining")
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - secondsRemaining) / Double(totalSeconds)
    }

    private var abbreviatedTime: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
