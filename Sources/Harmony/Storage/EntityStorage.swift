
public protocol EntityReadStorage
{
    // MARK: - Functions: Read

    func entity(forKey key: EnityType.Key) throws -> EnityType?

    func enumerate(keys enumerator: KeyEnumerator) throws

    func enumerate(entities enumerator: EntityEnumerator) throws

    // MARK: - Inner Types

    associatedtype EnityType: Entity

    typealias KeyEnumerator = (EnityType.Key, inout Bool) -> Void

    typealias EntityEnumerator = (EnityType, inout Bool) -> Void
}

public protocol EntityReadWriteStorage: EntityReadStorage
{
    // MARK: - Functions: Write

    func insert(entity: EnityType) throws

    func removeEntity(forKey key: EnityType.Key) throws
}

extension EntityReadWriteStorage
{
    // MARK: - Functions: Write

    public func remove(entity: EnityType) throws
    {
        try removeEntity(forKey: entity.key)
    }
}

struct AnyEntityReadStorage<T: Entity>: EntityReadStorage
{
    // MARK: - Initialization

    init<Storage: EntityReadStorage>(_ entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityForKey = { key in return try entityStorage.entity(forKey: key) }
        self.enumerateKeys = { enumerator in return try entityStorage.enumerate(keys: enumerator) }
        self.enumerateEntities = { enumerator in return try entityStorage.enumerate(entities: enumerator) }
    }

    // MARK: - Functions: Read

    func entity(forKey key: T.Key) throws -> T? {
        return try self.entityForKey(key)
    }

    func enumerate(keys enumerator: (T.Key, inout Bool) -> Void) throws {
        try self.enumerateKeys(enumerator)
    }

    func enumerate(entities enumerator: (T, inout Bool) -> Void) throws {
        try self.enumerateEntities(enumerator)
    }

    // MARK: - Inner Types

    typealias EnityType = T

    // MARK: - Private Properties

    private let entityForKey: (T.Key) throws -> T?

    private let enumerateKeys: (KeyEnumerator) throws -> Void

    private let enumerateEntities: (EntityEnumerator) throws -> Void
}

struct AnyEntityReadWriteStorage<T: Entity>: EntityReadWriteStorage
{
    // MARK: - Initialization

    init<Storage: EntityReadWriteStorage>(_ entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityReadStorage = AnyEntityReadStorage<T>(entityStorage)
        self.insertEntity = { entity in return try entityStorage.insert(entity: entity) }
        self.removeEntityForKey = { key in return try entityStorage.removeEntity(forKey: key) }
    }

    // MARK: - Functions: Read

    func entity(forKey key: T.Key) throws -> T? {
        return try self.entityReadStorage.entity(forKey: key)
    }

    func enumerate(keys enumerator: (T.Key, inout Bool) -> Void) throws {
        try self.entityReadStorage.enumerate(keys: enumerator)
    }

    func enumerate(entities enumerator: (T, inout Bool) -> Void) throws {
        try self.entityReadStorage.enumerate(entities: enumerator)
    }

    // MARK: - Functions: Write

    func insert(entity: T) throws {
        try self.insertEntity(entity)
    }

    func removeEntity(forKey key: T.Key) throws {
        try self.removeEntityForKey(key)
    }

    // MARK: - Inner Types

    typealias EnityType = T

    // MARK: - Private Properties

    private let entityReadStorage: AnyEntityReadStorage<T>

    private let insertEntity: (T) throws -> Void

    private let removeEntityForKey: (T.Key) throws -> Void
}
