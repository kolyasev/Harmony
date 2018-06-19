
import XCTest

@testable import Harmony

class EntityCollectionViewTests: XCTestCase
{
    var db: Database!
    var storage: BaseEntityStorage!

    var subscriptionToken: SubscriptionToken?

    override func setUp() {
        super.setUp()

        self.storage = InMemoryBaseEntityStorage()
        self.db = Database(baseEntityStorage: self.storage)
    }

    func testShouldReuseViews()
    {
        let view1 = try! self.db.view(ChildModel.self, predicate: \.name == "child")
        let view2 = try! self.db.view(ChildModel.self, predicate: \.name == "child")

        XCTAssert(view1 === view2)
    }

    func testShouldNotReuseViews()
    {
        let view1 = try! self.db.view(ChildModel.self, predicate: \.name == "child 1")
        let view2 = try! self.db.view(ChildModel.self, predicate: \.name == "child 2")

        XCTAssert(view1 !== view2)
    }

    func testViewUpdate()
    {
        let view = try! self.db.view(ChildModel.self, predicate: \.name == "child")

        var entities: [ChildModel]?
        var eventsCount = 0
        let expectation = self.expectation(description: "Expect update.")

        self.subscriptionToken = view.subscribe { e in
            entities = e
            eventsCount += 1

            if !e.isEmpty {
                expectation.fulfill()
            }
        }

        let collection = self.db.collection(ChildModel.self)
        try! collection.write { state in
            try state.insert(entity: ChildModel(id: "1", name: "child"))
            try state.insert(entity: ChildModel(id: "2", name: "child 2"))
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(eventsCount, 2)

        XCTAssertNotNil(entities)
        XCTAssertEqual(entities!.count, 1)
    }
}
