import SwiftUI

/// Shared navigation destination for task detail routing.
/// Attach to any view inside a NavigationStack to handle NavigationLink(value: TaskItem).
struct TaskNavigationDestination: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: TaskItem.self) { task in
                if task.isNote {
                    NoteEditorView(note: task)
                } else {
                    TaskDetailView(task: task)
                }
            }
    }
}

extension View {
    func taskNavigationDestination() -> some View {
        modifier(TaskNavigationDestination())
    }
}
