import Foundation
import FirebaseAuth

enum DeleteReviewError: LocalizedError {
    case loginRequired
    case notOwner

    var errorDescription: String? {
        switch self {
        case .loginRequired: "Please log in to delete your review."
        case .notOwner: "You can only delete reviews you created."
        }
    }
}

@MainActor
final class DeleteReviewUseCase {
    private let repository: ReviewRepository
    private let currentUserID: () -> String?

    init(repository: ReviewRepository? = nil,
         currentUserID: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.repository = repository ?? FirebaseReviewRepository()
        self.currentUserID = currentUserID
    }

    func execute(review: Review) async throws {
        guard let uid = currentUserID(), !uid.isEmpty else {
            throw DeleteReviewError.loginRequired
        }
        guard !review.isSample, review.authorID == uid else {
            throw DeleteReviewError.notOwner
        }
        // Keep the review visible unless Firestore confirms deletion.
        try await repository.delete(id: review.id)
    }
}
