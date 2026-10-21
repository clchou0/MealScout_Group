import XCTest
import FirebaseAuth
@testable import MealScout

final class DummyReviewRepository: ReviewRepository {
    var savedReview: Review?
    var reviewsToReturn: [Review] = []

    func fetchAll() async throws -> [Review] {
        return reviewsToReturn
    }

    func save(_ review: Review) async throws {
        self.savedReview = review
    }

    func delete(id: UUID) async throws {}

    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review] {
        return reviewsToReturn.filter { $0.restaurant.id == mapIdentifier }
    }
}

final class DummyRestaurantRepository: RestaurantRepository {
    var savedRestaurant: Restaurant?
    var existingRestaurant: Restaurant?

    func fetchAll() async throws -> [Restaurant] {
        return existingRestaurant != nil ? [existingRestaurant!] : []
    }

    func save(_ restaurant: Restaurant) async throws {
        self.savedRestaurant = restaurant
    }

    func delete(id: MapIdentifier) async throws {
        if savedRestaurant?.id == id {
            savedRestaurant = nil
        }
        if existingRestaurant?.id == id {
            existingRestaurant = nil
        }
    }

    func find(by id: MapIdentifier) async throws -> Restaurant? {
        if let existing = existingRestaurant, existing.id == id {
            return existing
        }
        if let saved = savedRestaurant, saved.id == id {
            return saved
        }
        return nil
    }

    func findOrCreateRestaurant(id: MapIdentifier, restaurantName: String, lat: Double, lng: Double) async throws -> Restaurant {
        if let existing = existingRestaurant {
            return existing
        }
        return Restaurant(
            id: id,
            name: restaurantName,
            tags: [],
            latitude: lat,
            longitude: lng
        )
    }

    func getTagsForRestaurant(id: MapIdentifier) async throws -> [CuisineTag] {
        if let existing = existingRestaurant, existing.id == id {
            return existing.tags
        }
        if let saved = savedRestaurant, saved.id == id {
            return saved.tags
        }
        return []
    }
}

final class LogReviewUseCaseTests: XCTestCase {

    private var reviewRepo: DummyReviewRepository!
    private var restaurantRepo: DummyRestaurantRepository!
    private var sut: LogReviewUseCase!

    override func setUp() async throws {
        try await super.setUp()
        
        // Pass Firebase Auth guard in tests
        _ = try? await Auth.auth().signInAnonymously()
        
        reviewRepo = DummyReviewRepository()
        restaurantRepo = DummyRestaurantRepository()
        
        sut = LogReviewUseCase(
            reviewRepository: reviewRepo,
            restaurantRepository: restaurantRepo
        )
    }

    override func tearDown() {
        reviewRepo = nil
        restaurantRepo = nil
        sut = nil
        super.tearDown()
    }
}
