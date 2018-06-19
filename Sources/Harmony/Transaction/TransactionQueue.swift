
import Foundation

public enum Result<T>
{
    case success(T)
    case failure(Error)
}

protocol TransactionQueueTarget: class
{
    // MARK: - Functions

    func run<T: Transaction>(transaction: T) throws -> T.Result where T.TransactionEntity == TransactionEntity

    // MARK: - Inner Types

    associatedtype TransactionEntity: Entity
}

class TransactionQueue<Target: TransactionQueueTarget>
{
    // MARK: - Properties

    weak var target: Target?

    // MARK: - Functions

    func enqueueAsync<T: Transaction>(transaction: T, completion: ((Result<T.Result>) -> Void)? = nil) where T.TransactionEntity == Target.TransactionEntity
    {
        return self.queue.async {
            do {
                let result: T.Result = try self.getTarget().run(transaction: transaction)

                if let completion = completion
                {
                    DispatchQueue.global().async {
                        completion(.success(result))
                    }
                }
            }
            catch let error {
                if let completion = completion
                {
                    DispatchQueue.global().async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func enqueueSync<T: Transaction>(transaction: T) throws -> T.Result where T.TransactionEntity == Target.TransactionEntity
    {
        return try self.queue.sync {
            return try self.getTarget().run(transaction: transaction)
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
