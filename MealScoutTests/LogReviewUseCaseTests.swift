import XCTest
@testable import MealScout
internal import MapKit

struct DummyRepositoryError: Error {}

final class DummyReviewRepository: ReviewRepository {
    var savedReview: Review?
    var savedRestaurant: Restaurant?
    var reviewsToReturn: [Review] = []
    var shouldFail = false

    func fetchAll() async throws -> [Review] {
        return reviewsToReturn
    }

    func save(_ review: Review) async throws {
        if shouldFail { throw DummyRepositoryError() }
        self.savedReview = review
    }

    func save(_ review: Review, with restaurant: Restaurant) async throws {
        if shouldFail { throw DummyRepositoryError() }
        self.savedReview = review
        self.savedRestaurant = restaurant
    }

    func delete(id: UUID) async throws {}

    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review] {
        return reviewsToReturn.filter { $0.restaurant.id == mapIdentifier }
    }
}

final class DummyRestaurantRepository: RestaurantRepository {
    var savedRestaurant: Restaurant?
    var existingRestaurant: Restaurant?
    var shouldFail = false

    func fetchAll() async throws -> [Restaurant] {
        return existingRestaurant != nil ? [existingRestaurant!] : []
    }

    func save(_ restaurant: Restaurant) async throws {
        if shouldFail { throw DummyRepositoryError() }
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
        if shouldFail { throw DummyRepositoryError() }
        if let existing = existingRestaurant, existing.id == id {
            return existing
        }
        if let saved = savedRestaurant, saved.id == id {
            return saved
        }
        return nil
    }

    func findOrCreateRestaurant(id: MapIdentifier, restaurantName: String, lat: Double, lng: Double) async throws -> Restaurant {
        if shouldFail { throw DummyRepositoryError() }
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
    private let mapID = MapIdentifier(rawValue: "I385AFE206B1B222B")!

    override func setUp() async throws {
        try await super.setUp()
        
        reviewRepo = DummyReviewRepository()
        restaurantRepo = DummyRestaurantRepository()
        
        sut = LogReviewUseCase(
            reviewRepository: reviewRepo,
            restaurantRepository: restaurantRepo,
            currentUserID: { "test-user" }
        )
    }

    override func tearDown() {
        reviewRepo = nil
        restaurantRepo = nil
        sut = nil
        super.tearDown()
    }
    
    func test_execute_success() async {
        guard let mapID = MapIdentifier(rawValue: "I385AFE206B1B222B") else {
            XCTFail("Failed to create MapIdentifier")
            return
        }

        let result = await sut.execute(
            mealOccasion: .dinner,
            dishes: [DishEntry(dishName: "Carbonara", price: 20.0, quantity: 1)],
            numDiners: 1,
            totalPrice: 20.0,
            ratings: RatingScores(quality: 4.0, price: 4.0, portion: 4.0),
            description: "Great pasta!",
            usedDeal: Deal(redeemSource: "Store", percentOff: 0, dollarsOff: 0, notes: "None"),
            restaurantIdentifier: mapID,
            restaurantName: "Bar Totti",
            addedRestaurantTags: [.drinksFocused],
            lat: -33.8664,
            lng: 151.2073
        )

        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Bar Totti"))
            XCTAssertNotNil(reviewRepo.savedReview)
            XCTAssertNotNil(reviewRepo.savedRestaurant)
        case .failure(let error):
            XCTFail("Expected success, but got error: \(error)")
        }
    }
    
    func test_execute_failsWhenDishesEmpty() async {
        guard let mapID = MapIdentifier(rawValue: "I385AFE206B1B222B") else {
            XCTFail("Failed to create MapIdentifier")
            return
        }

        let result = await sut.execute(
            mealOccasion: .dinner,
            dishes: [], // Empty dishes to trigger validation guard
            numDiners: 1,
            totalPrice: 20.0,
            ratings: RatingScores(quality: 4.0, price: 4.0, portion: 4.0),
            description: "Great pasta!",
            usedDeal: Deal(redeemSource: "Store", percentOff: 0, dollarsOff: 0, notes: "None"),
            restaurantIdentifier: mapID,
            restaurantName: "Bar Totti",
            addedRestaurantTags: [],
            lat: -33.8664,
            lng: 151.2073
        )

        XCTAssertEqual(result, .failure(.dishesEmpty))
    }

    // MARK: - Helpers

    /// Calls execute with valid defaults, so each test only overrides the field it checks
    private func execute(
        mealOccasion: MealOccasion = .dinner,
        dishes: [DishEntry] = [DishEntry(dishName: "Carbonara", price: 20.0, quantity: 1)],
        numDiners: Int = 1,
        totalPrice: Double = 20.0,
        description: String = "Great pasta!",
        usedDeal: Deal = Deal(),
        addedRestaurantTags: [CuisineTag] = []
    ) async -> Result<String, LogReviewError> {
        await sut.execute(
            mealOccasion: mealOccasion,
            dishes: dishes,
            numDiners: numDiners,
            totalPrice: totalPrice,
            ratings: RatingScores(quality: 4.0, price: 4.0, portion: 4.0),
            description: description,
            usedDeal: usedDeal,
            restaurantIdentifier: mapID,
            restaurantName: "Bar Totti",
            addedRestaurantTags: addedRestaurantTags,
            lat: -33.8664,
            lng: 151.2073
        )
    }

    private func assertNothingSaved(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(reviewRepo.savedReview, file: file, line: line)
        XCTAssertNil(reviewRepo.savedRestaurant, file: file, line: line)
    }

    // MARK: - Validation

