
public class EntityCollectionState<T: Entity>
{
    // MARK: - Properties

    let sid = DatabaseSID()

    // MARK: - Inner Types

    public typealias EnityType = T
}

public class EntityCollectionReadState<T: Entity>: EntityCollectionState<T>, EntityReadStorage
{
    // MARK: - Initialization

    init<Storage: EntityReadStorage>(entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityStorage = AnyEntityReadStorage<T>(entityStorage)
        super.init()
    }

    // MARK: - Functions: Read

    public func entity(forKey key: T.Key) throws -> T?
    {
        return try self.entityStorage.entity(forKey: key)
    }

    public func enumerate(keys enumerator: (T.Key, inout Bool) -> Void) throws
    {
        try self.entityStorage.enumerate(keys: enumerator)
    }

    public func enumerate(entities enumerator: (T, inout Bool) -> Void) throws
    {
        try self.entityStorage.enumerate(entities: enumerator)
    }

    // MARK: - Private Properties

    private let entityStorage: AnyEntityReadStorage<T>
}

public final class EntityCollectionReadWriteState<T: Entity>: EntityCollectionReadState<T>, EntityReadWriteStorage
{
    // MARK: - Initialization

    override init<Storage: EntityReadStorage>(entityStorage: Storage) where Storage.EnityType == T {
        super.init(entityStorage: entityStorage)
    }

    // MARK: - Properties

    var hasUpdates: Bool {
        return !self.updates.isEmpty
    }

    var allUpdates: [EntityUpdate<T>] {
        return Array(self.updates.values)
    }

    // MARK: - Functions: Read

    public override func entity(forKey key: T.Key) throws -> T?
    {
        let entity: T?

        if let update = self.updates[key]
        {
            entity = update.entity
        }
        else {
            entity = try super.entity(forKey: key)
        }

        return entity
    }

    public override func enumerate(keys enumerator: (T.Key, inout Bool) -> Void) throws
    {
        var stop = false
        for case .insert(let entity) in self.updates.values {
            enumerator(entity.key, &stop)
            if stop { return }
        }

        try super.enumerate(keys: { key, stop in
            guard self.updates[key] == nil else {
                return
            }
            enumerator(key, &stop)
        })
    }

    public override func enumerate(entities enumerator: (T, inout Bool) -> Void) throws
    {
        var stop = false
        for case .insert(let entity) in self.updates.values {
            enumerator(entity, &stop)
            if stop { return }
        }

        try super.enumerate(entities: { entity, stop in
            guard self.updates[entity.key] == nil else {
                return
            }
            enumerator(entity, &stop)
        })
    }

    // MARK: - Functions: Write

    public func insert(entity: T) throws
    {
        self.updates[entity.key] = .insert(entity: entity)
    }

    public func removeEntity(forKey key: T.Key) throws
    {
        self.updates[key] = .remove(key: key)
    }

    // MARK: - Functions

    func writeChanges<Storage: EntityReadWriteStorage>(to entityStorage: Storage) throws where Storage.EnityType == T
    {
        for update in self.updates.values
        {
            switch update
            {
            case .insert(let entity):
                try entityStorage.insert(entity: entity)

            case .remove(let key):
                try entityStorage.removeEntity(forKey: key)
            }
        }
    }

    // MARK: - Private Properties

    private var updates: [T.Key: EntityUpdate<T>] = [:]
}

extension EntityCollectionState: Equatable
{
    // MARK: - Functions

    public static func ==(lhs: EntityCollectionState<T>, rhs: EntityCollectionState<T>) -> Bool {
        return lhs.sid == rhs.sid
    }
}

extension EntityCollectionState: Hashable
{
    // MARK: - Properties

    public var hashValue: Int {
        return self.sid.hashValue
    }
}
