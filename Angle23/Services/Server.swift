//
//  Server.swift
//  Angle23
//
//  Created by Christoph Pageler on 07.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import Embassy
import Ambassador
import NetworkService


class Server {

    static let shared = Server()

    private let networkServiceAngle32 = NetworkService()
    public let port: Int = 8082

    private init() {
        networkServiceAngle32.delegate = self
    }

    public func bonjourName() -> String {
        return "Angle23 macOS \(NSFullUserName())"
    }

    public func start() {
        let dispatchQueue = DispatchQueue(label: "de.pageler.christoph.angle23.server.start",
                                          qos: .background,
                                          attributes: .concurrent,
                                          autoreleaseFrequency: .inherit,
                                          target: nil)
        dispatchQueue.async {
            let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
            let router = Router()
            let server = DefaultHTTPServer(eventLoop: loop, interface: "0.0.0.0", port: self.port, app: router.app)

            router["/api/v1/images"] = JSONResponse(handler: { _ -> Any in
                return [
                    ["id": "01", "name": "john"],
                    ["id": "02", "name": "tom"]
                ]
            })

            // Start HTTP server to listen on the port
            try! server.start()

            // Run event loop
            loop.runForever()
        }

        self.networkServiceAngle32.startPublish(type: .tcp(name: "angle32"),
                                                name: bonjourName(),
                                                port: Int32(self.port))
    }

}


extension Server: NetworkServiceDelegate {

    func networkService(_ networkService: NetworkService, didPublish service: NetService) {
        print("did publish")
    }

    func networkService(_ networkService: NetworkService, didNotPublish service: NetService) {
        print("did not publish")
    }

}
