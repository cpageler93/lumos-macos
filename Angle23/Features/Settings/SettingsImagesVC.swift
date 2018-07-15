//
//  SettingsImagesVC.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Cocoa


class SettingsImagesVC: NSViewController {

    @IBOutlet weak var pathControlImagesFolder: NSPathControl!
    @IBOutlet weak var tableViewImages: NSTableView!
    @IBOutlet weak var textFieldNumberOfImages: NSTextField!

    private var isVisible = false

    private var images: [ImageModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        pathControlImagesFolder.url = Preferences.imagesFolderPath
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notificationDidUpdateImagesNotification),
                                               name: ImageService.didUpdateImageNotification,
                                               object: nil)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        isVisible = true
        updateImages()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        isVisible = false
    }

    @objc private func notificationDidUpdateImagesNotification(_ notification: Notification) {
        updateImages()
    }

    private func updateImages() {
        guard isVisible else { return }
        images = ImageService.shared.allImages()
        tableViewImages.reloadData()
        textFieldNumberOfImages.stringValue = "\(images.count) Images"
    }

    // MARK: - Actions

    @IBAction func actionImagesFolderChangeClicked(_ sender: NSButton) {
        let dialog = NSOpenPanel();
        dialog.title                   = "Choose a folder"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == NSApplication.ModalResponse.OK, let url = dialog.url {
            pathControlImagesFolder.url = url
            Preferences.imagesFolderPath = url

            FolderBookmarkService.shared.storeFolderInBookmark(url: url)
            FolderBookmarkService.shared.saveBookmarksData()
            ImageService.shared.cleanImageStore()
        }
    }

}


extension SettingsImagesVC: NSTableViewDataSource {

    fileprivate enum CellIdentifiers {

        static let imageCell = "ImageCell"
        static let filenameCell = "FilenameCell"
        static let fromCell = "FromCell"
        static let viewCountCell = "ViewCountCell"
        static let showCell = "ShowCell"
        static let sortViewCountCell = "SortViewCountCell"
        static let createdDataCell = "CreatedDateCell"

    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return images.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let image = images[row]

        switch tableColumn {
        case tableView.tableColumns[0]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.imageCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? ImageTableCellView
            cell?.customImageView.image = image.nsImage()
            return cell
        case tableView.tableColumns[1]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.filenameCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = image.filename
            return cell
        case tableView.tableColumns[2]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.fromCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = image.uploadedFrom
            return cell
        case tableView.tableColumns[3]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.viewCountCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = "\(image.totalViewCount)"
            return cell
        case tableView.tableColumns[4]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.showCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? CheckboxTableCellView
            cell?.checkboxButton.state = image.show ? .on : .off
            cell?.checkboxButton.tag = row
            cell?.checkboxButton.action = #selector(actionCheckboxButton)
            return cell
        case tableView.tableColumns[5]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.sortViewCountCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = "\(image.sortViewCount)"
            return cell
        case tableView.tableColumns[6]:
            let identifier = NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.createdDataCell)
            let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
            let dateString = DateFormatter.localizedString(from: image.createdDate, dateStyle: .short, timeStyle: .short)
            cell?.textField?.stringValue = dateString
            return cell
        default:
            return nil
        }
    }

    @objc func actionCheckboxButton(_ sender: NSButton) {
        let image = images[sender.tag]
        ImageService.shared.write {
            image.show = sender.state == .on
        }
        tableViewImages.reloadData(forRowIndexes: IndexSet(integer: sender.tag),
                                   columnIndexes: IndexSet(integer: 4))
    }

}


extension SettingsImagesVC: NSTableViewDelegate {

}

