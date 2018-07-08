//
//  SettingsServerVC.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Cocoa


class SettingsServerVC: NSViewController {

    @IBOutlet weak var textFieldServerInfo: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        textFieldServerInfo.stringValue = """
        Connect to this server:
        • connect to the same local network
        • start Angle23 for iPhone
        • select \"\(Server.shared.bonjourName())\"
        """
    }
    
}
