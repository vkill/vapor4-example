import Vapor
import FluentKit
import RedisKit

final class AuthController {
    let db: Database
    let redis: ConnectionPool<RedisConnectionSource>
    
    init(db: Database, redis: ConnectionPool<RedisConnectionSource>) {
        self.db = db
        self.redis = redis
    }
    
    struct LoginRequestBody: Content {
        let login: String
        let password: String
    }
    struct LoginResponseBody: Content {
        let accessToken: String
        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
    
    func login(req: Request) throws -> EventLoopFuture<LoginResponseBody> {
        let reqBody: LoginRequestBody
        do {
            reqBody = try req.content.decode(LoginRequestBody.self)
        } catch {
            throw Abort(.badRequest, reason: "\(error)")
        }
        
        
        guard let user = User.all.filter({$0.login == reqBody.login}).first else {
            throw Abort(.unauthorized, reason: "login or password incorrect")
        }
        guard user.verifyPassword(reqBody.password) else {
            throw Abort(.unauthorized, reason: "login or password incorrect")
        }
        
        let accessToken = try user.makeAccessToken()
        
        return redis.withConnection { redis in
            return redis.hset("currentLoginTS", to: Date().timeIntervalSince1970, in: "User:\(user.login):").map { _ in
                return LoginResponseBody(accessToken: accessToken)
            }
        }
    }
    
    struct MeResponseBody: Content {
        let currentLoginTS: String?
        private enum CodingKeys: String, CodingKey {
            case currentLoginTS = "current_login_timestamp"
        }
    }
    
    func me(req: Request) throws -> EventLoopFuture<MeResponseBody> {
        guard let accessToken = req.headers["x-access-token"].first, let payload = try? User.verifyAccessToken(accessToken) else {
            throw Abort(.forbidden)
        }
        
        return redis.withConnection { redis in
            return redis.hget("currentLoginTS", from: "User:\(payload.login):").map { currentLoginTS in
                return MeResponseBody(currentLoginTS: currentLoginTS)
            }
        }
    }
}
