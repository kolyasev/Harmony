
public protocol EntityPredicate
{
    // MARK: - Functions

    func evaluate(_ entity: Root) -> Bool

    // MARK: - Inner Types

    associatedtype Root: Entity
}

struct AnyEntityPredicate<Root: Entity>: EntityPredicate
{
    // MARK: - Initialization

    init<P: EntityPredicate>(_ predicate: P) where P.Root == Root {
        self._evaluate = predicate.evaluate
    }

    // MARK: - Functions

    func evaluate(_ entity: Root) -> Bool {
        return self._evaluate(entity)
    }

    // MARK: - Private Properties

    private let _evaluate: (Root) -> Bool
}

public struct BlockEntityPredicate<T: Entity>: EntityPredicate
{
    // MARK: - Initialization

    public init(_ block: @escaping Block) {
        self.block = block
    }

    // MARK: - Functions

    public func evaluate(_ entity: T) -> Bool {
        return self.block(entity)
    }

    // MARK: - Inner Types

    public typealias Block = (T) -> Bool

    // MARK: - Private Properties

    private let block: Block
}
