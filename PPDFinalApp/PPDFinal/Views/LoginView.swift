import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                TextField("Username", text: $username)
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                Button("Login") {
                    viewModel.username = username
                    viewModel.login()
                }
                .disabled(username.isEmpty)
                Button("Register") {
                    viewModel.username = username
                    viewModel.register()
                }
                .disabled(username.isEmpty)
            }
            .navigationTitle("Login")
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
