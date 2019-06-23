import Vapor
import FluentKit
import RedisKit

func routes(_ r: Routes, _ c: Container) throws {
    guard let psql = try? c.make(Databases.self).database(.psql) else {
        fatalError()
    }
    
    let redis = try c.make(ConnectionPool<RedisConnectionSource>.self)
    
    let todoController = TodoController(db: psql, redis: redis)
    r.get("todos", use: todoController.index)
    r.post("todos", use: todoController.create)
    r.on(.DELETE, "todos", ":todoID", use: todoController.delete)
    
    let authController = AuthController(db: psql, redis: redis)
    r.post("login", use: authController.login)
    r.post("me", use: authController.me)
}
