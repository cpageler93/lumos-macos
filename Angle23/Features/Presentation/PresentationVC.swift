//
//  PresentationVC.swift
//  Angle23
//
//  Created by Christoph Pageler on 07.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Cocoa


class PresentationVC: NSViewController {

    @IBOutlet weak var presentationImageView1: PresentationImageView!
    @IBOutlet weak var presentationImageView2: PresentationImageView!
    private weak var activePresentationImageView: PresentationImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationImageView1.image = nil
        presentationImageView2.image = nil
        presentationImageView1.alphaValue = 0
        presentationImageView2.alphaValue = 0
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        togglePresentationImageView(animated: false)
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { (timer) in
            self.togglePresentationImageView()
        }
    }

}

// MARK: - Image Presentation

private extension PresentationVC {

    private func fetchNextImage() -> NSImage? {
        guard let nextImage = ImageService.shared.fetchNextImageFromQueue() else { return nil }
        return nextImage.nsImage()
    }

    private func togglePresentationImageView(animated: Bool = true) {
        let nextPresentationImageView: PresentationImageView
        if activePresentationImageView == presentationImageView1 {
            nextPresentationImageView = presentationImageView2
        } else {
            nextPresentationImageView = presentationImageView1
        }

        nextPresentationImageView.image = fetchNextImage()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animated ? 2 : 0
            activePresentationImageView?.animator().alphaValue = 0
            nextPresentationImageView.animator().alphaValue = 1
        }, completionHandler: {
            self.activePresentationImageView = nextPresentationImageView
        })
    }

}

