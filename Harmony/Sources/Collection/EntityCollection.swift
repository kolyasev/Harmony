
class EntityCollection<T: Entity>
{
    init(baseEntityStorage: BaseEntityStorage)
    {
        let entityCollectionStorage = EntityCollectionStorage<T>(baseEntityStorage: baseEntityStorage)
        self.stateManager = EntityCollectionStateManager(entityStorage: entityCollectionStorage)
        self.transactionQueue.target = self
    }

    // FIXME: Not implemented
//    func view() -> EntityCollectionView<T>
//    {
//        fatalError()
//    }

    func read<R>(_ block: @escaping (EntityCollectionReadState<T>) -> R) -> R
    {
        let transaction = ReadTransaction<T, R>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    func write<R>(_ block: @escaping (EntityCollectionReadWriteState<T>) -> R) -> R
    {
        let transaction = ReadWriteTransaction<T, R>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    func perform<EntityTransaction: Transaction, R>(transaction: EntityTransaction) -> R where EntityTransaction.TransactionEntity == T, EntityTransaction.Result == R
    {
        return transaction.run(entityCollectionStateManager: self.stateManager)
    }

    private let transactionQueue = TransactionQueue<EntityCollection<T>>()

    private let stateManager: EntityCollectionStateManager<T>
}

extension EntityCollection
{
    func asyncRead<R>(_ block: @escaping (EntityCollectionReadState<T>) -> R, completion: ((R) -> Void)? = nil)
    {
        let transaction = ReadTransaction<T, R>(block: block)
        self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }

    func asyncWrite<R>(_ block: @escaping (EntityCollectionReadWriteState<T>) -> R, completion: ((R) -> Void)? = nil)
    {
        let transaction = ReadWriteTransaction<T, R>(block: block)
        return self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }
}

extension EntityCollection: TransactionQueueTarget
{
    func run<Trans: Transaction>(transaction: Trans) -> Trans.Result where Trans.TransactionEntity == TransactionEntity {
        return transaction.run(entityCollectionStateManager: self.stateManager)
    }

    typealias TransactionEntity = T
}
