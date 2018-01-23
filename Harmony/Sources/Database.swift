
class Database
{
    init(entityDataStorage: EntityDataStorage)
    {
        self.entityDataStorage = entityDataStorage
        self.transactionQueue = TransactionQueue()
        self.stateManager = DatabaseStateManager(entityDataStorage: entityDataStorage)
        self.collectionProvider = EntityCollectionProvider(transactionQueue: self.transactionQueue)
        self.viewProvider = EntityCollectionViewProvider(stateManager: self.stateManager)

        self.transactionQueue.target = self
        self.stateManager.updatesListener = self
    }

    func collection<T>(_ type: T.Type) -> EntityCollection<T>
    {
        return self.collectionProvider.collection(type)
    }

    func view<P: EntityPredicate>(_ type: P.Root.Type, predicate: P) -> EntityCollectionView<P.Root>
    {
        return self.viewProvider.view(type, predicate: predicate)
    }

    func read<R>(_ block: (DatabaseState) -> R) -> R
    {
        return self.stateManager.read(block)
    }

    func write<R>(_ block: (DatabaseState) -> R) -> R
    {
        return self.stateManager.write(block)
    }

    private let entityDataStorage: EntityDataStorage

    private let transactionQueue: TransactionQueue

    private let collectionProvider: EntityCollectionProvider

    private let viewProvider: EntityCollectionViewProvider

    private let stateManager: DatabaseStateManager

}

extension Database: TransactionQueueTarget
{
    func run<T>(transaction: T) -> T.Result where T: Transaction {
        return transaction.run(database: self)
    }
}

extension Database: EntityUpdatesListener
{
    func handleEntityUpdates(_ updates: [EntityUpdate], in state: DatabaseState) {
        self.viewProvider.handleEntityUpdates(updates, in: state)
    }
}
