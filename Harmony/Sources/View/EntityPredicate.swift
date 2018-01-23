
protocol EntityPredicate
{
    func evaluate(_ entity: Root) -> Bool

    associatedtype Root: Entity
}

struct AnyEntityPredicate<Root: Entity>: EntityPredicate
{
    init<P: EntityPredicate>(_ predicate: P) where P.Root == Root {
        self._evaluate = predicate.evaluate
    }

    func evaluate(_ entity: Root) -> Bool {
        return self._evaluate(entity)
    }

    private let _evaluate: (Root) -> Bool
}

struct BlockEntityPredicate<T: Entity>: EntityPredicate
{
    init(_ block: @escaping Block) {
        self.block = block
    }

    func evaluate(_ entity: T) -> Bool {
        return self.block(entity)
    }

    typealias Block = (T) -> Bool

    private let block: Block
}
