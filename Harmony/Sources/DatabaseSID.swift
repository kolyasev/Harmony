
struct DatabaseSID: Comparable, Hashable
{
    init()
    {
        self.index = DatabaseSID.indexGenerator.next()
    }

    var hashValue: Int {
        return self.index.hashValue
    }

    static func <(lhs: DatabaseSID, rhs: DatabaseSID) -> Bool {
        return lhs.index < rhs.index
    }

    static func ==(lhs: DatabaseSID, rhs: DatabaseSID) -> Bool {
        return lhs.index == rhs.index
    }

    private final class IndexGenerator
    {
        func next() -> Int
        {
            self.index += 1
            return self.index
        }

        private var index: Int = 0
    }

    private let index: Int

    private static let indexGenerator = IndexGenerator()
}
