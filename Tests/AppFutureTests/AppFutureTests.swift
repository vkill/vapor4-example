import XCTest
@testable import App
import Vapor

fileprivate let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()

final class AppFutureTests: XCTestCase {
    private static var port: Int = 8080
    private static var process: Process!
    private static var pipe: Pipe!
    
    override static func setUp() {
        let workingDirectory = "/repos/vapor4-example/"
        let mainConfig = try! MainConfig(filePath: workingDirectory + "Config/main.toml")
        if let httpServerConfiguration = mainConfig.toHTTPServerConfiguration() {
            self.port = httpServerConfiguration.port
        }
        
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let runBinary = productsDirectory.appendingPathComponent("Run")
        
        let process = Process()
        process.executableURL = runBinary
        process.arguments = ["-e", "test"]

        let pipe = Pipe()
        process.standardOutput = pipe
        
        try! process.run()
        
        self.process = process
        self.pipe = pipe
    }
    
    override static func tearDown() {
        process.terminate()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        
        print(output)
    }
    
    func testPostLoginThenGetMe() throws {
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
        
        var loginReq = try HTTPClient.Request(url: "http://127.0.0.1:\(type(of: self).port)/login", method: .POST, body: .string("""
{
    "login": "admin",
    "password": "123456"
}
"""))
        loginReq.headers.add(name: .contentType, value: "application/json")

        let loginRes = try httpClient.execute(request: loginReq).wait()
        
        XCTAssertEqual(loginRes.status, .ok)
        guard let loginResBody = loginRes.body else { fatalError() }
        
        struct LoginResBodyObject: Decodable {
            let access_token: String
        }
        
        let loginResBodyObject = try JSONDecoder().decode(LoginResBodyObject.self, from: loginResBody.getData(at: 0, length: loginResBody.readableBytes)!)
        
        var meReq = try HTTPClient.Request(url: "http://127.0.0.1:\(type(of: self).port)/me", method: .GET)
        meReq.headers.add(name: "x-access-token", value: loginResBodyObject.access_token)
        
        let meRes = try httpClient.execute(request: meReq).wait()
        
        XCTAssertEqual(meRes.status, .ok)
    }
    
    static var allTests = [
        ("testPostLoginThenGetMe", testPostLoginThenGetMe),
    ]
}

extension AppFutureTests {
    static var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
}
