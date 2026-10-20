import XCTest
import MapKit
@testable import MealScout

@MainActor
final class DeleteReviewUseCaseTests: XCTestCase {
    private func review(author: String = "owner", sample: Bool = false) -> Review {
        Review(authorID: author, isSample: sample, mealOccasion: .dinner,
               dishes: [], numDiners: 1, totalPrice: 10, ratings: RatingScores(),
               description: "Test review", restaurant: Restaurant(
                id: MapIdentifier(rawValue: "I385AFE206B1B222B")!, name: "Test",
                tags: [], latitude: 0, longitude: 0))
    }

    func testOwnerDeletesTheSelectedReview() async throws {
        let repository = ReviewRepositorySpy()
        let item = review()
        try await DeleteReviewUseCase(repository: repository, currentUserID: { "owner" }).execute(review: item)
        XCTAssertEqual(repository.deletedIDs, [item.id])
    }

    func testGuestCannotDelete() async {
        let repository = ReviewRepositorySpy()
        do {
            try await DeleteReviewUseCase(repository: repository, currentUserID: { nil }).execute(review: review())
            XCTFail("Guest deletion should fail")
        } catch { XCTAssertTrue(error is DeleteReviewError) }
        XCTAssertTrue(repository.deletedIDs.isEmpty)
    }

    func testOtherAccountCannotDelete() async {
        let repository = ReviewRepositorySpy()
        do {
            try await DeleteReviewUseCase(repository: repository, currentUserID: { "other" }).execute(review: review())
            XCTFail("Another account must not delete this review")
        } catch { XCTAssertTrue(error is DeleteReviewError) }
        XCTAssertTrue(repository.deletedIDs.isEmpty)
    }

    func testSampleReviewCannotBeDeleted() async {
        let repository = ReviewRepositorySpy()
        do {
            try await DeleteReviewUseCase(repository: repository, currentUserID: { "owner" }).execute(review: review(sample: true))
            XCTFail("Sample deletion should fail")
        } catch { XCTAssertTrue(error is DeleteReviewError) }
        XCTAssertTrue(repository.deletedIDs.isEmpty)
    }

    func testDatabaseFailureReachesCaller() async {
        let repository = ReviewRepositorySpy()
        repository.shouldFail = true
        do {
            try await DeleteReviewUseCase(repository: repository, currentUserID: { "owner" }).execute(review: review())
            XCTFail("Database error should reach the UI")
        } catch { XCTAssertTrue(error is ReviewRepositorySpy.Failure) }
    }
}

private final class ReviewRepositorySpy: ReviewRepository {
    enum Failure: Error { case unavailable }
    var deletedIDs: [UUID] = []
    var shouldFail = false
    func fetchAll() async throws -> [Review] { [] }
    func save(_ review: Review) async throws { }
    func delete(id: UUID) async throws {
        if shouldFail { throw Failure.unavailable }
        deletedIDs.append(id)
    }
    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review] { [] }
}
