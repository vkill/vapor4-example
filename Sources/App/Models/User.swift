import Vapor
import JWTKit

struct User {
    static var all: [User] {
        return [User(login: "admin", encryptedPassword: try! BCrypt.hash("123456", cost: 11).string())]
    }
    
    let login: String
    private let encryptedPassword: String

    func verifyPassword(_ unencryptedPassword: String) -> Bool {
        return true == (try? BCrypt.verify(.string(unencryptedPassword), created: .string(encryptedPassword)))
    }
}

extension User {
    struct AuthPayload: JWTPayload, Equatable {
        var login: String
        var exp: ExpirationClaim
        
        func verify(using signer: JWTSigner) throws {
            try self.exp.verifyNotExpired()
        }
    }
    private static let jwtSigner = JWTSigner.hs256(key: Data("JWTKEY".utf8))
    
    func makeAccessToken() throws -> String {
        let payload = AuthPayload(
            login: login,
            exp: .init(value: Date(timeIntervalSinceNow: 3600))
        )
        let jwt = JWT(payload: payload)
        let token = try jwt.sign(using: type(of: self).jwtSigner)
        return String(decoding: token, as: UTF8.self)
    }
    
    static func verifyAccessToken(_ accessToken: String) throws -> AuthPayload {
        let jwt = try JWT<AuthPayload>(from: [UInt8](accessToken.utf8), verifiedBy: jwtSigner)
        return jwt.payload
    }
}
