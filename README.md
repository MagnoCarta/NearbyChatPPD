# FinalPPD

This repository contains a demo implementation of a location-based communication system. The project is split in two major targets:

- **BrokerFinal** – a [Vapor](https://vapor.codes) server application that will act as a message broker.
- **PPDFinal** – a SwiftUI client application following the Model‑View‑ViewModel (MVVM) architecture.

## Requirements overview

The project implements the core features of a location‑based communication system:

1. Synchronous messaging between online users via WebSocket connections.
2. Asynchronous messaging for offline users using a shared message queue (Redis or in‑memory).
3. Queued messages are delivered only when the recipient comes online.
4. Each user manages a personal contact list.
5. Users are instantiated with name, geographic coordinates and online status.
6. A configurable radius limits which contacts can communicate in real time.
7. Contacts are refreshed whenever someone enters the user’s radius.
8. Location, status and radius can be updated at any time.
9. Live chat is permitted only for contacts that are online and inside the radius.
10. Offline or out‑of‑range contacts receive messages through the asynchronous queue.

For a presentation‑style explanation of these points, see [presentation_script.md](presentation_script.md).

## SwiftUI project structure

The `PPDFinal` target now contains dedicated folders for the MVVM pattern:

```
PPDFinal/
├── Models
├── ViewModels
├── Views
├── Services
```

Core models for the application live in the **Models** directory. These include
`User`, `Contact`, `Message` and `Settings` which define the basic data
structures for identifying users, persisting conversations and storing app
preferences.

`ContentView.swift` has been moved into the `Views` folder. New models, view models and services will live in their respective directories as the project evolves.
Recent updates introduced lightweight view models built using the Observation framework. `AuthViewModel`, `ContactsViewModel`, `ChatViewModel` and `LocationViewModel` coordinate the app logic and expose observable state to SwiftUI views.

The UI now features dedicated screens for the most common flows:

* **LoginView** – prompts for a username and creates the local `User` model.
* **ContactsListView** – lists nearby contacts with their online state and distance.
* **ChatView** – displays messages and allows sending new ones.
* **SettingsView** – toggles app options like notification radius.

Networking code now includes a **WebSocketService** that maintains a persistent
connection to the broker. It automatically attempts to reconnect when the
connection drops and relays incoming `Message` payloads to interested
listeners. The service operates on a dedicated `WebSocketActor` global actor and
uses Swift concurrency tasks for reconnection.
An `APIClient` service handles REST communication with the broker for queued messages, status updates and contact sync.

Messages exchanged in chats are persisted locally using a lightweight **MessageStore** powered by SwiftData. This allows previously received or sent messages to be restored when the app is launched offline.

`ChatViewModel` now binds this WebSocket service directly to the chat UI. When a
`ChatView` appears it connects to the server, sending any drafted message over
the WebSocket and appending incoming messages in real time. The connection is
closed when leaving the screen.

The broker exposes a `/chat/{userID}` WebSocket route managed by a new
`WebSocketHub`. Clients register under their user ID and messages are forwarded
to recipients if they are currently connected.
The server now supports binary JSON frames in addition to text for greater flexibility.


## Running

Both the iOS app and the server can be built with the Swift Package Manager.

```bash
# Build Vapor backend
cd BrokerFinal && swift build

# Build iOS app
cd ../PPDFinalApp && swift build
```

When running the server locally ensure it binds to the IPv4 loopback interface
so the simulator can connect:

```bash
cd BrokerFinal
swift run --hostname 0.0.0.0 --port 8080
```

The client already points to `127.0.0.1:8080` by default.

Refer to the individual README files in each target for more details.

## Testing

To run the server's unit tests:

```bash
cd BrokerFinal
swift test
```


