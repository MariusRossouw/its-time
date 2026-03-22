import SwiftUI

struct SyncConflict: Identifiable {
    let id = UUID()
    let taskId: UUID
    let taskTitle: String
    let field: String
    let localValue: String
    let remoteValue: String
    let localDevice: String
    let remoteDevice: String
    let localUpdatedAt: Date
    let remoteUpdatedAt: Date
}

enum ConflictResolution {
    case keepLocal
    case keepRemote
}

struct ConflictResolutionView: View {
    let conflicts: [SyncConflict]
    var onResolve: (SyncConflict, ConflictResolution) -> Void
    var onResolveAll: (ConflictResolution) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if conflicts.isEmpty {
                    ContentUnavailableView {
                        Label("No Conflicts", systemImage: "checkmark.circle")
                    } description: {
                        Text("All data is in sync.")
                    }
                } else {
                    Section {
                        HStack {
                            Button("Keep All Local") {
                                onResolveAll(.keepLocal)
                                dismiss()
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button("Keep All Remote") {
                                onResolveAll(.keepRemote)
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    ForEach(conflicts) { conflict in
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(conflict.taskTitle)
                                    .font(.headline)

                                Text("Field: \(conflict.field)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 16) {
                                    // Local version
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "iphone")
                                                .font(.caption)
                                            Text("Local")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(.blue)

                                        Text(conflict.localValue)
                                            .font(.subheadline)
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(.blue.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Text(conflict.localUpdatedAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    // Remote version
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "cloud")
                                                .font(.caption)
                                            Text("Remote")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(.green)

                                        Text(conflict.remoteValue)
                                            .font(.subheadline)
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(.green.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Text(conflict.remoteUpdatedAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                HStack {
                                    Button {
                                        onResolve(conflict, .keepLocal)
                                    } label: {
                                        Label("Keep Local", systemImage: "iphone")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)

                                    Spacer()

                                    Button {
                                        onResolve(conflict, .keepRemote)
                                    } label: {
                                        Label("Keep Remote", systemImage: "cloud")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Resolve Conflicts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
