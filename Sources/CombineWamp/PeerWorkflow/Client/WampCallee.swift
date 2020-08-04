import Combine
import Foundation
import FoundationExtensions

/// WAMP Callee is a WAMP Client role that allows this Peer to register RPC procedures and respond to their calls
public struct WampCallee {
    let session: WampSession

    init(session: WampSession) {
        self.session = session
    }

    public func register(procedure: URI, onUnregister: @escaping (Publishers.Promise<Message.Unregistered, ModuleError>) -> Void)
    -> AnyPublisher<(invocation: Message.Invocation, responder: ([ElementType]) -> Publishers.Promise<Void, ModuleError>), ModuleError> {
        guard let id = session.idGenerator.next() else { return Fail(error: .sessionIsNotValid).eraseToAnyPublisher() }
        let messageBus = session.messageBus

        return session.send(
            Message.register(.init(request: id, options: [:], procedure: procedure))
        )
        .flatMap { () -> Publishers.Promise<Message.Registered, ModuleError> in
            messageBus
                .setFailureType(to: ModuleError.self)
                .flatMap { message -> AnyPublisher<Message.Registered, ModuleError> in
                    if case let .registered(registered) = message, registered.request == id {
                        return Just<Message.Registered>(registered).setFailureType(to: ModuleError.self).eraseToAnyPublisher()
                    }

                    if case let .error(error) = message, error.requestType == Message.Register.type, error.request == id {
                        return Fail<Message.Registered, ModuleError>(error: .commandError(error)).eraseToAnyPublisher()
                    }

                    return Empty().eraseToAnyPublisher()
                }
                .first()
                .promise
        }
        .map { registeredMessage -> AnyPublisher<(invocation: Message.Invocation, responder: ([ElementType]) -> Publishers.Promise<Void, ModuleError>), ModuleError> in
            messageBus
                .setFailureType(to: ModuleError.self)
                .compactMap { message in
                    guard case let .invocation(invocation) = message,
                          invocation.registration == registeredMessage.registration
                    else { return nil }

                    return (
                        invocation: invocation,
                        responder: { [weak session] response in
                            guard let session = session else { return .init(error: .sessionIsNotValid) }
                            return Self.responder(session: session, invocation: invocation, response: response)
                        })
                }
                .handleEvents(
                    receiveCancel: {
                        onUnregister(unregister(registration: registeredMessage.registration))
                    }
                )
                .eraseToAnyPublisher()
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }

    private static func responder(session: WampSession, invocation: Message.Invocation, response: [ElementType]) -> Publishers.Promise<Void, ModuleError> {
        return session.send(
            Message.yield(.init(request: invocation.request, options: [:], positionalArguments: response, namedArguments: nil))
        )
    }

    private func unregister(registration: WampID) -> Publishers.Promise<Message.Unregistered, ModuleError> {
        guard let id = session.idGenerator.next() else { return .init(error: .sessionIsNotValid) }
        let messageBus = session.messageBus

        return session.send(
            Message.unregister(.init(request: id, registration: registration))
        )
        .flatMap { () -> Publishers.Promise<Message.Unregistered, ModuleError> in
            messageBus
                .setFailureType(to: ModuleError.self)
                .flatMap { message -> AnyPublisher<Message.Unregistered, ModuleError> in
                    if case let .unregistered(unregistered) = message, unregistered.request == id {
                        return Just<Message.Unregistered>(unregistered).setFailureType(to: ModuleError.self).eraseToAnyPublisher()
                    }

                    if case let .error(error) = message, error.requestType == Message.Unregistered.type, error.request == id {
                        return Fail<Message.Unregistered, ModuleError>(error: .commandError(error)).eraseToAnyPublisher()
                    }

                    return Empty().eraseToAnyPublisher()
                }
                .first()
                .promise
        }
        .promise
    }
}
