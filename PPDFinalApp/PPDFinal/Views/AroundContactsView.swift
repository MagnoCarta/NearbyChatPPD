import SwiftUI

struct AroundContactsView: View {
    @Bindable var contactsViewModel: ContactsViewModel
    @Bindable var chatViewModel: ChatViewModel
    @Bindable var locationViewModel: LocationViewModel
    @Binding var settings: Settings
    let userID: UUID
    let username: String

    var body: some View {
        List(contactsViewModel.contacts) { contact in
            NavigationLink(destination: ChatView(viewModel: chatViewModel, userID: userID, contact: contact)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(contact.name)
                        if let distance = contact.distance {
                            Text("\(distance, specifier: "%.0f") m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(contact.isOnline ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .navigationTitle("Around")
        .onAppear {
            Task { await sync() }
        }
        .onChange(of: locationViewModel.lastLocation) { _ in
            Task { await sync() }
        }
        .onChange(of: settings.radius) { newRadius in
            contactsViewModel.radiusDidUpdate(newRadius)
            Task { await sync() }
        }
    }

    private func sync() async {
        guard let coordinate = locationViewModel.lastLocation?.coordinate else { return }
        let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
        contactsViewModel.locationDidUpdate(location)
        await contactsViewModel.syncContacts(userID: userID,
                                             name: username,
                                             location: location,
                                             radius: settings.radius)
    }
}

#Preview {
    let contactsVM = ContactsViewModel()
    let chatVM = ChatViewModel()
    let locationVM = LocationViewModel()
    let me = User(username: "Me", location: .init(latitude: 0, longitude: 0))
    contactsVM.contacts = [
        Contact(name: "Alice", location: me.location, isOnline: true, distance: 10),
        Contact(name: "Bob", location: me.location, isOnline: false, distance: 100)
    ]
    return NavigationStack {
        AroundContactsView(contactsViewModel: contactsVM,
                           chatViewModel: chatVM,
                           locationViewModel: locationVM,
                           settings: .constant(Settings()),
                           userID: me.id,
                           username: me.username)
    }
}
