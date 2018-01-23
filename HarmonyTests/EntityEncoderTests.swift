
import XCTest

@testable import Harmony

class EntityEncoderTests: XCTestCase
{
    private var storage: TestEncodeStorage!

    override func setUp() {
        super.setUp()

        self.storage = TestEncodeStorage()
    }

    func testEncodeEntity()
    {
        let entity = TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child"))
        let encoder = EntityEncoder(storage: self.storage)

        do {
            try encoder.encode(entity)
        }
        catch (let error) {
            XCTFail("Encoder failed with error: \(error).")
        }

        let testModelIdentifier = BaseEntityIdentifier(type: TestModel.self, stringKey: "3")
        let childModelIdentifier = BaseEntityIdentifier(type: ChildModel.self, stringKey: "5")

        // Root model
        let testModelData = self.storage.entityDatas[testModelIdentifier]
        XCTAssertNotNil(testModelData)

        let testModelJSON = json(from: testModelData!.data)
        XCTAssertEqual(testModelJSON["id"] as? String, "3")
        XCTAssertEqual(testModelJSON["title"] as? String, "test")
        XCTAssertEqual(testModelJSON["number"] as? Int, 10)
        XCTAssertEqual(testModelJSON["child"] as? String, "5")

        // Child model
        let childModelData = self.storage.entityDatas[childModelIdentifier]
        XCTAssertNotNil(childModelData)

        let childModelJSON = json(from: childModelData!.data)
        XCTAssertEqual(childModelJSON["id"] as? String, "5")
        XCTAssertEqual(childModelJSON["name"] as? String, "child")
    }
}

fileprivate extension EntityEncoderTests
{
    func json(from data: Data) -> [String: Any] {
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}

fileprivate class TestEncodeStorage: WriteEntityDataStorage
{
    var entityDatas: [BaseEntityIdentifier: EntityData] = [:]

    func insert(entityData: EntityData) {
        self.entityDatas[entityData.identifier] = entityData
    }

    func removeEntityData(withIdentifier identifier: BaseEntityIdentifier) {
        XCTFail("Should not called.")
    }
}
