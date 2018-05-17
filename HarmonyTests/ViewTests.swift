
import XCTest

@testable import Harmony

class ViewTests: XCTestCase
{
    var db: Database!
    var storage: BaseEntityStorage!

    override func setUp() {
        super.setUp()

        self.storage = InMemoryBaseEntityStorage()
        self.db = Database(baseEntityStorage: self.storage)
    }

    func testViewUpdate()
    {
        let view = self.db.view(ChildModel.self, predicate: BlockEntityPredicate { entity in
            return entity.name == "child"
        })

        var entities: [ChildModel]?
        var eventsCount = 0
        let expectation = self.expectation(description: "Expect update.")

        let token = view.subscribe { e in
            entities = e
            eventsCount += 1

            if !e.isEmpty {
                expectation.fulfill()
            }
        }

        let entity = ChildModel(id: "5", name: "child")
        let collection = self.db.collection(ChildModel.self)

        collection.write { state in
            state.insert(entity: entity)
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(eventsCount, 2)

        XCTAssertNotNil(entities)
        XCTAssertEqual(entities!.count, 1)

        view.unsubscribe(token)
    }
}
