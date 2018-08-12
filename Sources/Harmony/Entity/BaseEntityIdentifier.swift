
public struct BaseEntityIdentifier: Hashable
{
// MARK: - Initialization

    init(type: BaseEntity.Type, stringKey: String)
    {
        self.type = type
        self.stringKey = stringKey
        self.hashValue = String(describing: type).hashValue ^ stringKey.hashValue
    }

// MARK: - Properties

    public let type: BaseEntity.Type

    public let stringKey: String

    public let hashValue: Int

// MARK: - Functions

    public static func ==(lhs: BaseEntityIdentifier, rhs: BaseEntityIdentifier) -> Bool
    {
        return lhs.type == rhs.type &&
               lhs.stringKey == rhs.stringKey
    }
}
