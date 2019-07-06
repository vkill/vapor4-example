import Vapor

struct Constants {
    static var shared: Constants!
    
    let mainConfig: MainConfig
    let workingDirectory: String
    
    // your settings
    
    init(mainConfig: MainConfig, workingDirectory: String) {
        self.mainConfig = mainConfig
        self.workingDirectory = workingDirectory
        
        Self.shared = self
    }
}
