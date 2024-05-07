import Fluent
import Vapor

struct TodoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        
        todos.get("playSound") { req -> EventLoopFuture<Response> in
            let response = Response(status: .ok, body: .init(string: "Play the toot!"))
            return req.eventLoop.makeSucceededFuture(response)
        }
    }
}