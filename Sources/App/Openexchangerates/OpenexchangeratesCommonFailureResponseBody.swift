struct OpenexchangeratesCommonFailureResponseBody {
    let status: Int
    let message: String
    let description: String
    
    static func `default`(status: Int) -> OpenexchangeratesCommonFailureResponseBody {
        return .init(status: status, message: "Unknown", description: "")
    }
}
