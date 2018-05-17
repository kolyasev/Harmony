
public protocol ReadBaseEntityStorage
{
    // MARK: - Functions

    func entity<T: Entity>(withType type: T.Type, forKey key: T.Key) -> T?

    func enumerate<T: Entity>(entityType: T.Type, keys block: (T.Key, inout Bool) -> Void)

    func enumerate<T: Entity>(entityType: T.Type, entities block: (T, inout Bool) -> Void)
}

public protocol WriteBaseEntityStorage
{
    // MARK: - Functions

    func insert<T: Entity>(entity: T)

    func removeEntity<T: Entity>(withType type: T.Type, forKey key: T.Key)
}

public typealias BaseEntityStorage = ReadBaseEntityStorage & WriteBaseEntityStorage
