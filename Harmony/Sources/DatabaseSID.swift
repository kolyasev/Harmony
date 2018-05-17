
struct DatabaseSID: Comparable, Hashable
{
    // MARK: - Initialization

    init()
    {
        self.index = DatabaseSID.indexGenerator.next()
    }

    // MARK: - Properties

    var hashValue: Int {
        return self.index.hashValue
    }

    // MARK: - Functions

    static func <(lhs: DatabaseSID, rhs: DatabaseSID) -> Bool {
        return lhs.index < rhs.index
    }

    static func ==(lhs: DatabaseSID, rhs: DatabaseSID) -> Bool {
        return lhs.index == rhs.index
    }

    // MARK: - Inner Types

    private final class IndexGenerator
    {
        func next() -> Int
        {
            self.index += 1
            return self.index
        }

        private var index: Int = 0
    }

    // MARK: - Private Properties

    private let index: Int

    private static let indexGenerator = IndexGenerator()
}
