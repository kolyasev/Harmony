
public protocol EntityReadStorage
{
    // MARK: - Functions: Read

    func entity(forKey key: EnityType.Key) -> EnityType?

    func enumerate(keys enumerator: KeyEnumerator)

    func enumerate(entities enumerator: EntityEnumerator)

    // MARK: - Inner Types

    associatedtype EnityType: Entity

    typealias KeyEnumerator = (EnityType.Key, inout Bool) -> Void

    typealias EntityEnumerator = (EnityType, inout Bool) -> Void
}

public protocol EntityReadWriteStorage: EntityReadStorage
{
    // MARK: - Functions: Write

    func insert(entity: EnityType)

    func removeEntity(forKey key: EnityType.Key)
}

extension EntityReadWriteStorage
{
    // MARK: - Functions: Write

    public func remove(entity: EnityType)
    {
        removeEntity(forKey: entity.key)
    }
}

struct AnyEntityReadStorage<T: Entity>: EntityReadStorage
{
    // MARK: - Initialization

    init<Storage: EntityReadStorage>(_ entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityForKey = { key in return entityStorage.entity(forKey: key) }
        self.enumerateKeys = { enumerator in return entityStorage.enumerate(keys: enumerator) }
        self.enumerateEntities = { enumerator in return entityStorage.enumerate(entities: enumerator) }
    }

    // MARK: - Functions: Read

    func entity(forKey key: T.Key) -> T? {
        return self.entityForKey(key)
    }

    func enumerate(keys enumerator: (T.Key, inout Bool) -> Void) {
        self.enumerateKeys(enumerator)
    }

    func enumerate(entities enumerator: (T, inout Bool) -> Void) {
        self.enumerateEntities(enumerator)
    }

    // MARK: - Inner Types

    typealias EnityType = T

    // MARK: - Private Properties

    private let entityForKey: (T.Key) -> T?

    private let enumerateKeys: (KeyEnumerator) -> Void

    private let enumerateEntities: (EntityEnumerator) -> Void
}

struct AnyEntityReadWriteStorage<T: Entity>: EntityReadWriteStorage
{
    // MARK: - Initialization

    init<Storage: EntityReadWriteStorage>(_ entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityReadStorage = AnyEntityReadStorage<T>(entityStorage)
        self.insertEntity = { entity in return entityStorage.insert(entity: entity) }
        self.removeEntityForKey = { key in return entityStorage.removeEntity(forKey: key) }
    }

    // MARK: - Functions: Read

    func entity(forKey key: T.Key) -> T? {
        return self.entityReadStorage.entity(forKey: key)
    }

    func enumerate(keys enumerator: (T.Key, inout Bool) -> Void) {
        self.entityReadStorage.enumerate(keys: enumerator)
    }

    func enumerate(entities enumerator: (T, inout Bool) -> Void) {
        self.entityReadStorage.enumerate(entities: enumerator)
    }

    // MARK: - Functions: Write

    func insert(entity: T) {
        self.insertEntity(entity)
    }

    func removeEntity(forKey key: T.Key) {
        self.removeEntityForKey(key)
    }

    // MARK: - Inner Types

    typealias EnityType = T

    // MARK: - Private Properties

    private let entityReadStorage: AnyEntityReadStorage<T>

    private let insertEntity: (T) -> Void

    private let removeEntityForKey: (T.Key) -> Void
}
