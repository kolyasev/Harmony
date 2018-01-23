
class EntityCollectionState
{
    init(databaseState: DatabaseState)
    {
        self.databaseState = databaseState
    }

    let databaseState: DatabaseState
}

class EntityCollectionReadState<T: Entity>: EntityCollectionState
{
    func entity(forKey key: T.Key) -> T?
    {
        let identifier = BaseEntityIdentifier(type: T.self, stringKey: key.description)
        return self.databaseState.entity(withIdentifier: identifier) as? T
    }
}

class EntityCollectionReadWriteState<T: Entity>: EntityCollectionReadState<T>
{
    func insert(entity: T)
    {
        self.databaseState.insert(entity: entity)
    }

    func removeEntity(forKey key: T.Key)
    {
        let identifier = BaseEntityIdentifier(type: T.self, stringKey: key.description)
        self.databaseState.removeEntity(withIdentifier: identifier)
    }

    func remove(entity: T)
    {
        removeEntity(forKey: entity.key)
    }
}
