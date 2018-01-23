
import XCTest

@testable import Harmony

class EntityDecoderTests: XCTestCase
{
    private var storage: TestDecodeStorage!

    override func setUp() {
        super.setUp()

        self.storage = TestDecodeStorage()
    }

    func testDecodeEntity()
    {
        let testModelIdentifier = BaseEntityIdentifier(type: TestModel.self, stringKey: "3")
        let childModelIdentifier = BaseEntityIdentifier(type: ChildModel.self, stringKey: "5")

        self.storage.entityDatas[testModelIdentifier] = EntityData(
            identifier: testModelIdentifier,
            data: data(from: ["id": "3", "title": "test", "number": 10, "child": "5"])
        )
        self.storage.entityDatas[childModelIdentifier] = EntityData(
            identifier: childModelIdentifier,
            data: data(from: ["id": "5", "name": "child"])
        )

        var holder: EntityHolder<TestModel>?

        let decoder = EntityDecoder(storage: self.storage)
        do {
            let decoded = try decoder.decode(forIdentifier: testModelIdentifier)

            guard let result = decoded?.cast(to: TestModel.self) else {
                XCTFail("Expected to decode \(TestModel.self) but found \(String(describing: decoded)) instead.")
                return
            }

            holder = result
        }
        catch (let error) {
            XCTFail("Decoder failed with error: \(error).")
        }

        XCTAssertNotNil(holder)
        XCTAssertEqual(holder!.entity, TestModel(id: "3", title: "test", number: 10, child: ChildModel(id: "5", name: "child")))
        XCTAssertEqual(holder!.dependencies, [childModelIdentifier])
    }
}

fileprivate extension EntityDecoderTests
{
    func data(from json: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }
}

fileprivate class TestDecodeStorage: ReadEntityDataStorage
{
    var entityDatas: [BaseEntityIdentifier: EntityData] = [:]

    func entityData(withIdentifier identifier: BaseEntityIdentifier) -> EntityData? {
        return self.entityDatas[identifier]
    }

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void) {
        var stop = false
        for identifier in self.entityDatas.keys {
            if identifier.type == entityType {
                block(identifier, &stop)
                if stop { return }
            }
        }
    }

    func enumerate(entityType: BaseEntity.Type, entities block: (EntityData, inout Bool) -> Void) {
        var stop = false
        for entityData in self.entityDatas.values {
            if entityData.identifier.type == entityType {
                block(entityData, &stop)
                if stop { return }
            }
        }
    }
}
