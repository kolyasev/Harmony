
final class InMemoryEntityStorage<T: Entity>: EntityReadWriteStorage
{
    // MARK: - Functions: Read

    func entity(forKey key: EnityType.Key) -> EnityType? {
        return self.entities[key]
    }

    func enumerate(keys enumerator: KeyEnumerator)
    {
        var stop = false
        for key in self.entities.keys {
            enumerator(key, &stop)
            if stop { return }
        }
    }

    func enumerate(entities enumerator: EntityEnumerator)
    {
        var stop = false
        for entity in self.entities.values {
            enumerator(entity, &stop)
            if stop { return }
        }
    }

    // MARK: - Functions: Write

    func insert(entity: T) {
        self.entities[entity.key] = entity
    }

    func removeEntity(forKey key: T.Key) {
        self.entities[key] = nil
    }

    // MARK: - Inner Types

    typealias EnityType = T

    // MARK: - Private Properties

    private var entities: [T.Key: T] = [:]

}
