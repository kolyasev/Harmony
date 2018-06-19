
public protocol ReadBaseEntityStorage
{
    // MARK: - Functions

    func entity<T: Entity>(withType type: T.Type, forKey key: T.Key) throws -> T?

    func enumerate<T: Entity>(entityType: T.Type, keys block: (T.Key, inout Bool) -> Void) throws

    func enumerate<T: Entity>(entityType: T.Type, entities block: (T, inout Bool) -> Void) throws
}

public protocol WriteBaseEntityStorage
{
    // MARK: - Functions

    func insert<T: Entity>(entity: T) throws

    func removeEntity<T: Entity>(withType type: T.Type, forKey key: T.Key) throws
}

public typealias BaseEntityStorage = ReadBaseEntityStorage & WriteBaseEntityStorage
