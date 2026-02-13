//
//  SiriRemoteObserver.swift
//  SwiftUILearning
//
//  tvOS: Siri Remote — touch = orbit; ring up/down = zoom; center click = select; Play/Pause = orbit toggle; Menu/Back = orbit off.
//

#if os(tvOS)

import SwiftUI
import GameController

/// Siri Remote input observer. @Observable for modern SwiftUI data flow.
@Observable
final class TouchPanelObserver {
    var x: Float = 0
    var y: Float = 0
    var onPlayPause: (() -> Void)?
    var onZoomIn: (() -> Void)?
    var onZoomOut: (() -> Void)?
    var onClicked: (() -> Void)?

    private var isTouching = false

    init() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupController()
        }
        // Also try immediately in case controller is already connected
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupController()
        }
    }

    private func setupController() {
        guard let gc = GCController.controllers().first else {
            print("[Remote] No controller found")
            return
        }
        
        if let pad = gc.extendedGamepad {
            print("[Remote] Extended gamepad found")
            setupExtended(pad)
        } else if let pad = gc.microGamepad {
            print("[Remote] Micro gamepad found (old remote)")
            setupMicro(pad)
        }
    }

    private func setupExtended(_ pad: GCExtendedGamepad) {
        // Touch surface → orbit
        pad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            guard let self else { return }
            self.isTouching = (x != 0 || y != 0)
            DispatchQueue.main.async {
                self.x = x
                self.y = y
            }
        }

        // Ring click up/down → zoom
        pad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self, pressed, !self.isTouching else { return }
            print("[Remote] dpad.up pressed")
            DispatchQueue.main.async { self.onZoomIn?() }
        }
        pad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self, pressed, !self.isTouching else { return }
            print("[Remote] dpad.down pressed")
            DispatchQueue.main.async { self.onZoomOut?() }
        }

        // Center click → select
        pad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            guard pressed else { return }
            print("[Remote] buttonA pressed")
            DispatchQueue.main.async { self?.onClicked?() }
        }

        // Play/Pause
        pad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            guard pressed else { return }
            print("[Remote] buttonX (play/pause) pressed")
            DispatchQueue.main.async { self?.onPlayPause?() }
        }
    }
    
    private func setupMicro(_ pad: GCMicroGamepad) {
        pad.reportsAbsoluteDpadValues = true
        pad.dpad.valueChangedHandler = { [weak self] _, x, y in
            DispatchQueue.main.async {
                self?.x = x
                self?.y = y
            }
        }
        pad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            guard pressed, let self else { return }
            DispatchQueue.main.async {
                let y = self.y
                if y > 0.3 { self.onZoomIn?() }
                else if y < -0.3 { self.onZoomOut?() }
            }
        }
        pad.valueChangedHandler = { [weak self] micro, element in
            guard element === micro.buttonX, micro.buttonX.value > 0.5 else { return }
            print("[Remote] micro buttonX pressed")
            DispatchQueue.main.async { self?.onPlayPause?() }
        }
    }
}

#endif
