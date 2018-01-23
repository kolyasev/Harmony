
import Foundation

class EntityDataCache
{
    func getEntityData(forIdentifier identifier: BaseEntityIdentifier) -> EntityData? {
        return self.cache.object(forKey: key(for: identifier))?.value
    }

    func addEntityData(_ entityData: EntityData) {
        self.cache.setObject(Box(entityData), forKey: key(for: entityData.identifier))
    }

    private func key(for identifier: BaseEntityIdentifier) -> NSString {
        return (String(describing: identifier.type) + "_" + identifier.stringKey) as NSString
    }

    private class Box<T>
    {
        init(_ value: T) {
            self.value = value
        }

        let value: T
    }

    private let cache = NSCache<NSString, Box<EntityData>>()
}
