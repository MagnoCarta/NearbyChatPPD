import SwiftUI

struct SettingsView: View {
    /// Shared settings controlling radius and notification preferences.
    @Binding var settings: Settings

    var body: some View {
        Form {
            Stepper(value: $settings.radius, in: 0...5000, step: 100) {
                Text("Radius: \(Int(settings.radius)) m")
            }
            Toggle("Notifications", isOn: $settings.notificationsEnabled)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: .constant(Settings()))
    }
}