    func test_execute_failsWhenNotLoggedIn() async {
        sut = LogReviewUseCase(
            reviewRepository: reviewRepo,
            restaurantRepository: restaurantRepo,
            currentUserID: { nil }
        )

        let result = await execute()

        XCTAssertEqual(result, .failure(.authenticationRequired))
        assertNothingSaved()
    }

    func test_execute_failsWhenMealOccasionMissing() async {
        let result = await execute(mealOccasion: .none)

        XCTAssertEqual(result, .failure(.invalidMealOccasion))
        assertNothingSaved()
    }

    func test_execute_failsWhenNoDiners() async {
        let result = await execute(numDiners: 0)

        XCTAssertEqual(result, .failure(.invalidDiners))
        assertNothingSaved()
    }

    func test_execute_failsWhenDishHasNoName() async {
        let result = await execute(dishes: [DishEntry(dishName: "", price: 20.0, quantity: 1)])

        XCTAssertEqual(result, .failure(.invalidDish))
        assertNothingSaved()
    }

    func test_execute_failsWhenDishQuantityZero() async {
        let result = await execute(dishes: [DishEntry(dishName: "Carbonara", price: 20.0, quantity: 0)])

        XCTAssertEqual(result, .failure(.invalidDish))
        assertNothingSaved()
    }

    func test_execute_failsWhenTotalPriceZero() async {
        let result = await execute(totalPrice: 0)

        XCTAssertEqual(result, .failure(.invalidPrice))
        assertNothingSaved()
    }

    func test_execute_failsWhenDescriptionEmpty() async {
        let result = await execute(description: "")

        XCTAssertEqual(result, .failure(.emptyReview))
        assertNothingSaved()
    }

    func test_execute_failsWhenDealHasDiscountButNoSource() async {
        let result = await execute(usedDeal: Deal(redeemSource: "", percentOff: 10))

        XCTAssertEqual(result, .failure(.invalidDeal))
        assertNothingSaved()
    }

    func test_execute_failsWhenDealPercentNegative() async {
        let result = await execute(usedDeal: Deal(redeemSource: "Store", percentOff: -50))

        XCTAssertEqual(result, .failure(.invalidDeal))
        assertNothingSaved()
    }

    func test_execute_failsWhenDealPercentOver100() async {
        let result = await execute(usedDeal: Deal(redeemSource: "Store", percentOff: 250))

        XCTAssertEqual(result, .failure(.invalidDeal))
        assertNothingSaved()
    }

    func test_execute_failsWhenDealDollarsNegative() async {
        let result = await execute(usedDeal: Deal(redeemSource: "Store", dollarsOff: -10))

        XCTAssertEqual(result, .failure(.invalidDeal))
        assertNothingSaved()
    }

    func test_execute_succeedsWithPercentAndDollarsOff() async {
        let result = await execute(usedDeal: Deal(redeemSource: "Store", percentOff: 10, dollarsOff: 5))

        XCTAssertNoThrow(try result.get())
    }

    func test_execute_succeedsWithSourceButNoDiscount() async {
        let result = await execute(usedDeal: Deal(redeemSource: "Uber Eats", notes: "Free drink with meal"))

        XCTAssertNoThrow(try result.get())
    }

    func test_execute_succeedsWithoutDeal() async {
        let result = await execute(usedDeal: Deal())

        XCTAssertNoThrow(try result.get())
    }

    // MARK: - Saving

    func test_execute_savesReviewWithAuthorAndRestaurant() async {
        let result = await execute()

        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(reviewRepo.savedReview?.authorID, "test-user")
        XCTAssertEqual(reviewRepo.savedReview?.restaurantID, mapID.rawValue)
        XCTAssertEqual(reviewRepo.savedReview?.dishes.first?.dishName, "Carbonara")
        XCTAssertEqual(reviewRepo.savedRestaurant?.name, "Bar Totti")
    }

    func test_execute_mergesTagsWithoutDuplicates() async {
        restaurantRepo.existingRestaurant = Restaurant(
            id: mapID, name: "Bar Totti", tags: [.drinksFocused],
            latitude: -33.8664, longitude: 151.2073
        )

        _ = await execute(addedRestaurantTags: [.drinksFocused, .bbq])

        let savedTags = reviewRepo.savedRestaurant?.tags ?? []
        XCTAssertEqual(savedTags.count, 2)
        XCTAssertEqual(Set(savedTags), [.drinksFocused, .bbq])
    }

    func test_execute_savesNothingWhenBatchWriteFails() async {
        reviewRepo.shouldFail = true

        let result = await execute()

        XCTAssertEqual(result, .failure(.databaseError))
        assertNothingSaved()
    }

    func test_execute_returnsDatabaseErrorWhenRestaurantLookupFails() async {
        restaurantRepo.shouldFail = true

        let result = await execute()

        XCTAssertEqual(result, .failure(.databaseError))
        assertNothingSaved()
    }

    // MARK: - retrieveTagsForRestaurant

    func test_retrieveTags_returnsTagsOfExistingRestaurant() async {
        restaurantRepo.existingRestaurant = Restaurant(
            id: mapID, name: "Bar Totti", tags: [.drinksFocused],
            latitude: 0, longitude: 0
        )

        let tags = await sut.retrieveTagsForRestaurant(mapIdentifier: mapID)

        XCTAssertEqual(tags, [.drinksFocused])
    }

    func test_retrieveTags_returnsEmptyWhenRestaurantNotFound() async {
        let tags = await sut.retrieveTagsForRestaurant(mapIdentifier: mapID)

        XCTAssertTrue(tags.isEmpty)
    }

    func test_retrieveTags_returnsEmptyWhenDatabaseFails() async {
        restaurantRepo.shouldFail = true

        let tags = await sut.retrieveTagsForRestaurant(mapIdentifier: mapID)

        XCTAssertTrue(tags.isEmpty)
    }
}
