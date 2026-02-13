//
//  SiriRemoteObserver.swift
//  SwiftUILearning
//
//  tvOS: Siri Remote (Apple TV 4K gen 4 i sl.) — GCMicroGamepad.
//  - Touch (x, y): orbit kamera; dpad.valueChangedHandler.
//  - Zoom: dpad.up / dpad.down (samo kad nije swipe — isTouching flag).
//  - Play/Pause: Button X → orbit toggle.
//

#if os(tvOS)

import SwiftUI
import Combine
import GameController
import UIKit

/// Siri Remote: touch (x,y) za orbit; dpad.up/down za zoom (samo kad nije swipe); Play/Pause = Button X.
final class TouchPanelObserver: ObservableObject {
    @Published var x: Float = 0
    @Published var y: Float = 0
    var onPlayPause: (() -> Void)?
    var onZoomIn: (() -> Void)?
    var onZoomOut: (() -> Void)?

    private var isTouching = false

    init() {
        setupController()
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupController()
        }
    }

    private func setupController() {
        guard let gc = GCController.controllers().first,
              let pad = gc.microGamepad else { return }
        pad.reportsAbsoluteDpadValues = true
        pad.dpad.valueChangedHandler = { [weak self] _, x, y in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isTouching = (abs(x) > 0.1 || abs(y) > 0.1)
                self.x = x
                self.y = y
            }
        }
        pad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self, pressed, !self.isTouching else { return }
            DispatchQueue.main.async { self.onZoomIn?() }
        }
        pad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self, pressed, !self.isTouching else { return }
            DispatchQueue.main.async { self.onZoomOut?() }
        }
        pad.valueChangedHandler = { [weak self] microGamepad, element in
            guard element === microGamepad.buttonX, microGamepad.buttonX.value > 0.5 else { return }
            print("[Play/Pause] button pressed on remote (GameController buttonX)")
            DispatchQueue.main.async {
                self?.onPlayPause?()
            }
        }
    }
}

#endif
