import SwiftUI

struct AllContactsView: View {
    @Bindable var contactsViewModel: ContactsViewModel
    @Bindable var chatViewModel: ChatViewModel
    let userID: UUID

    var body: some View {
        List(contactsViewModel.allContacts.filter { $0.id != userID }) { contact in
            NavigationLink(destination: ChatView(viewModel: chatViewModel, userID: userID, contact: contact)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(contact.name)
                        if let distance = contact.distance {
                            Text("\(distance) m")
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
        .navigationTitle("Contacts")
    }
}

#Preview {
    let contactsVM = ContactsViewModel()
    let chatVM = ChatViewModel()
    let me = User(username: "Me", location: .init(latitude: 0, longitude: 0))
    contactsVM.allContacts = [
        Contact(name: "Alice", location: me.location, isOnline: true, distance: 10),
        Contact(name: "Bob", location: me.location, isOnline: false, distance: 100)
    ]
    return NavigationStack {
        AllContactsView(contactsViewModel: contactsVM, chatViewModel: chatVM, userID: me.id)
    }
}
