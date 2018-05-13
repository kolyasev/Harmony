
protocol ReadBaseEntityStorage
{
    func entity<T: Entity>(withType type: T.Type, forKey key: T.Key) -> T?

    func enumerate<T: Entity>(entityType: T.Type, keys block: (T.Key, inout Bool) -> Void)

    func enumerate<T: Entity>(entityType: T.Type, entities block: (T, inout Bool) -> Void)
}

protocol WriteBaseEntityStorage
{
    func insert<T: Entity>(entity: T)

    func removeEntity<T: Entity>(withType type: T.Type, forKey key: T.Key)
}

typealias BaseEntityStorage = ReadBaseEntityStorage & WriteBaseEntityStorage
