import SwiftUI
import SwiftData

struct FilterEditorView: View {
    var filter: CustomFilter?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]

    @State private var name = ""
    @State private var icon = "line.3.horizontal.decrease.circle"
    @State private var color = "#007AFF"
    @State private var matchAll = true
    @State private var rules: [FilterRule] = []

    private var isEditing: Bool { filter != nil }

    private let colorOptions = [
        "#007AFF", "#34C759", "#FF3B30", "#FF9500",
        "#AF52DE", "#5856D6", "#FF2D55", "#00C7BE"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Filter name", text: $name)
                    HStack(spacing: 8) {
                        ForEach(colorOptions, id: \.self) { c in
                            Button {
                                color = c
                            } label: {
                                Circle()
                                    .fill(Color(hex: c))
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        if c == color {
                                            Circle().stroke(.white, lineWidth: 2).frame(width: 18, height: 18)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Picker("Match", selection: $matchAll) {
                        Text("All rules (AND)").tag(true)
                        Text("Any rule (OR)").tag(false)
                    }
                }

                Section("Rules") {
                    ForEach($rules) { $rule in
                        ruleRow(rule: $rule)
                    }
                    .onDelete { offsets in
                        rules.remove(atOffsets: offsets)
                    }

                    Button("Add Rule", systemImage: "plus.circle") {
                        rules.append(FilterRule(field: .priority, op: .equals, value: "high"))
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Filter" : "New Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let filter {
                    name = filter.name
                    icon = filter.icon
                    color = filter.color
                    matchAll = filter.matchAll
                    rules = filter.rules
                }
            }
        }
    }

    @ViewBuilder
    private func ruleRow(rule: Binding<FilterRule>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Field", selection: rule.field) {
                    ForEach(FilterField.allCases, id: \.self) { field in
                        Text(field.label).tag(field)
                    }
                }
                .labelsHidden()

                Picker("Op", selection: rule.op) {
                    ForEach(opsForField(rule.wrappedValue.field), id: \.self) { op in
                        Text(op.label).tag(op)
                    }
                }
                .labelsHidden()
            }

            valueField(rule: rule)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func valueField(rule: Binding<FilterRule>) -> some View {
        switch rule.wrappedValue.field {
        case .priority:
            Picker("Value", selection: rule.value) {
                ForEach(TaskPriority.allCases, id: \.rawValue) { p in
                    Text(p.rawValue.capitalized).tag(p.rawValue)
                }
            }
            .labelsHidden()
        case .status:
            Picker("Value", selection: rule.value) {
                ForEach(TaskStatus.allCases, id: \.rawValue) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            }
            .labelsHidden()
        case .dueDate:
            Picker("Value", selection: rule.value) {
                Text("Today").tag("today")
                Text("Tomorrow").tag("tomorrow")
                Text("This Week").tag("thisWeek")
                Text("Overdue").tag("overdue")
                Text("No Date").tag("none")
            }
            .labelsHidden()
        case .tag:
            Picker("Value", selection: rule.value) {
                ForEach(tags) { tag in
                    Text(tag.name).tag(tag.name)
                }
            }
            .labelsHidden()
        case .list:
            Picker("Value", selection: rule.value) {
                ForEach(lists) { list in
                    Text(list.name).tag(list.name)
                }
            }
            .labelsHidden()
        case .title:
            TextField("Contains...", text: rule.value)
        case .isNote:
            Picker("Value", selection: rule.value) {
                Text("Yes").tag("true")
                Text("No").tag("false")
            }
            .labelsHidden()
        case .timePreference:
            Picker("Value", selection: rule.value) {
                ForEach(TimePreference.allCases, id: \.rawValue) { p in
                    Text(p.label).tag(p.rawValue)
                }
            }
            .labelsHidden()
        case .isRecurring:
            Picker("Value", selection: rule.value) {
                Text("Yes").tag("true")
                Text("No").tag("false")
            }
            .labelsHidden()
        }
    }

    private func opsForField(_ field: FilterField) -> [FilterOp] {
        switch field {
        case .dueDate: return [.equals, .notEquals, .before, .after]
        case .title: return [.contains, .notEquals]
        case .isNote, .isRecurring: return [.equals]
        default: return [.equals, .notEquals]
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let filter {
            filter.name = trimmed
            filter.icon = icon
            filter.color = color
            filter.matchAll = matchAll
            filter.rules = rules
            filter.updatedAt = Date()
        } else {
            let newFilter = CustomFilter(name: trimmed, color: color, matchAll: matchAll)
            newFilter.rules = rules
            modelContext.insert(newFilter)
        }

        dismiss()
    }
}
