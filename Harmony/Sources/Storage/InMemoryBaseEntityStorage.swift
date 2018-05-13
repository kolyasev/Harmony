
final class InMemoryBaseEntityStorage: BaseEntityStorage
{
    // MARK: - Functions: Read

    func entity<T: Entity>(withType type: T.Type, forKey key: T.Key) -> T? {
        return storage(withType: type).entity(forKey: key)
    }

    func enumerate<T: Entity>(entityType: T.Type, keys block: (T.Key, inout Bool) -> Void) {
        storage(withType: entityType).enumerate(keys: block)
    }

    func enumerate<T: Entity>(entityType: T.Type, entities block: (T, inout Bool) -> Void) {
        storage(withType: entityType).enumerate(entities: block)
    }

    // MARK: - Functions: Write

    func insert<T: Entity>(entity: T) {
        storage(withType: type(of: entity)).insert(entity: entity)
    }

    func removeEntity<T: Entity>(withType type: T.Type, forKey key: T.Key) {
        storage(withType: type).removeEntity(forKey: key)
    }

    // MARK: - Private Functions

    private func storage<T: Entity>(withType type: T.Type) -> InMemoryEntityStorage<T>
    {
        let storage: InMemoryEntityStorage<T>

        let key = ObjectIdentifier(type)
        if let existingStorage = self.storages[key] as? InMemoryEntityStorage<T>
        {
            storage = existingStorage
        }
        else {
            storage = InMemoryEntityStorage<T>()
            self.storages[key] = storage
        }

        return storage
    }

    // MARK: - Private Properties

    private var storages: [ObjectIdentifier: Any] = [:]

}
