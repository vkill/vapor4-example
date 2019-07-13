import Foundation
import NIOHTTPClient
import NIO
import NIOHTTP1

final class OpenexchangeratesClient {
    let appID: String
    let eventLoop: EventLoop

    init(appID: String, on eventLoop: EventLoop) {
        self.appID = appID
        self.eventLoop = eventLoop
    }
    
    private func getHTTPClient() -> HTTPClient {
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
        defer {
            try? httpClient.syncShutdown()
        }
        return httpClient
    }
    
    private func getResponseData(response: HTTPClient.Response) -> Data? {
        guard let body = response.body else {
            return nil
        }
        
        guard let contentLengthHeader = response.headers.filter({ $0.0 == "Content-Length" }).first, let contentLengthVal = Int(contentLengthHeader.value) else {
            return body.getData(at: 0, length: body.readableBytes)
        }
        
        return body.getData(at: 0, length: contentLengthVal)
    }
}

extension OpenexchangeratesClient {
    enum FetchLatestError: Error {
        case requestBuildFailed(Error)
        case responseStatusNotOK
        case responseBodyEmpty
        case responseBodyInvalid(Error)
        case responseBodyFailure(OpenexchangeratesCommonFailureResponseBody)
    }
    
    func fetchLatest() -> EventLoopFuture<Result<OpenexchangeratesLatestSuccessResponseBody, FetchLatestError>> {
        let request: HTTPClient.Request
        do {
            request = try HTTPClient.Request(
                url: "https://openexchangerates.org/api/latest.json?app_id=\(self.appID)",
                method: .GET
            )
        } catch {
            return self.eventLoop.future(.failure(.requestBuildFailed(error)))
        }
        
        return getHTTPClient().execute(request: request).flatMap { response in
            guard response.status == .ok else {
                guard let responseBodyData = self.getResponseData(response: response) else {
                    return self.eventLoop.future(.failure(.responseStatusNotOK))
                }
                
                let responseBody: OpenexchangeratesLatestResponseBody
                do {
                    responseBody = try JSONDecoder().decode(OpenexchangeratesLatestResponseBody.self, from: responseBodyData)
                } catch {
                    return self.eventLoop.future(.failure(.responseStatusNotOK))
                }
                
                let failureResponseBody = responseBody.failureResponseBody ?? OpenexchangeratesCommonFailureResponseBody.default(status: Int(response.status.code))
                return self.eventLoop.future(.failure(.responseBodyFailure(failureResponseBody)))
            }
            
            guard let responseBodyData = self.getResponseData(response: response) else {
                return self.eventLoop.future(.failure(.responseBodyEmpty))
            }
            
            let responseBody: OpenexchangeratesLatestResponseBody
            do {
                responseBody = try JSONDecoder().decode(OpenexchangeratesLatestResponseBody.self, from: responseBodyData)
            } catch {
                return self.eventLoop.future(.failure(.responseBodyInvalid(error)))
            }
            
            guard let successResponseBody = responseBody.successResponseBody else {
                let failureResponseBody = responseBody.failureResponseBody ?? OpenexchangeratesCommonFailureResponseBody.default(status: Int(response.status.code))
                return self.eventLoop.future(.failure(.responseBodyFailure(failureResponseBody)))
            }
            
            return self.eventLoop.future(.success(successResponseBody))
        }
    }
}
