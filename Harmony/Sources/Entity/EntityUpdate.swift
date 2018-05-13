
enum EntityUpdate<T: Entity>
{
    case insert(entity: T)
    case remove(key: T.Key)
}

extension EntityUpdate
{
    var entity: T? {
        guard case .insert(let entity) = self else {
            return nil
        }
        return entity
    }
}
