import Vapor

struct Constants {
    static var shared: Constants!
    
    let workingDirectory: String
    let mainConfig: MainConfig
    
    // your settings
    let openexchangeratesAppID: String
    
    init(workingDirectory: String) throws {
        self.workingDirectory = workingDirectory
        self.mainConfig = try MainConfig(filePath: workingDirectory + "Config/main.toml")
        
        self.openexchangeratesAppID = mainConfig.openexchangerates.appID
        
        Self.shared = self
    }
}
