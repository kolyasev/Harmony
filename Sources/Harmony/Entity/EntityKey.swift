
import Foundation

public protocol EntityKey: LosslessStringConvertible, Hashable { }

extension String: EntityKey { }

extension Int: EntityKey { }

extension UUID: EntityKey { }

extension UUID: LosslessStringConvertible
{
// MARK: -  Initialization

    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}
