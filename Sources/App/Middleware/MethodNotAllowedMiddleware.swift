import Vapor

struct MethodNotAllowedMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).flatMapError { error in
            if let abortError = error as? AbortError, abortError.status == .methodNotAllowed {
                let response = Response(status: .methodNotAllowed)
                response.body = .init(string: "Method not allowed.")
                return request.eventLoop.makeSucceededFuture(response)
            }
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}