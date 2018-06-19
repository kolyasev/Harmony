
protocol Transaction
{
    associatedtype TransactionEntity: Entity

    associatedtype Result

    func run(entityCollectionStateManager: EntityCollectionStateManager<TransactionEntity>) throws -> Result
}

class ReadTransaction<T: Entity, R>: Transaction
{
    typealias TransactionEntity = T

    typealias Result = R

    init(block: @escaping ReadBlock)
    {
        self.block = block
    }

    func run(entityCollectionStateManager: EntityCollectionStateManager<T>) throws -> R
    {
        return try entityCollectionStateManager.read { state in
            return try self.block(state)
        }
    }

    typealias ReadBlock = (EntityCollectionReadState<T>) throws -> R

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

    func run(entityCollectionStateManager: EntityCollectionStateManager<T>) throws -> R
    {
        return try entityCollectionStateManager.write { state in
            return try self.block(state)
        }
    }

    typealias ReadWriteBlock = (EntityCollectionReadWriteState<T>) throws -> R

    private let block: ReadWriteBlock
}
