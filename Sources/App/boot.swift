import Vapor

fileprivate var openexchangeratesFetcher: OpenexchangeratesFetcher!

func boot(_ application: Application) throws {

    openexchangeratesFetcher = OpenexchangeratesFetcher(application: application)
    application.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(0), delay: .hours(1)) { task in
        _ = openexchangeratesFetcher.fetchAndSaveLatest()
    }
}
