
struct EntityUpdate
{
    let identifier: BaseEntityIdentifier

    let type: UpdateType

    enum UpdateType
    {
        case insert
        case remove
    }
}
