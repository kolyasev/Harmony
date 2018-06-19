
class EntityCollectionStorage<T: Entity>: EntityReadWriteStorage
{
    // MARK: - Initialization

    init(baseEntityStorage: BaseEntityStorage) {
        self.baseEntityStorage = baseEntityStorage
    }

    // MARK: - Functions: Read

    func entity(forKey key: EnityType.Key) throws -> EnityType? {
        return try self.baseEntityStorage.entity(withType: T.self, forKey: key)
    }

    func enumerate(keys enumerator: KeyEnumerator) throws {
        try self.baseEntityStorage.enumerate(entityType: T.self, keys: enumerator)
    }

    func enumerate(entities enumerator: EntityEnumerator) throws {
        try self.baseEntityStorage.enumerate(entityType: T.self, entities: enumerator)
    }

    // MARK: - Functions: Write

    func insert(entity: EntityCollectionStorage.EnityType) throws {
        try self.baseEntityStorage.insert(entity: entity)
    }

    func removeEntity(forKey key: EntityCollectionStorage.EnityType.Key) throws {
        try self.baseEntityStorage.removeEntity(withType: T.self, forKey: key)
    }

    // MARK: - Inner Types

    typealias EnityType = T

    // MARK: - Private Properties

    private let baseEntityStorage: BaseEntityStorage
}
