import Vapor

extension Application {
    private struct RegistryKey: StorageKey {
        typealias Value = LocationRegistry
    }

    var locationRegistry: LocationRegistry {
        if let existing = self.storage[RegistryKey.self] {
            return existing
        }
        let registry = LocationRegistry()
        self.storage[RegistryKey.self] = registry
        return registry
    }
}
