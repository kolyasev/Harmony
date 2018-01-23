
import XCTest

@testable import Harmony

class HarmonyTests: XCTestCase
{
    var db: Database!
    var storage: EntityDataStorage!

    override func setUp() {
        super.setUp()

        self.storage = InMemoryEntityDataStorage()
        self.db = Database(entityDataStorage: self.storage)
    }

    func testReuseCollections()
    {
        let collection1 = self.db.collection(TestModel.self)
        let collection2 = self.db.collection(TestModel.self)

        XCTAssert(collection1 === collection2)
    }

    func testReadWrite()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        collection.write { state in
            state.insert(entity: entity)
        }

        let entityFromDB = collection.read { state in
            return state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityFromDB)
        XCTAssertEqual(entityFromDB!, entity)
    }

    func testUpdateChildDirectly()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let testCollection = self.db.collection(TestModel.self)
        let childCollection = self.db.collection(ChildModel.self)

        testCollection.write { state in
            state.insert(entity: entity)
        }

        let newChild = ChildModel(id: "5", name: "new child")
        childCollection.write { state in
            state.insert(entity: newChild)
        }

        let entityFromDB = testCollection.read { state in
            return state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityFromDB)
        XCTAssertEqual(entityFromDB!.child, newChild)
    }

    func testUpdateChildNested()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let testCollection = self.db.collection(TestModel.self)
        let childCollection = self.db.collection(ChildModel.self)

        testCollection.write { state in
            state.insert(entity: entity)
        }

        let newEntity = TestModel(id: "10", title: "other test", number: 20, child: ChildModel(id: "5", name: "new child"))
        testCollection.write { state in
            state.insert(entity: newEntity)
        }

        let childFromDB = childCollection.read { state in
            return state.entity(forKey: "5")
        }

        XCTAssertNotNil(childFromDB)
        XCTAssertEqual(childFromDB!, newEntity.child)
    }

    func testReadInsertedInWrite()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        let entityInState = collection.write { state -> TestModel? in
            state.insert(entity: entity)
            return state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityInState)
        XCTAssertEqual(entityInState!, entity)
    }

    func testReadUpdatedInWrite()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        collection.write { state in
            state.insert(entity: entity)
        }

        let newEntity = TestModel(id: "3", title: "new test", number: 15, child: entity.child)
        let entityInState = collection.write { state -> TestModel? in
            state.insert(entity: newEntity)
            return state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityInState)
        XCTAssertEqual(entityInState!, newEntity)
    }

    func testViewUpdateRoot()
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

        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        collection.write { state in
            state.insert(entity: entity)
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(eventsCount, 2)

        XCTAssertNotNil(entities)
        XCTAssertEqual(entities!.count, 1)

        view.unsubscribe(token)
    }

    func testViewUpdateChild()
    {
        let view = self.db.view(TestModel.self, predicate: BlockEntityPredicate { entity in
            return entity.child.name == "new child"
        })

        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        collection.write { state in
            state.insert(entity: entity)
        }

        var entities: [TestModel]?
        var eventsCount = 0
        let expectation = self.expectation(description: "Expect update.")

        let token = view.subscribe { e in
            entities = e
            eventsCount += 1

            if !e.isEmpty {
                expectation.fulfill()
            }
        }

        let newChild = ChildModel(id: "5", name: "new child")
        let childCollection = self.db.collection(ChildModel.self)
        childCollection.write { state in
            state.insert(entity: newChild)
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssert(2...3 ~= eventsCount)

        XCTAssertNotNil(entities)
        XCTAssertEqual(entities!.count, 1)

        XCTAssertEqual(entities![0], TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "new child")))

        view.unsubscribe(token)
    }
}
