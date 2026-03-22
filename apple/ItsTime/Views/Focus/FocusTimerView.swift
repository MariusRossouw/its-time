import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    private var activeTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo }
    }

    @State private var timerMode: TimerMode = .pomodoro
    @State private var selectedTask: TaskItem?
    @State private var isRunning = false
    @State private var elapsedSeconds = 0
    @State private var pomodoroCount = 0
    @State private var currentSession: FocusSession?
    @State private var timer: Timer?
    @State private var showTaskPicker = false
    @State private var showStats = false

    @AppStorage("focusDuration") private var pomodoroMinutes = 25
    @AppStorage("shortBreakDuration") private var shortBreakMinutes = 5
    @AppStorage("longBreakDuration") private var longBreakMinutes = 15

    private var totalSeconds: Int {
        switch timerMode {
        case .pomodoro: return pomodoroMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        case .stopwatch: return 0
        }
    }

    private var remainingSeconds: Int {
        if timerMode == .stopwatch { return elapsedSeconds }
        return max(totalSeconds - elapsedSeconds, 0)
    }

    private var progress: Double {
        if timerMode == .stopwatch { return 0 }
        guard totalSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(totalSeconds)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                modePicker
                Spacer()
                timerRing
                Spacer()
                taskLinkButton
                controlButtons
                Spacer()
            }
            .padding()
            .navigationTitle("Focus")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showStats = true } label: {
                        Image(systemName: "chart.bar")
                    }
                }
            }
            .sheet(isPresented: $showTaskPicker) {
                FocusTaskPickerSheet(
                    tasks: activeTasks,
                    selectedTask: $selectedTask,
                    isPresented: $showTaskPicker
                )
            }
            .sheet(isPresented: $showStats) {
                NavigationStack {
                    FocusStatsView()
                }
            }
        }
    }

    // MARK: - Subviews

    private var modePicker: some View {
        Picker("Mode", selection: $timerMode) {
            Text("Focus").tag(TimerMode.pomodoro)
            Text("Stopwatch").tag(TimerMode.stopwatch)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .disabled(isRunning)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                .frame(width: 240, height: 240)

            if timerMode != .stopwatch {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }

            timerDisplay
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(timeString(remainingSeconds))
                .font(.system(size: 48, weight: .light, design: .monospaced))

            if timerMode == .pomodoro {
                Text(sessionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if timerMode == .pomodoro {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < pomodoroCount % 4 ? Color.accentColor : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private var taskLinkButton: some View {
        Button { showTaskPicker = true } label: {
            HStack {
                Image(systemName: "link")
                Text(selectedTask?.title ?? "Link a task")
                    .lineLimit(1)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.15))
            .clipShape(Capsule())
        }
        .disabled(isRunning)
    }

    private var controlButtons: some View {
        HStack(spacing: 32) {
            Button { resetTimer() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            .disabled(!isRunning && elapsedSeconds == 0)

            Button {
                if isRunning { pauseTimer() } else { startTimer() }
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(timerColor)
                    .clipShape(Circle())
            }

            Button { skipSession() } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            .disabled(timerMode == .stopwatch)
        }
    }

    // MARK: - Helpers

    private var timerColor: Color {
        switch timerMode {
        case .pomodoro: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        case .stopwatch: return .orange
        }
    }

    private var sessionLabel: String {
        switch timerMode {
        case .pomodoro: return "Focus Session"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .stopwatch: return ""
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        if currentSession == nil {
            let sessionType: FocusSessionType = timerMode == .stopwatch ? .stopwatch : .pomodoro
            let planned = timerMode == .stopwatch ? 0 : totalSeconds
            let session = FocusSession(plannedDuration: planned, sessionType: sessionType, task: selectedTask)
            modelContext.insert(session)
            currentSession = session
        }

        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsedSeconds += 1
                if timerMode != .stopwatch && elapsedSeconds >= totalSeconds {
                    completeSession()
                }
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        currentSession?.cancel()
        currentSession = nil
        elapsedSeconds = 0
    }

    private func completeSession() {
        pauseTimer()
        currentSession?.complete()
        currentSession = nil
        elapsedSeconds = 0

        if timerMode == .pomodoro {
            pomodoroCount += 1
            timerMode = pomodoroCount % 4 == 0 ? .longBreak : .shortBreak
        } else if timerMode == .shortBreak || timerMode == .longBreak {
            timerMode = .pomodoro
        }
    }

    private func skipSession() {
        resetTimer()
        timerMode = timerMode == .pomodoro ? .shortBreak : .pomodoro
    }
}

// MARK: - Task Picker Sheet

struct FocusTaskPickerSheet: View {
    let tasks: [TaskItem]
    @Binding var selectedTask: TaskItem?
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedTask = nil
                    isPresented = false
                } label: {
                    Text("No task").foregroundStyle(.secondary)
                }

                ForEach(tasks) { task in
                    Button {
                        selectedTask = task
                        isPresented = false
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.priorityColor(task.priority))
                                .frame(width: 8, height: 8)
                            Text(task.title).lineLimit(1)
                            Spacer()
                            if selectedTask?.id == task.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Link Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

enum TimerMode: String, CaseIterable {
    case pomodoro
    case shortBreak
    case longBreak
    case stopwatch
}
