import SwiftUI
import SwiftData

struct EisenhowerMatrixView: View {
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    private let calendar = Calendar.current

    private var activeTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && !$0.isNote }
    }

    // Urgent = due within 2 days or overdue
    private func isUrgent(_ task: TaskItem) -> Bool {
        guard let due = task.dueDate else { return false }
        let twoDays = calendar.date(byAdding: .day, value: 2, to: Date())!
        return due <= twoDays
    }

    // Important = high or medium priority
    private func isImportant(_ task: TaskItem) -> Bool {
        task.priority == .high || task.priority == .medium
    }

    private var doFirst: [TaskItem] { // urgent + important
        activeTasks.filter { isUrgent($0) && isImportant($0) }
    }

    private var schedule: [TaskItem] { // not urgent + important
        activeTasks.filter { !isUrgent($0) && isImportant($0) }
    }

    private var delegate: [TaskItem] { // urgent + not important
        activeTasks.filter { isUrgent($0) && !isImportant($0) }
    }

    private var eliminate: [TaskItem] { // not urgent + not important
        activeTasks.filter { !isUrgent($0) && !isImportant($0) }
    }

    var body: some View {
        GeometryReader { geo in
            let halfHeight = max(1, (geo.size.height - 40) / 2) // reserve space for headers

            VStack(spacing: 0) {
                // Column headers
                HStack(spacing: 0) {
                    Spacer().frame(width: 28)
                    Text("Urgent")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Not Urgent")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.bottom, 4)

                HStack(spacing: 0) {
                    // Row headers
                    VStack(spacing: 0) {
                        Text("Important")
                            .font(.caption.bold())
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 24, height: halfHeight)
                        Text("Not\nImportant")
                            .font(.caption.bold())
                            .multilineTextAlignment(.center)
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 24, height: halfHeight)
                    }
                    .frame(width: 24)

                    // Grid
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            quadrant(
                                title: "Do First",
                                icon: "flame.fill",
                                color: .red,
                                tasks: doFirst,
                                height: halfHeight
                            )
                            quadrant(
                                title: "Schedule",
                                icon: "calendar",
                                color: .blue,
                                tasks: schedule,
                                height: halfHeight
                            )
                        }
                        HStack(spacing: 2) {
                            quadrant(
                                title: "Delegate",
                                icon: "person.2",
                                color: .orange,
                                tasks: delegate,
                                height: halfHeight
                            )
                            quadrant(
                                title: "Eliminate",
                                icon: "trash",
                                color: .gray,
                                tasks: eliminate,
                                height: halfHeight
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Eisenhower Matrix")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func quadrant(title: String, icon: String, color: Color, tasks: [TaskItem], height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption.bold())
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Tasks
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(tasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            matrixTaskRow(task: task, color: color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: height)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func matrixTaskRow(task: TaskItem, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.priorityColor(task.priority))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.caption)
                    .lineLimit(1)
                if let due = task.dueDate {
                    Text(due, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
