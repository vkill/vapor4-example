import Vapor

public func app(_ environment: Environment) throws -> Application {
    let workingDirectory = "/repos/vapor4-example/"
    _ = try Constants(workingDirectory: workingDirectory)
    
    let application = Application(environment: environment, configure: configure)
    try boot(application)
    return application
}
