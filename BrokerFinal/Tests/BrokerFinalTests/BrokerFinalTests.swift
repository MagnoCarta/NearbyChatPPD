@testable import BrokerFinal
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct BrokerFinalTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "hello", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            })
        }
    }
    
    @Test("Getting all the Todos")
    func getAllTodos() async throws {
        try await withApp { app in
            let sampleTodos = [Todo(title: "sample1"), Todo(title: "sample2")]
            try await sampleTodos.create(on: app.db)
            
            try await app.testing().test(.GET, "todos", afterResponse: { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode([TodoDTO].self) == sampleTodos.map { $0.toDTO()} )
            })
        }
    }
    
    @Test("Creating a Todo")
    func createTodo() async throws {
        let newDTO = TodoDTO(id: nil, title: "test")
        
        try await withApp { app in
            try await app.testing().test(.POST, "todos", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let models = try await Todo.query(on: app.db).all()
                #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
            })
        }
    }
    
    @Test("Deleting a Todo")
    func deleteTodo() async throws {
        let testTodos = [Todo(title: "test1"), Todo(title: "test2")]
        
        try await withApp { app in
            try await testTodos.create(on: app.db)
            
            try await app.testing().test(.DELETE, "todos/\(testTodos[0].requireID())", afterResponse: { res async throws in
                #expect(res.status == .noContent)
                let model = try await Todo.find(testTodos[0].id, on: app.db)
                #expect(model == nil)
            })
        }
    }

    @Test("Queue offline messages")
    func queueMessages() async throws {
        try await withApp { app in
            let message = Message(senderID: UUID(), receiverID: UUID(), content: "hi")
            try await app.messageQueue.enqueue(message, for: message.receiverID)

            try await app.testing().test(.GET, "queue/\(message.receiverID.uuidString)", afterResponse: { res async throws in
                #expect(res.status == .ok)
                let messages = try res.content.decode([Message].self)
                #expect(messages.count == 1)
                #expect(messages.first?.content == message.content)
            })
        }
    }

    @Test("Update user status")
    func updateStatus() async throws {
        try await withApp { app in
            let userID = UUID()
            try await app.testing().test(.PUT, "status/\(userID.uuidString)", beforeRequest: { req in
                try req.content.encode(UserStatus.online)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
                let status = await app.locationRegistry.status(for: userID)
                #expect(status == .online)
            })
        }
    }

    @Test("Register user")
    func registerUser() async throws {
        try await withApp { app in
            let location = Location(latitude: 1, longitude: 2)
            try await app.testing().test(.POST, "users/register/alice", beforeRequest: { req in
                try req.content.encode(location)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(UserDTO.self)
                #expect(dto.name == "alice")
                let user = try await UserModel.query(on: app.db).filter(\.$name == "alice").first()
                #expect(user != nil)
            })
        }
    }

    @Test("Login user")
    func loginUser() async throws {
        try await withApp { app in
            let existing = UserModel(name: "bob", latitude: 0, longitude: 0, isOnline: false)
            try await existing.create(on: app.db)
            let location = Location(latitude: 3, longitude: 4)
            try await app.testing().test(.POST, "users/login/bob", beforeRequest: { req in
                try req.content.encode(location)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(UserDTO.self)
                #expect(dto.name == "bob")
                let user = try await UserModel.query(on: app.db).filter(\.$name == "bob").first()
                #expect(user?.latitude == location.latitude)
                #expect(user?.isOnline == true)
            })
        }
    }
}

extension TodoDTO: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}
