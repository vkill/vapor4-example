import Vapor
import FluentKit

struct Todo: Model {
    static let shared = Todo()
    let id = Field<Int?>("id")
    let title = Field<String>("title")
}
