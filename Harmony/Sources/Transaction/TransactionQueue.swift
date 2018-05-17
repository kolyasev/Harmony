
import Foundation

protocol TransactionQueueTarget: class
{
    // MARK: - Functions

    func run<T: Transaction>(transaction: T) -> T.Result where T.TransactionEntity == TransactionEntity

    // MARK: - Inner Types

    associatedtype TransactionEntity: Entity
}

class TransactionQueue<Target: TransactionQueueTarget>
{
    // MARK: - Properties

    weak var target: Target?

    // MARK: - Functions

    func enqueueAsync<T: Transaction>(transaction: T, completion: ((T.Result) -> Void)? = nil) where T.TransactionEntity == Target.TransactionEntity
    {
        return self.queue.async {
            let result: T.Result = self.getTarget().run(transaction: transaction)

            if let completion = completion
            {
                DispatchQueue.global().async {
                    completion(result)
                }
            }
        }
    }

    func enqueueSync<T: Transaction>(transaction: T) -> T.Result where T.TransactionEntity == Target.TransactionEntity
    {
        return self.queue.sync {
            return self.getTarget().run(transaction: transaction)
        }
    }

    // MARK: - Private Functions

    private func getTarget() -> Target
    {
        guard let target = self.target else {
            fatalError("Unknown target for queue.")
        }

        return target
    }

    // MARK: - Private Properties

    private let queue = DispatchQueue(label: "ru.kolyasev.Harmony.TransactionQueue.queue", attributes: [.concurrent])
}
