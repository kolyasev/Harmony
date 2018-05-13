
class Database
{
    init(baseEntityStorage: BaseEntityStorage)
    {
        self.baseEntityStorage = baseEntityStorage
        self.collectionProvider = EntityCollectionProvider(baseEntityStorage: self.baseEntityStorage)

        // FIXME: Not implemented
//        self.viewProvider = EntityCollectionViewProvider(stateManager: self.stateManager)
    }

    func collection<T>(_ type: T.Type) -> EntityCollection<T>
    {
        return self.collectionProvider.collection(type)
    }

    // FIXME: Not implemented
//    func view<P: EntityPredicate>(_ type: P.Root.Type, predicate: P) -> EntityCollectionView<P.Root>
//    {
//        return self.viewProvider.view(type, predicate: predicate)
//    }

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
