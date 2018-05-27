
struct TestModel: Entity
{
// MARK: - Properties

    let id: String

    let title: String

    let number: Int

    let child: ChildModel

    static let keyPath: KeyPath<TestModel, String> = \.id

    typealias Key = String

}

struct ChildModel: Entity
{
    let id: String

    let name: String

    static let keyPath: KeyPath<ChildModel, String> = \.id

    typealias Key = String

}
