import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: TodoController())
    let hubController = ChatWebSocketController(app: app)
    try app.register(collection: hubController)
    try app.register(collection: MessageQueueController())
    try app.register(collection: MessageHistoryController(store: app.messageStore))
    try app.register(collection: ContactsController(registry: app.locationRegistry, hub: hubController.hub))
    try app.register(collection: StatusController(registry: app.locationRegistry, hub: hubController.hub))
    try app.register(collection: UsersController())
}
