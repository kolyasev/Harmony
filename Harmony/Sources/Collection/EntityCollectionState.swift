
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

    public func entity(forKey key: T.Key) -> T?
    {
        return self.entityStorage.entity(forKey: key)
    }

    public func enumerate(keys enumerator: (T.Key, inout Bool) -> Void)
    {
        self.entityStorage.enumerate(keys: enumerator)
    }

    public func enumerate(entities enumerator: (T, inout Bool) -> Void)
    {
        self.entityStorage.enumerate(entities: enumerator)
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

    public override func entity(forKey key: T.Key) -> T?
    {
        let entity: T?

        if let update = self.updates[key]
        {
            entity = update.entity
        }
        else {
            entity = super.entity(forKey: key)
        }

        return entity
    }

    public override func enumerate(keys enumerator: (T.Key, inout Bool) -> Void)
    {
        var stop = false
        for case .insert(let entity) in self.updates.values {
            enumerator(entity.key, &stop)
            if stop { return }
        }

        super.enumerate(keys: { key, stop in
            guard self.updates[key] == nil else {
                return
            }
            enumerator(key, &stop)
        })
    }

    public override func enumerate(entities enumerator: (T, inout Bool) -> Void)
    {
        var stop = false
        for case .insert(let entity) in self.updates.values {
            enumerator(entity, &stop)
            if stop { return }
        }

        super.enumerate(entities: { entity, stop in
            guard self.updates[entity.key] == nil else {
                return
            }
            enumerator(entity, &stop)
        })
    }

    // MARK: - Functions: Write

    public func insert(entity: T)
    {
        self.updates[entity.key] = .insert(entity: entity)
    }

    public func removeEntity(forKey key: T.Key)
    {
        self.updates[key] = .remove(key: key)
    }

    // MARK: - Functions

    func writeChanges<Storage: EntityReadWriteStorage>(to entityStorage: Storage) where Storage.EnityType == T
    {
        for update in self.updates.values
        {
            switch update
            {
            case .insert(let entity):
                entityStorage.insert(entity: entity)

            case .remove(let key):
                entityStorage.removeEntity(forKey: key)
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
