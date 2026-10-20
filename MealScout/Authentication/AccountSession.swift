import Foundation
import FirebaseAuth

/// Firebase owns credential storage and restores the session between launches.
@MainActor @Observable
final class AccountSession {
    private(set) var user: User?
    private(set) var isReady = false
    @ObservationIgnored nonisolated(unsafe) private var listener: AuthStateDidChangeListenerHandle?

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isReady = true
            }
        }
    }

    deinit {
        if let listener { Auth.auth().removeStateDidChangeListener(listener) }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        user = result.user
    }

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        user = result.user
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
    }
}
