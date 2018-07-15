//
//  ImageModel.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import RealmSwift


class ImageModel: Object {

    @objc dynamic var uuid = UUID().uuidString
    @objc dynamic var filename = ""
    @objc dynamic var uploadedFrom = ""
    @objc dynamic var createdDate: Date = Date()
    @objc dynamic var lastViewedDate: Date? = nil
    @objc dynamic var totalViewCount: Int = 0
    @objc dynamic var sortViewCount: Int = 0
    @objc dynamic var show: Bool = true

}
