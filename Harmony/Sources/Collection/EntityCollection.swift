
public final class EntityCollection<Element: Entity>
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

    // MARK: - Functions: Views

    public func view<P: Predicate>(_ predicate: P) -> EntityCollectionView<P.Element> where P.Element == Element
    {
        return self.collectionViewProvider.view(stateManager: self.stateManager, predicate: predicate)
    }

    public func view(_ key: Element.Key) -> EntityView<Element>
    {
        return self.viewProvider.view(stateManager: self.stateManager, key: key)
    }

    // MARK: - Functions: Read / Write

    public func read<Result>(_ block: @escaping (EntityCollectionReadState<Element>) -> Result) -> Result
    {
        let transaction = ReadTransaction<Element, Result>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    public func write<Result>(_ block: @escaping (EntityCollectionReadWriteState<Element>) -> Result) -> Result
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
        self.collectionViewProvider.enumerateViews { view in
            view.updateEntities(with: entityUpdates)
        }

        for entityUpdate in entityUpdates
        {
            if let view = self.viewProvider.existingView(for: entityUpdate.key) {
                view.updateEntity(with: entityUpdate)
            }
        }
    }

    // MARK: - Private Properties

    private let transactionQueue = TransactionQueue<EntityCollection<Element>>()

    private let stateManager: EntityCollectionStateManager<Element>

    private let collectionViewProvider = EntityCollectionViewProvider<Element>()

    private let viewProvider = EntityViewProvider<Element>()
}

extension EntityCollection
{
    // MARK: - Functions

    public func asyncRead<Result>(_ block: @escaping (EntityCollectionReadState<Element>) -> Result, completion: ((Result) -> Void)? = nil)
    {
        let transaction = ReadTransaction<Element, Result>(block: block)
        self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }

    public func asyncWrite<Result>(_ block: @escaping (EntityCollectionReadWriteState<Element>) -> Result, completion: ((Result) -> Void)? = nil)
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

extension EntityCollection
{
    // MARK: - Functions: Read

    public func entity(forKey key: Element.Key) -> Element?
    {
        return read { state in
            return state.entity(forKey: key)
        }
    }

    public func enumerate(keys enumerator: @escaping (Element.Key, inout Bool) -> Void)
    {
        return read { state in
            return state.enumerate(keys: enumerator)
        }
    }

    public func enumerate(entities enumerator: @escaping (Element, inout Bool) -> Void)
    {
        return read { state in
            return state.enumerate(entities: enumerator)
        }
    }

    // MARK: - Functions: Write

    public func insert(entity: Element)
    {
        write { state in
            state.insert(entity: entity)
        }
    }

    public func removeEntity(forKey key: Element.Key)
    {
        write { state in
            state.removeEntity(forKey: key)
        }
    }

}
