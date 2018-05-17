
class EntityCollection<Element: Entity>
{
    // MARK: - Initialization

    init(baseEntityStorage: BaseEntityStorage)
    {
        let entityCollectionStorage = EntityCollectionStorage<Element>(baseEntityStorage: baseEntityStorage)
        self.stateManager = EntityCollectionStateManager(entityStorage: entityCollectionStorage)
        self.transactionQueue.target = self
        self.stateManager.updatesListener = { [weak self] updates in
            self?.updateEntities(with: updates)
        }
    }

    // MARK: - Functions

    func view<Predicate: EntityPredicate>(_ predicate: Predicate) -> EntityCollectionView<Predicate.Root> where Predicate.Root == Element
    {
        return self.viewProvider.view(stateManager: self.stateManager, predicate: predicate)
    }

    func read<Result>(_ block: @escaping (EntityCollectionReadState<Element>) -> Result) -> Result
    {
        let transaction = ReadTransaction<Element, Result>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    func write<Result>(_ block: @escaping (EntityCollectionReadWriteState<Element>) -> Result) -> Result
    {
        let transaction = ReadWriteTransaction<Element, Result>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    // MARK: - Private Functions

    private func perform<T: Transaction, Result>(transaction: T) -> Result where T.TransactionEntity == Element, T.Result == Result
    {
        return transaction.run(entityCollectionStateManager: self.stateManager)
    }

    private func handleEntityUpdates(_ entityUpdates: [EntityUpdate<Element>])
    {
        self.viewProvider.enumerateViews { view in
            view.updateEntities(with: entityUpdates)
        }
    }

    // MARK: - Private Properties

    private let transactionQueue = TransactionQueue<EntityCollection<Element>>()

    private let stateManager: EntityCollectionStateManager<Element>

    private let viewProvider = EntityCollectionViewProvider<Element>()
}

extension EntityCollection
{
    // MARK: - Functions

    func asyncRead<Result>(_ block: @escaping (EntityCollectionReadState<Element>) -> Result, completion: ((Result) -> Void)? = nil)
    {
        let transaction = ReadTransaction<Element, Result>(block: block)
        self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }

    func asyncWrite<Result>(_ block: @escaping (EntityCollectionReadWriteState<Element>) -> Result, completion: ((Result) -> Void)? = nil)
    {
        let transaction = ReadWriteTransaction<Element, Result>(block: block)
        return self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }
}

extension EntityCollection: TransactionQueueTarget
{
    // MARK: - Functions

    func run<T: Transaction>(transaction: T) -> T.Result where T.TransactionEntity == TransactionEntity
    {
        return transaction.run(entityCollectionStateManager: self.stateManager)
    }

    // MARK: - Inner Types

    typealias TransactionEntity = Element
}

extension EntityCollection: EntityUpdatesListener
{
    // MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<Element>]) {
        handleEntityUpdates(entityUpdates)
    }

    // MARK: - Inner Types

    typealias EntityType = Element
}
