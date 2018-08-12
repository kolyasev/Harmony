
enum EntityUpdate<T: Entity>
{
    case insert(entity: T)
    case remove(key: T.Key)
}

extension EntityUpdate
{
// MARK: - Properties

    var key: T.Key {
        switch self
        {
            case .insert(let entity):
                return entity.key

            case .remove(let key):
                return key
        }
    }

    var entity: T? {
        guard case .insert(let entity) = self else {
            return nil
        }
        return entity
    }
}
