import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var webSocketService: WebSocketService
    @State private var contactsViewModel: ContactsViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var locationViewModel = LocationViewModel()
    @State private var settings = Settings()

    init() {
        let service = WebSocketService(baseURL: URL(string: "ws://127.0.0.1:8080/chat")!)
        _webSocketService = State(initialValue: service)
        _contactsViewModel = State(initialValue: ContactsViewModel(webSocketService: service))
        _chatViewModel = State(initialValue: ChatViewModel(webSocketService: service))
    }

    var body: some View {
        Group {
            if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                TabView {
                    NavigationStack {
                        AroundContactsView(contactsViewModel: contactsViewModel,
                                           chatViewModel: chatViewModel,
                                           locationViewModel: locationViewModel,
                                           settings: $settings,
                                           userID: user.id,
                                           username: user.username)
                    }
                    .tabItem {
                        Label("Around", systemImage: "location")
                    }

                    NavigationStack {
                        AllContactsView(contactsViewModel: contactsViewModel,
                                        chatViewModel: chatViewModel,
                                        userID: user.id)
                    }
                    .tabItem {
                        Label("Contacts", systemImage: "person.2")
                    }

                    NavigationStack {
                        SettingsView(settings: $settings)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }
                .onAppear {
                    locationViewModel.startUpdates()
                    locationViewModel.bindToBroker(user: user, settings: settings)
                    Task { @WebSocketActor in
                        await chatViewModel.connect(userID: user.id)
                    }
                }
                .onDisappear {
                    locationViewModel.stopUpdates()
                    Task { @WebSocketActor in
                        await chatViewModel.disconnect()
                    }
                }
                .onChange(of: settings.radius) { newValue in
                    locationViewModel.updateRadius(newValue)
                    contactsViewModel.radiusDidUpdate(newValue)
                }
                .onChange(of: locationViewModel.lastLocation) { newValue in
                    if let coord = newValue?.coordinate {
                        let loc = Location(latitude: coord.latitude, longitude: coord.longitude)
                        contactsViewModel.locationDidUpdate(loc)
                    }
                }
            } else {
                LoginView(viewModel: authViewModel)
                    .onAppear {
                        locationViewModel.startUpdates()
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
