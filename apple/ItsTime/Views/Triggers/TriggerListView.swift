import SwiftUI
import SwiftData

struct TriggerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trigger.sortOrder) private var triggers: [Trigger]

    @State private var showNewTrigger = false
    @State private var showLog = false

    var body: some View {
        List {
            if triggers.isEmpty {
                ContentUnavailableView(
                    "No Automations",
                    systemImage: "bolt.circle",
                    description: Text("Create triggers to automate actions when events happen.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(triggers) { trigger in
                    NavigationLink(value: trigger) {
                        TriggerRowView(trigger: trigger)
                    }
                }
                .onDelete { offsets in
                    for i in offsets { modelContext.delete(triggers[i]) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Automations")
        .navigationDestination(for: Trigger.self) { trigger in
            TriggerEditorView(trigger: trigger)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button { showLog = true } label: {
                        Image(systemName: "list.bullet.clipboard")
                    }
                    Button { showNewTrigger = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityIdentifier("new_automation_button")
                }
            }
        }
        .sheet(isPresented: $showNewTrigger) {
            NavigationStack {
                TriggerEditorView()
            }
        }
        .sheet(isPresented: $showLog) {
            NavigationStack {
                TriggerLogView()
            }
        }
    }
}

struct TriggerRowView: View {
    @Bindable var trigger: Trigger

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trigger.triggerType.icon)
                .font(.title3)
                .foregroundStyle(trigger.isEnabled ? .blue : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(trigger.name)
                    .font(.body)
                    .foregroundStyle(trigger.isEnabled ? .primary : .secondary)
                HStack(spacing: 6) {
                    Text(trigger.triggerType.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !trigger.actions.isEmpty {
                        Text("\(trigger.actions.count) action\(trigger.actions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { trigger.isEnabled },
                set: { trigger.isEnabled = $0; trigger.updatedAt = Date() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}
