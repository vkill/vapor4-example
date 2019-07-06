import Vapor
import FluentKit
import FluentPostgresDriver
import RedisKit

/// Called before your application initializes.
func configure(_ s: inout Services) throws {
    //
    let mainConfig = Constants.shared.mainConfig
    let workingDirectory = Constants.shared.workingDirectory
    
    //
    s.register(DirectoryConfiguration.self) { _ in
        return DirectoryConfiguration(workingDirectory: workingDirectory)
    }
    
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
    if let httpServerConfiguration = mainConfig.toHTTPServerConfiguration() {
        s.register(HTTPServer.Configuration.self) { _ in
            return httpServerConfiguration
        }
    }
    
    //
    s.register(PostgresConfiguration.self) { _ in
        return mainConfig.toPostgresConfiguration()
    }
    
    s.extend(Databases.self) { dbs, c in
        try dbs.postgres(config: c.make())
    }
    
    //
    s.register(RedisConfiguration.self) { _ in
        return mainConfig.toRedisConfiguration()
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
