import Combine
import Foundation
import FoundationExtensions

/// WAMP Caller is a WAMP Client role that allows this Peer to call RPC procedures
public struct WampCaller {
    let session: WampSession

    init(session: WampSession) {
        self.session = session
    }

    public func call(procedure: URI, positionalArguments: [ElementType]? = nil, namedArguments: [String : ElementType]? = nil)
    -> Publishers.Promise<Message.Result, ModuleError> {
        guard let id = session.idGenerator.next() else { return .init(error: .sessionIsNotValid) }
        let messageBus = session.messageBus

        return session.send(
            Message.call(.init(request: id, options: [:], procedure: procedure, positionalArguments: positionalArguments, namedArguments: namedArguments))
        )
        .flatMap { () -> Publishers.Promise<Message.Result, ModuleError> in
            messageBus
                .setFailureType(to: ModuleError.self)
                .flatMap { message -> AnyPublisher<Message.Result, ModuleError> in
                    if case let .result(result) = message, result.request == id {
                        return Just<Message.Result>(result).setFailureType(to: ModuleError.self).eraseToAnyPublisher()
                    }

                    if case let .error(error) = message, error.requestType == Message.Call.type, error.request == id {
                        return Fail<Message.Result, ModuleError>(error: .commandError(error)).eraseToAnyPublisher()
                    }

                    return Empty().eraseToAnyPublisher()
                }
                .promise(onEmpty: { .failure(.sessionIsNotValid) })
        }
        .promise
    }

    public func progressCall(procedure: URI, positionalArguments: [ElementType]? = nil) -> AnyPublisher<Message.Result, ModuleError> {
        guard let id = session.idGenerator.next()
            else { return Fail<Message.Result, ModuleError>(error: .sessionIsNotValid).eraseToAnyPublisher() }
        let messageBus = session.messageBus

        return session.send(
            Message.call(.init(request: id, options: [:], procedure: procedure, positionalArguments: positionalArguments, namedArguments: nil))
        )
        .flatMap { () -> AnyPublisher<Message.Result, ModuleError> in
            messageBus
                .setFailureType(to: ModuleError.self)
                .flatMap { message -> AnyPublisher<Message.Result, ModuleError> in
                    if case let .result(result) = message, result.request == id {
                        return Just<Message.Result>(result).setFailureType(to: ModuleError.self).eraseToAnyPublisher()
                    }

                    if case let .error(error) = message, error.requestType == Message.Call.type, error.request == id {
                        return Fail<Message.Result, ModuleError>(error: .commandError(error)).eraseToAnyPublisher()
                    }

                    return Empty().eraseToAnyPublisher()
                }.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
