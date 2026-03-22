import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var email = ""
    @State private var selectedColor = "#007AFF"

    private let colors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#5856D6", "#AF52DE",
        "#FF2D55", "#A2845E", "#8E8E93", "#30B0C7"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text("Welcome to Its Time")
                    .font(.largeTitle.bold())

                Text("Set up your profile so collaborators know who you are.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("Display name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("onboarding_name_field")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email (optional)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("email@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("onboarding_email_field")
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Pick a Color")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .accessibilityIdentifier("color_\(color)")
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .accessibilityIdentifier("onboarding_color_grid")
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Get Started button
            Button {
                createProfile()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityIdentifier("onboarding_get_started")
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private func createProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let collab = Collaborator(
            name: trimmedName,
            email: email.trimmingCharacters(in: .whitespaces),
            color: selectedColor,
            isCurrentUser: true
        )
        modelContext.insert(collab)
    }
}
