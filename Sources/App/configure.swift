import Vapor
import FluentKit
import FluentPostgresDriver
import RedisKit

/// Called before your application initializes.
func configure(_ s: inout Services) throws {
    /// Register providers first
    s.singleton(Databases.self) { c in
        return .init(on: c.eventLoop)
    }
    
    /// Register routes
    s.extend(Routes.self) { r, c in
        try routes(r, c)
    }
    
    /// Register middleware
    s.register(MiddlewareConfiguration.self) { c in
        // Create _empty_ middleware config
        var middlewares = MiddlewareConfiguration()
        
        // Serves files from `Public/` directory
        /// middlewares.use(FileMiddleware.self)
        
        // Catches errors and converts to HTTP response
        try middlewares.use(c.make(ErrorMiddleware.self))
        
        return middlewares
    }
    
    //
    s.register(PostgresConfiguration.self) { c in
        return .init(
            hostname: "127.0.0.1",
            port: 5432,
            username: "postgres",
            password: "",
            database: "test"
        )
    }
    
    s.extend(Databases.self) { dbs, c in
        try dbs.postgres(config: c.make())
    }
    
    //
    s.register(RedisConfiguration.self) { c in
        return .init(
            hostname: "127.0.0.1",
            port: 6379,
            password: nil,
            database: nil,
            logger: nil
        )
    }
    
    s.register(RedisConnectionSource.self) { c in
        let config = try c.make(RedisConfiguration.self)
        return .init(
            config: config,
            eventLoop: c.eventLoop
        )
    }
    
    s.register(ConnectionPool<RedisConnectionSource>.self) { c in
        let source = try c.make(RedisConnectionSource.self)
        return .init(
            config: .init(maxConnections: 2),
            source: source
        )
    }
}