import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @Environment(AccountSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var createAccount = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isBusy = false
    @State private var message: String?
    @State private var showSignOut = false

    var body: some View {
        NavigationStack {
            Form {
                if !session.isReady {
                    ProgressView("Loading account…")
                } else if let user = session.user {
                    Section("Your account") {
                        Label(user.email ?? "Signed in", systemImage: "person.crop.circle.fill")
                        Text("Your new reviews are linked to this account.")
                            .foregroundStyle(.secondary)
                    }
                    Section {
                        Button("Log out", role: .destructive) { showSignOut = true }
                    }
                } else {
                    Section {
                        Text("Welcome to MealScout")
                            .font(.title2.bold())
                        Text("Browse restaurants as a guest, or sign in to write reviews.")
                            .foregroundStyle(.secondary)
                        Picker("Account action", selection: $createAccount) {
                            Text("Log in").tag(false)
                            Text("Sign up").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Account details") {
                        TextField("Email", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("account.email")
                        SecureField("Password", text: $password)
                            .textContentType(createAccount ? .newPassword : .password)
                            .accessibilityIdentifier("account.password")
                        if createAccount {
                            SecureField("Confirm password", text: $confirmation)
                                .textContentType(.newPassword)
                            Text("Use at least 6 characters. Your project may require a stronger password.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        Button(createAccount ? "Create account" : "Log in") {
                            Task { await submit() }
                        }
                        .accessibilityIdentifier("account.submit")
                        if !createAccount {
                            Button("Forgot password?") { Task { await resetPassword() } }
                        }
                        if isBusy { ProgressView("Please wait…") }
                    }
                }
                if let message {
                    Section { Text(message).accessibilityIdentifier("account.message") }
                }
            }
            .disabled(isBusy)
            .navigationTitle(session.user == nil ? "Welcome" : "My account")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.disabled(isBusy)
                }
            }
            .interactiveDismissDisabled(isBusy)
            .onChange(of: createAccount) { _, _ in
                password = ""
                confirmation = ""
                message = nil
            }
            .confirmationDialog("Log out of MealScout?", isPresented: $showSignOut, titleVisibility: .visible) {
                Button("Log out", role: .destructive) {
                    do { try session.signOut(); password = ""; confirmation = ""; message = nil }
                    catch { message = error.localizedDescription }
                }
            }
        }
    }

    private var cleanEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    @MainActor private func submit() async {
        message = nil
        guard cleanEmail.contains("@"), !password.isEmpty else {
            message = "Enter your email address and password."
            return
        }
        if createAccount {
            guard password.count >= 6 else { message = "Use a password with at least 6 characters."; return }
            guard password == confirmation else { message = "The passwords do not match."; return }
        }
        isBusy = true
        defer { isBusy = false }
        do {
            if createAccount { try await session.signUp(email: cleanEmail, password: password) }
            else { try await session.signIn(email: cleanEmail, password: password) }
            password = ""
            confirmation = ""
        } catch { message = error.localizedDescription }
    }

    @MainActor private func resetPassword() async {
        guard cleanEmail.contains("@") else { message = "Enter your email address first."; return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await session.resetPassword(email: cleanEmail)
            message = "If an account exists for this email, you’ll receive password reset instructions."
        } catch { message = error.localizedDescription }
    }
}
