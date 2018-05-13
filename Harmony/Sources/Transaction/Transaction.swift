
protocol Transaction
{
    associatedtype TransactionEntity: Entity

    associatedtype Result

    func run(entityCollectionStateManager: EntityCollectionStateManager<TransactionEntity>) -> Result
}

class ReadTransaction<T: Entity, R>: Transaction
{
    typealias TransactionEntity = T

    typealias Result = R

    init(block: @escaping ReadBlock)
    {
        self.block = block
    }

    func run(entityCollectionStateManager: EntityCollectionStateManager<T>) -> R
    {
        return entityCollectionStateManager.read { state in
            return self.block(state)
        }
    }

    typealias ReadBlock = (EntityCollectionReadState<T>) -> R

    private let block: ReadBlock
}

class ReadWriteTransaction<T: Entity, R>: Transaction
{
    typealias TransactionEntity = T

    typealias Result = R

    init(block: @escaping ReadWriteBlock)
    {
        self.block = block
    }

    func run(entityCollectionStateManager: EntityCollectionStateManager<T>) -> R
    {
        return entityCollectionStateManager.write { state in
            return self.block(state)
        }
    }

    typealias ReadWriteBlock = (EntityCollectionReadWriteState<T>) -> R

    private let block: ReadWriteBlock
}
