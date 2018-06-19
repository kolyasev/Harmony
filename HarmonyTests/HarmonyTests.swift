
import XCTest

@testable import Harmony

class HarmonyTests: XCTestCase
{
    var db: Database!
    var storage: BaseEntityStorage!

    override func setUp() {
        super.setUp()

        self.storage = InMemoryBaseEntityStorage()
        self.db = Database(baseEntityStorage: self.storage)
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

        try! collection.write { state in
            try state.insert(entity: entity)
        }

        let entityFromDB = try! collection.read { state in
            return try state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityFromDB)
        XCTAssertEqual(entityFromDB!, entity)
    }

    func testReadInsertedInWrite()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        let entityInState = try! collection.write { state -> TestModel? in
            try state.insert(entity: entity)
            return try state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityInState)
        XCTAssertEqual(entityInState!, entity)
    }

    func testReadUpdatedInWrite()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let collection = self.db.collection(TestModel.self)

        try! collection.write { state in
            try state.insert(entity: entity)
        }

        let newEntity = TestModel(id: "3", title: "new test", number: 15, child: entity.child)
        let entityInState = try! collection.write { state -> TestModel? in
            try state.insert(entity: newEntity)
            return try state.entity(forKey: "3")
        }

        XCTAssertNotNil(entityInState)
        XCTAssertEqual(entityInState!, newEntity)
    }

    // FIXME: ...
//    func testViewUpdateRoot()
//    {
//        let view = self.db.view(ChildModel.self, predicate: BlockEntityPredicate { entity in
//            return entity.name == "child"
//        })
//
//        var entities: [ChildModel]?
//        var eventsCount = 0
//        let expectation = self.expectation(description: "Expect update.")
//
//        let token = view.subscribe { e in
//            entities = e
//            eventsCount += 1
//
//            if !e.isEmpty {
//                expectation.fulfill()
//            }
//        }
//
//        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
//        let collection = self.db.collection(TestModel.self)
//
//        collection.write { state in
//            state.insert(entity: entity)
//        }
//
//        wait(for: [expectation], timeout: 1.0)
//
//        XCTAssertEqual(eventsCount, 2)
//
//        XCTAssertNotNil(entities)
//        XCTAssertEqual(entities!.count, 1)
//
//        view.unsubscribe(token)
//    }

    // FIXME: ...
//    func testViewUpdateChild()
//    {
//        let view = self.db.view(TestModel.self, predicate: BlockEntityPredicate { entity in
//            return entity.child.name == "new child"
//        })
//
//        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
//        let collection = self.db.collection(TestModel.self)
//
//        collection.write { state in
//            state.insert(entity: entity)
//        }
//
//        var entities: [TestModel]?
//        var eventsCount = 0
//        let expectation = self.expectation(description: "Expect update.")
//
//        let token = view.subscribe { e in
//            entities = e
//            eventsCount += 1
//
//            if !e.isEmpty {
//                expectation.fulfill()
//            }
//        }
//
//        let newChild = ChildModel(id: "5", name: "new child")
//        let childCollection = self.db.collection(ChildModel.self)
//        childCollection.write { state in
//            state.insert(entity: newChild)
//        }
//
//        wait(for: [expectation], timeout: 1.0)
//
//        XCTAssert(2...3 ~= eventsCount)
//
//        XCTAssertNotNil(entities)
//        XCTAssertEqual(entities!.count, 1)
//
//        XCTAssertEqual(entities![0], TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "new child")))
//
//        view.unsubscribe(token)
//    }
}
