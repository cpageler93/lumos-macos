//
//  Server.swift
//  Lumos
//
//  Created by Christoph Pageler on 07.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import Embassy
import Ambassador
import NetworkService
import AppKit


class Server {

    static let shared = Server()

    private let networkServiceAngle32 = NetworkService()
    public let port: Int = 8082
    private var incomingImages = Set<String>()

    private init() {
        networkServiceAngle32.delegate = self
    }

    public func bonjourName() -> String {
        return NSFullUserName()
    }

    public func start() {
        let dispatchQueue = DispatchQueue(label: "de.pageler.christoph.lumos.macos.server.start",
                                          qos: .background,
                                          attributes: .concurrent,
                                          autoreleaseFrequency: .inherit,
                                          target: nil)
        dispatchQueue.async {
            let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
            let router = Router()
            let server = DefaultHTTPServer(eventLoop: loop, interface: "0.0.0.0", port: self.port, app: router.app)

            router["/api/v1/test"] = JSONResponse(handler: { _ -> Any in
                return [
                    "success": true
                ]
            })

            router["/api/v1/images"] = JSONResponse(handler: { _ -> Any in
                ImageService.shared.refresh()
                var images: [ImageModel] = []
                if let imagesResult = ImageService.shared.allImagesAsResult()?.sorted(byKeyPath: "createdDate", ascending: false) {
                    images = Array(imagesResult)
                }
                return [
                    "success": true,
                    "images": images.map({ image in
                        return [
                            "uuid": image.uuid,
                            "filename": image.filename,
                            "uploadedFrom": image.uploadedFrom,
                            "totalViewCount": image.totalViewCount,
                            "show": image.show,
                            "createdDate": ISO8601DateFormatter().string(from: image.createdDate),
                            "data": image.thumbnailData()?.base64EncodedString(options: .lineLength64Characters) ?? ""
                        ]
                    })
                ]
            })

            router["/api/v1/images/upload"] = JSONResponse { environ, respond in
                let input = environ["swsgi.input"] as! SWSGIInput
                JSONReader.read(input, handler: { data in
                    guard let dict = data as? [String: Any],
                        let uuid = dict["uuid"] as? String,
                        let image = dict["image"] as? String,
                        let name = dict["name"] as? String,
                        let imageData = Data(base64Encoded: image)
                    else {
                        respond([
                            "success": false
                        ])
                        return
                    }

                    // skip double requests
                    if self.incomingImages.contains(uuid) { return }
                    self.incomingImages.insert(uuid)

                    ImageService.shared.addNewImage(imageData, fromUserWithName: name)
                    respond([
                        "success": true
                    ])
                })
            }

            router["/api/v1/images/([a-zA-Z0-9-]+)"] = JSONResponse(handler: { environ -> Any in
                ImageService.shared.refresh()
                let captures = environ["ambassador.router_captures"] as? [String]
                guard let uuid = captures?.first else {
                    return [
                        "success": false,
                        "message": "UUID Parameter not found"
                    ]
                }

                guard let image = ImageService.shared.imageModelWith(uuid: uuid) else {
                    return [
                        "success": false,
                        "message": "Image not found"
                    ]
                }

                var base64DataString = ""
                if let imageData = image.imageData() {
                    base64DataString = imageData.base64EncodedString(options: .lineLength64Characters)
                }

                return [
                    "success": true,
                    "image": [
                        "uuid": image.uuid,
                        "filename": image.filename,
                        "uploadedFrom": image.uploadedFrom,
                        "totalViewCount": image.totalViewCount,
                        "show": image.show,
                        "createdDate": ISO8601DateFormatter().string(from: image.createdDate),
                        "data": base64DataString
                    ]
                ]
            })

            // Start HTTP server to listen on the port
            try! server.start()

            // Run event loop
            loop.runForever()
        }

        self.networkServiceAngle32.startPublish(type: .tcp(name: "lumos"),
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
