
public protocol Predicate: Hashable, CustomStringConvertible
{
    // MARK: - Functions

    func evaluate(_ object: Element) -> Bool

    // MARK: - Inner Types

    associatedtype Element: Entity
}

enum Expression<Element, Value>: Hashable, CustomStringConvertible
    where Value: Equatable, Value: CustomStringConvertible
{
    // MARK: - Cases

    case keyPath(KeyPath<Element, Value>)
    case constant(Value)

    // MARK: - Properties: CustomStringConvertible

    var description: String {
        return makeDescription()
    }

    // MARK: - Properties: Hashable

    var hashValue: Int {
        return self.description.hashValue
    }

    // MARK: - Functions

    func value(_ object: Element) -> Value
    {
        switch self
        {
            case .keyPath(let keyPath):
                return object[keyPath: keyPath]

            case .constant(let value):
                return value
        }
    }

    // MARK: - Functions: Equatable

    static func == (lhs: Expression<Element, Value>, rhs: Expression<Element, Value>) -> Bool
    {
        switch (lhs, rhs)
        {
            case (.keyPath(let leftKeyPath), .keyPath(let rightKeyPath)):
                return leftKeyPath == rightKeyPath

            case (.constant(let leftValue), .constant(let rightValue)):
                return leftValue == rightValue

            default:
                return false
        }
    }

    // MARK: - Private Functions

    private func makeDescription() -> String
    {
        switch self
        {
            case .keyPath(let keyPath):
                return String(describing: keyPath)

            case .constant(let value):
                return value.description
        }
    }
}

public struct CompoundPredicate<Element, LHS: Predicate, RHS: Predicate>: Predicate
    where LHS.Element == Element, RHS.Element == Element
{
    // MARK: - Initialization

    init(type: CompoundType, lhs: LHS, rhs: RHS)
    {
        self.type = type
        self.lhs = lhs
        self.rhs = rhs
    }

    // MARK: - Properties

    let type: CompoundType

    let lhs: LHS

    let rhs: RHS

    // MARK: - Properties: CustomStringConvertible

    public var description: String {
        return makeDescription()
    }

    // MARK: - Functions

    public func evaluate(_ object: Element) -> Bool
    {
        switch self.type
        {
            case .and:
                return self.lhs.evaluate(object) && self.rhs.evaluate(object)

            case .or:
                return self.lhs.evaluate(object) || self.rhs.evaluate(object)
        }
    }

    // MARK: - Private Functions

    private func makeDescription() -> String
    {
        switch self.type
        {
            case .and:
                return "\(self.lhs) AND \(self.rhs)"

            case .or:
                return "\(self.lhs) OR \(self.rhs)"
        }
    }

    // MARK: - Inner Types

    enum CompoundType
    {
        case and
        case or
    }
}

struct AnyPredicate<Element: Entity>: Predicate
{
    // MARK: - Initialization

    init<Base: Predicate>(_ predicate: Base) where Base.Element == Element
    {
        self.block = { predicate.evaluate($0) }
        self.description = predicate.description
        self.hashValue = predicate.hashValue
    }

    // MARK: - Properties

    let description: String

    let hashValue: Int

    // MARK: - Functions

    func evaluate(_ object: Element) -> Bool
    {
        return self.block(object)
    }

    // MARK: - Functions: Equatable

    static func == (lhs: AnyPredicate<Element>, rhs: AnyPredicate<Element>) -> Bool {
        return lhs.description == rhs.description
    }

    // MARK: - Private Properties

    private let block: (Element) -> Bool

}

public struct EqualPredicate<Element: Entity, Value: Equatable>: Predicate
    where Value: CustomStringConvertible
{
    // MARK: - Initialization

    init(lhs: Expression<Element, Value>, rhs: Expression<Element, Value>)
    {
        self.lhs = lhs
        self.rhs = rhs
    }

    // MARK: - Properties

    let lhs: Expression<Element, Value>

    let rhs: Expression<Element, Value>

    // MARK: - Properties: CustomStringConvertible

    public var description: String {
        return makeDescription()
    }

    // MARK: - Properties: Hashable

    public var hashValue: Int {
        return self.description.hashValue
    }

    // MARK: - Functions

    public func evaluate(_ object: Element) -> Bool
    {
        return self.lhs.value(object) == self.rhs.value(object)
    }

    // MARK: - Private Functions

    private func makeDescription() -> String
    {
        return "\(self.lhs) == \(self.rhs)"
    }
}

// MARK: - Operators

// MARK: Predicate && Predicate

public func && <Element, LP: Predicate, RP: Predicate>(lhs: LP, rhs: RP) -> CompoundPredicate<Element, LP, RP> where LP.Element == Element, RP.Element == Element
{
    return CompoundPredicate(type: .and, lhs: lhs, rhs: rhs)
}

// MARK: Predicate || Predicate

public func || <Element, LP: Predicate, RP: Predicate>(lhs: LP, rhs: RP) -> CompoundPredicate<Element, LP, RP> where LP.Element == Element, RP.Element == Element
{
    return CompoundPredicate(type: .or, lhs: lhs, rhs: rhs)
}

// MARK: KeyPath == Value

public func == <Element: Entity, Value: Equatable>(lhs: KeyPath<Element, Value>, rhs: KeyPath<Element, Value>) -> EqualPredicate<Element, Value>
{
    return EqualPredicate(lhs: .keyPath(lhs), rhs: .keyPath(rhs))
}

// MARK: KeyPath == KeyPath

public func == <Element: Entity, Value: Equatable>(lhs: KeyPath<Element, Value>, rhs: Value) -> EqualPredicate<Element, Value>
{
    return EqualPredicate(lhs: .keyPath(lhs), rhs: .constant(rhs))
}
