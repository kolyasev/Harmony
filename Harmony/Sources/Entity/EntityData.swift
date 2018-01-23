
import Foundation

struct EntityData
{
    let identifier: BaseEntityIdentifier
    let data: Data
}

extension EntityData: Hashable
{
    var hashValue: Int {
        return self.identifier.hashValue ^ self.data.hashValue
    }

    static func ==(lhs: EntityData, rhs: EntityData) -> Bool
    {
        return lhs.identifier == rhs.identifier &&
               lhs.data == rhs.data
    }

}
