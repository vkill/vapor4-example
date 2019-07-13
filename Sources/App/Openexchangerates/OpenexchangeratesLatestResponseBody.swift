import Foundation

struct OpenexchangeratesLatestResponseBody: Codable {
    let error: Bool?
    let status: Int?
    let message: String?
    let description: String?
    
    let disclaimer: String?
    let license: String?
    let timestamp: Date?
    let base: CurrencyCode?
    let rates: [CurrencyCode : Float]?
    
    struct RatesKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        init?(intValue: Int) {
            self.stringValue = "\(intValue)";
            self.intValue = intValue
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.error = try values.decodeIfPresent(Bool.self, forKey: .error)
        if self.error == true {
            self.status = try values.decode(Int.self, forKey: .status)
            self.message = try values.decode(String.self, forKey: .message)
            self.description = try values.decode(String.self, forKey: .description)
            
            self.disclaimer = nil
            self.license = nil
            self.timestamp = nil
            self.base = nil
            self.rates = nil
        } else {
            self.status = nil
            self.message = nil
            self.description = nil
            
            self.disclaimer = try values.decode(String.self, forKey: .disclaimer)
            self.license = try values.decode(String.self, forKey: .license)
            let timestamp = try values.decode(UInt.self, forKey: .timestamp)
            self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestamp))
            self.base = try values.decode(CurrencyCode.self, forKey: .base)
            
            var rates: [CurrencyCode : Float] = [:]
            let ratesDict = try values.decode([String : Float].self, forKey: .rates)
            for (currencyCodeString, rate) in ratesDict {
                guard let currencyCode = CurrencyCode(rawValue: currencyCodeString) else {
                    throw DecodingError.typeMismatch(CurrencyCode.self, .init(codingPath: [CodingKeys.rates], debugDescription: "Unknown currencyCode \(currencyCodeString)"))
                }
                rates[currencyCode] = rate
            }
            
            self.rates = rates
        }
    }
    
    private var isError: Bool {
        return self.error == true
    }
    
    var failureResponseBody: OpenexchangeratesCommonFailureResponseBody? {
        guard isError else {
            return nil
        }
        return .init(status: status!, message: message!, description: description!)
    }
    
    var successResponseBody: OpenexchangeratesLatestSuccessResponseBody? {
        guard !isError else {
            return nil
        }
        
        return .init(disclaimer: disclaimer!, license: license!, timestamp: timestamp!, base: base!, rates: rates!)
    }
}

struct OpenexchangeratesLatestSuccessResponseBody {
    let disclaimer: String
    let license: String
    let timestamp: Date
    let base: CurrencyCode
    let rates: [CurrencyCode:Float]
}
