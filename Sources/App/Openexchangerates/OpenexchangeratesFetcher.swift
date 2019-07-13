import Vapor
import FluentKit
import FluentPostgresDriver
import NIO

final class OpenexchangeratesFetcher {
    private let application: Application

    private final class DatabaseCache {
        var database: Database
        init(database: Database) {
            self.database = database
        }
    }
    public let eventLoop: EventLoop
    private var containers: [Container]
    private let databaseCache: ThreadSpecificVariable<DatabaseCache>
    
    private let logger: Logger
    
    init(application: Application, eventLoop: EventLoop? = nil, logger: Logger? = nil) {
        self.application = application
        self.eventLoop = eventLoop ?? MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        self.containers = []
        self.databaseCache = .init()
    
        self.logger = logger ?? Logger(label: "OpenexchangeratesFetcher")
    }
    
    deinit {
        shutdown()
    }
    
    private func shutdown() {
        let masterContainers = self.containers
        self.containers = []

        for container in masterContainers {
            if let database = try? container.make(Databases.self).default() {
                _ = database.close()
            }
            container.shutdown()
        }
    }
    
    private func getDatabase(on eventLoop: EventLoop) -> EventLoopFuture<Database> {
        assert(eventLoop.inEventLoop)
        
        if let database = self.databaseCache.currentValue?.database {
            return self.eventLoop.future(database)
        } else {
            return self.application.makeContainer(on: eventLoop).flatMapThrowing { container in
                self.containers.append(container)
                let database = try container.make(Databases.self).default()
                self.databaseCache.currentValue = DatabaseCache(database: database)
                return database
            }
        }
    }
    
    func fetchAndSaveLatest() -> EventLoopFuture<()> {
        self.eventLoop.future().flatMap { _ in
            return OpenexchangeratesClient(appID: Constants.shared.openexchangeratesAppID, on: self.eventLoop).fetchLatest().flatMap { result in
                switch result {
                case .failure(let error):
                    self.logger.error("fetch openexchangerates latest failed, error \(error)")
                    return self.eventLoop.future()
                case .success(let body):
                    return self.getDatabase(on: self.eventLoop).flatMap { database in
                        var saveFutures: [EventLoopFuture<()>] = []
                        for (toCurrencyCode, rate) in body.rates {
                            let row = Row<ExchangeRateModel>()
                            row.set(\.baseCurrencyCode, to: body.base)
                            row.set(\.toCurrencyCode, to: toCurrencyCode)
                            row.set(\.rate, to: rate)
                            row.set(\.timestamp, to: body.timestamp)
                            saveFutures.append(row.save(on: database))
                        }
                        
                        return saveFutures.flatten(on: self.eventLoop).transform(to: ())
                    }
                }
            }
        }
    }
}
