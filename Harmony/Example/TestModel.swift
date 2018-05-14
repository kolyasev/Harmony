
struct TestModel: Entity
{
// MARK: - Properties

    let id: String

    let title: String

    let number: Int

    let child: ChildModel

    var key: Key {
        return self.id
    }

    typealias Key = String

// MARK: - Functions

    static func == (lhs: TestModel, rhs: TestModel) -> Bool
    {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.number == rhs.number &&
               lhs.child == rhs.child
    }

}

struct ChildModel: Entity
{
    let id: String

    let name: String

    var key: Key {
        return self.id
    }

    typealias Key = String

    static func ==(lhs: ChildModel, rhs: ChildModel) -> Bool
    {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name
    }

}
