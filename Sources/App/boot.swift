import Vapor

func boot(_ application: Application) throws {
    let workingDirectory = "/repos/vapor4-example/"
    let mainConfig = try MainConfig(filePath: workingDirectory + "Config/main.toml")
    _ = Constants(mainConfig: mainConfig, workingDirectory: workingDirectory)
}
