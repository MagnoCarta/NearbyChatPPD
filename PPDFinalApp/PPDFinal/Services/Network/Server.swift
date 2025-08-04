//
//  Server.swift
//  PPDFinal
//
//  Created by Gilberto Magno on 04/08/25.
//

import Foundation

struct Server {
    static let local: URLComponents = {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.port = 8080
        return components
    }()
}

@globalActor actor StorageActor: GlobalActor {
    static let shared = StorageActor()
}
