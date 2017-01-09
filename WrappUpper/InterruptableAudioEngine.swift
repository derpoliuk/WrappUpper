//
//  InterruptableAudioEngine.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import UIKit
import AVFoundation
import CallKit

final class InterruptableAudioEngine: NSObject, AudioEngine {

    weak var delegate: AudioEngineDelegate?

    var isRecording = false

    fileprivate var recorder: InterruptableAudioRecorder?
    fileprivate var player: AVAudioPlayer?
    fileprivate var callObserver = CXCallObserver()

    override init() {
        super.init()
        subsribeForNotifications()
        observerPhoneCalls()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            let message = "Error setting category for AVAudioSession. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var lastURL: URL?

    func playLast() {
        guard let fileURL = lastURL, !isRecording else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.play()
            self.player = player
        } catch {
            let message = "Failed init AVAudioPlayer. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
    }

    func record() {
        guard !isRecording else { return }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            let message = "Error setting AVAudioSession active. Reason: \(error.localizedDescription)"
            fatalError(message)
        }

        isRecording = true


        let recorder: InterruptableAudioRecorder
        if let e = self.recorder {
            recorder = e
        } else {
            let url = AudioEngineFileURLGenerator.generateAudioFileURL()
            recorder = InterruptableAudioRecorder(url: url, format: audioFormat)
            lastURL = url
        }

        do {
            try recorder.record()
        } catch {
            let message = "Failed init start recorder. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
        self.recorder = recorder
    }

    func stop() {
        guard isRecording else { return }

        isRecording = false

        do {
            try recorder?.stop()
        } catch {
            let message = "Failed init stop recorder. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
        recorder = nil
    }

    private var audioFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 2, interleaved: true)
    }
    
}

// MARK: - Recording methods

private extension InterruptableAudioEngine {

    //TODO: remove force try
    func pauseRecording(interruption: AudioEngineInterruption) {
        guard let recorder = recorder else { return }
        recorder.pause(interruption: interruption)
        delegate?.audioEngineDidPause(self)
    }

    func resumeRecording() {
        guard let recorder = recorder, UIApplication.shared.applicationState == .active else { return }
        do {
            try recorder.record()
        } catch {
            let message = "Failed resume recording. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
        delegate?.audioEngineDidResume(self)
    }

}

// MARK: - Call Observer

extension InterruptableAudioEngine: CXCallObserverDelegate {

    func observerPhoneCalls() {
        callObserver.setDelegate(self, queue: DispatchQueue.main)
    }

    /*
     applicationDidBecomeActive
     call.isOutgoing: false
     call.isOnHold: false
     call.hasConnected: false
     call.hasEnded: false
     applicationWillResignActive
     call.isOutgoing: false
     call.isOnHold: false
     call.hasConnected: true
     call.hasEnded: false
     aplicationDidEnterBackground
     applicationWillEnterForeground
     call.isOutgoing: false
     call.isOnHold: false
     call.hasConnected: true
     call.hasEnded: true
     applicationDidBecomeActive
     */
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if !call.hasEnded {
            pauseRecording(interruption: .call)
        } else {
            resumeRecording()
        }
    }

}

// MARK: - Notifications

private extension InterruptableAudioEngine {

    func subsribeForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(audioSessionInterruption(_:)), name: Notification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(aplicationDidEnterBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    @objc func audioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let interruptionType = AVAudioSessionInterruptionType(rawValue: rawType) else { return }
        if interruptionType == .began {
            pauseRecording(interruption: .default)
        } else {
            resumeRecording()
        }
    }

    @objc func aplicationDidEnterBackground(_ notification: Notification) {
        pauseRecording(interruption: .default)
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        resumeRecording()
    }

}
