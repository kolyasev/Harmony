
import Foundation
import SQLite

public final class SQLIteBaseEntityStorage: BaseEntityStorage
{
    // MARK: - Functions: Read

    public init(filename: String) throws
    {
        let url = Constants.documentsURL.appendingPathComponent(filename)
        self.connection = try Connection(url.path)

        try createObjectsTable()
    }

    // MARK: - Functions: Read

    public func entity<T>(withType type: T.Type, forKey key: T.Key) throws -> T? where T : Entity
    {
        guard let row = try self.connection.pluck(filter(withType: type, forKey: key)) else {
            return nil
        }

        return try entity(from: row)
    }

    public func enumerate<T>(entityType: T.Type, keys block: (T.Key, inout Bool) -> Void) throws where T : Entity
    {
        var stop = false
        let expression = filter(withType: entityType).select(ObjectsTable.Column.key)
        for row in try self.connection.prepare(expression)
        {
            if let key: T.Key = try key(of: T.self, from: row) {
                block(key, &stop)
            }

            if stop { return }
        }
    }

    public func enumerate<T>(entityType: T.Type, entities block: (T, inout Bool) -> Void) throws where T : Entity
    {
        var stop = false
        for row in try self.connection.prepare(filter(withType: entityType))
        {
            if let entity: T = try entity(from: row) {
                block(entity, &stop)
            }

            if stop { return }
        }
    }

    // MARK: - Functions: Write

    public func insert<T>(entity: T) throws where T : Entity
    {
        let encoder = JSONEncoder()
        let data = try encoder.encode(entity)

        try self.connection.run(ObjectsTable.table.insert(or: .replace,
            ObjectsTable.Column.key <- entity.key.description,
            ObjectsTable.Column.type <- String(describing: type(of: entity)),
            ObjectsTable.Column.object <- data
        ))
    }

    public func removeEntity<T>(withType type: T.Type, forKey key: T.Key) throws where T : Entity
    {
        try self.connection.run(filter(withType: type, forKey: key).delete())
    }

    // MARK: - Private Functions

    private func createObjectsTable() throws
    {
        try self.connection.run(ObjectsTable.table.create(ifNotExists: true) { t in
            t.column(ObjectsTable.Column.key)
            t.column(ObjectsTable.Column.type)
            t.column(ObjectsTable.Column.object)
            t.primaryKey(ObjectsTable.Column.key, ObjectsTable.Column.type)
        })
    }

    private func filter<T>(withType type: T.Type) -> Table where T : Entity
    {
        let expression: SQLite.Expression<Bool> =
            ObjectsTable.Column.type == String(describing: type)
        return ObjectsTable.table.filter(expression)
    }

    private func filter<T>(withType type: T.Type, forKey key: T.Key) -> Table where T : Entity
    {
        let expression: SQLite.Expression<Bool> =
            ObjectsTable.Column.key == key.description &&
            ObjectsTable.Column.type == String(describing: type)
        return ObjectsTable.table.filter(expression)
    }

    private func key<T>(of type: T.Type, from row: Row) throws -> T.Key? where T : Entity
    {
        let id = row[ObjectsTable.Column.key]
        return T.Key(id)
    }

    private func entity<T>(from row: Row) throws -> T? where T : Entity
    {
        let data = row[ObjectsTable.Column.object]

        let decoder = JSONDecoder()
        let entity = try decoder.decode(T.self, from: data)

        return entity
    }

    // MARK: - Constants

    private enum Constants
    {
        static let version = 1
        static let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    private enum ObjectsTable
    {
        static let table = Table("objects-v\(Constants.version)")

        enum Column
        {
            static let key = SQLite.Expression<String>("key")
            static let type = SQLite.Expression<String>("type")
            static let object = SQLite.Expression<Data>("object")
        }
    }

    // MARK: - Private Properties

    private let connection: Connection
}
