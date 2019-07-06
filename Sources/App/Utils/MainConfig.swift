import Vapor
import FluentPostgresDriver
import RedisKit
import TOMLDecoder

struct MainConfig: Decodable {
    struct HTTPServer: Decodable {
        let hostname: String?
        let port: Int?
    }
    let httpServer: HTTPServer?
    
    struct Postgres: Decodable {
        let hostname: String?
        let port: Int?
        let database: String
        let username: String?
        let password: String?
    }
    let postgres: Postgres?
    
    struct Redis: Decodable {
        let hostname: String?
        let port: Int?
        let database: Int?
        let password: String?
    }
    let redis: Redis?
    
    private enum CodingKeys: String, CodingKey {
        case httpServer = "http_server"
        case postgres
        case redis
    }
}

extension MainConfig {
    init(filePath: String) throws {
        let tomlData = try Data(String(contentsOfFile: filePath).utf8)
        self = try TOMLDecoder().decode(Self.self, from: tomlData)
    }
}

extension MainConfig {
    func toHTTPServerConfiguration() -> Vapor.HTTPServer.Configuration? {
        return .init(
            hostname: httpServer?.hostname ?? "127.0.0.1",
            port: httpServer?.port ?? 8080
        )
    }
    
    func toPostgresConfiguration() -> PostgresConfiguration {
        return .init(
            hostname: postgres?.hostname ?? "127.0.0.1",
            port: postgres?.port ?? 5432,
            username: postgres?.username ?? "postgres",
            password: postgres?.password ?? "",
            database: postgres?.database
        )
    }
    
    func toRedisConfiguration() -> RedisConfiguration {
        return .init(
            hostname: redis?.hostname ?? "127.0.0.1",
            port: redis?.port ?? 6379,
            password: redis?.password,
            database: redis?.database,
            logger: nil
        )
    }
}
