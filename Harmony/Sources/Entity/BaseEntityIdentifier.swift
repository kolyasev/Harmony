
struct BaseEntityIdentifier: Hashable
{
    init(type: BaseEntity.Type, stringKey: String)
    {
        self.type = type
        self.stringKey = stringKey
        self.hashValue = String(describing: type).hashValue ^ stringKey.hashValue
    }

    let type: BaseEntity.Type

    let stringKey: String

    let hashValue: Int

    static func ==(lhs: BaseEntityIdentifier, rhs: BaseEntityIdentifier) -> Bool
    {
        return lhs.type == rhs.type &&
               lhs.stringKey == rhs.stringKey
    }
}
