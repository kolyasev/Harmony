
import XCTest

@testable import Harmony

class EntityViewTests: XCTestCase
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
        let view1 = self.db.view(ChildModel.self, key: "1")
        let view2 = self.db.view(ChildModel.self, key: "1")

        XCTAssert(view1 === view2)
    }

    func testShouldNotReuseViews()
    {
        let view1 = self.db.view(ChildModel.self, key: "1")
        let view2 = self.db.view(ChildModel.self, key: "2")

        XCTAssert(view1 !== view2)
    }

    func testViewUpdate()
    {
        let view = self.db.view(ChildModel.self, key: "1")

        var events: [ChildModel?] = []
        let expectation = self.expectation(description: "Expect update.")

        self.subscriptionToken = view.subscribe { e in
            events.append(e)

            if e != nil {
                expectation.fulfill()
            }
        }

        let collection = self.db.collection(ChildModel.self)
        collection.write { state in
            state.insert(entity: ChildModel(id: "1", name: "child 1"))
            state.insert(entity: ChildModel(id: "2", name: "child 2"))
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(events.count, 2)

        XCTAssertNil(events[0])
        XCTAssertNotNil(events[1])

        XCTAssertEqual(events[1]!.id, "1")
    }
}
