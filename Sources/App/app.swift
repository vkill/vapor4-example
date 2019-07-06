import Vapor

public func app(_ environment: Environment) throws -> Application {
    let application = Application(environment: environment, configure: configure)
    try boot(application)
    return application
}
