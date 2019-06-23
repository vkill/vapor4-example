import Vapor
import FluentKit
import RedisKit

final class TodoController {
    let db: Database
    let redis: ConnectionPool<RedisConnectionSource>
    
    init(db: Database, redis: ConnectionPool<RedisConnectionSource>) {
        self.db = db
        self.redis = redis
    }
    
    func index(req: Request) -> EventLoopFuture<[Row<Todo>]> {
        return Todo.query(on: self.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<Response> {
        let todo: Row<Todo>
        do {
            todo = try req.content.decode(Row<Todo>.self)
        } catch {
            throw Abort(.badRequest, reason: "\(error)")
        }
        
        return todo.save(on: self.db).flatMap { _ in
            return todo.encodeResponse(status: .created, for: req)
        }
    }
    
    func delete(req: Request) -> EventLoopFuture<HTTPStatus> {
        let todoID = req.parameters.get("todoID", as: Int.self)
        
        return Todo.find(todoID, on: self.db).flatMapThrowing { todo -> Row<Todo> in
            guard let todo = todo else {
                throw Abort(.notFound)
            }
            return todo
        }.flatMap { todo in
            return todo.delete(on: self.db).transform(to: .noContent)
        }
    }
}
