
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

    public func view<Predicate: EntityPredicate>(_ type: Predicate.Root.Type, predicate: Predicate) -> EntityCollectionView<Predicate.Root>
    {
        return collection(type).view(predicate)
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
