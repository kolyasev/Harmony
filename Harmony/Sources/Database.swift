
public class Database
{
    public init(baseEntityStorage: BaseEntityStorage)
    {
        self.baseEntityStorage = baseEntityStorage
        self.collectionProvider = EntityCollectionProvider(baseEntityStorage: self.baseEntityStorage)

        // FIXME: Not implemented
//        self.viewProvider = EntityCollectionViewProvider(stateManager: self.stateManager)
    }

    public func collection<T>(_ type: T.Type) -> EntityCollection<T>
    {
        return self.collectionProvider.collection(type)
    }

    public func view<P: Predicate>(_ type: P.Element.Type, predicate: P) -> EntityCollectionView<P.Element>
    {
        return collection(type).view(predicate)
    }

    public func view<E: Entity>(_ type: E.Type, key: E.Key) -> EntityView<E>
    {
        return collection(type).view(key)
    }

    // FIXME: Not implemented
//    func read<T: Entity, R>(_ block: (DatabaseState) -> R) -> R
//    {
//        let collection = collection(T.self)
//        return self.stateManager.read(block)
//    }

    // FIXME: Not implemented
//    func write<R>(_ block: (DatabaseState) -> R) -> R
//    {
//        return self.stateManager.write(block)
//    }

    private let baseEntityStorage: BaseEntityStorage

    private let collectionProvider: EntityCollectionProvider

    // FIXME: Not implemented
//    private let viewProvider: EntityCollectionViewProvider
}

// FIXME: Not implemented
//extension Database: EntityUpdatesListener
//{
//    func handleEntityUpdates(_ updates: [EntityUpdate], in state: DatabaseState) {
//        self.viewProvider.handleEntityUpdates(updates, in: state)
//    }
//}
