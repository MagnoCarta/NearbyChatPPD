import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    let userID: UUID
    let contact: Contact

    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages) { message in
                    HStack {
                        if message.senderID == userID {
                            Spacer()
                            Text(message.content)
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Text(message.content)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            HStack {
                TextField("Message", text: $viewModel.draft)
                Button("Send") {
                    viewModel.sendMessage(from: userID, to: contact.id)
                }
                .disabled(viewModel.draft.isEmpty)
            }
            .padding()
        }
        .navigationTitle(contact.name)
        .onAppear {
            viewModel.loadConversation(userID: userID, contactID: contact.id)
            Task { @APIActor in
                await viewModel.fetchHistory(userID: userID, contactID: contact.id)
                await viewModel.fetchQueuedMessages(for: userID, contactID: contact.id)
            }
        }
    }
}

#Preview {
    let chatVM = ChatViewModel()
    let user = User(username: "Me", location: .init(latitude: 0, longitude: 0))
    let contact = Contact(name: "Friend", location: user.location)
    chatVM.messages = [
        Message(senderID: user.id, receiverID: contact.id, content: "Hello"),
        Message(senderID: contact.id, receiverID: user.id, content: "Hi there!")
    ]
    return NavigationStack {
        ChatView(viewModel: chatVM, userID: user.id, contact: contact)
    }
}
