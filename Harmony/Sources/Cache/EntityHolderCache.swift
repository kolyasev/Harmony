
import Foundation

class EntityHolderCache
{
    func getEntityHolder(forIdentifier identifier: BaseEntityIdentifier) -> AnyEntityHolder? {
        return self.cache.object(forKey: key(for: identifier))?.value
    }

    func addEntityHolder(_ entityHolder: AnyEntityHolder) {
        self.cache.setObject(Box(entityHolder), forKey: key(for: entityHolder.entity.identifier))
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

    private let cache = NSCache<NSString, Box<AnyEntityHolder>>()
}
