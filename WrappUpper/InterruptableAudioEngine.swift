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

    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }

    fileprivate var recorder: IterruptableAudioRecorder?
    fileprivate var player: AVAudioPlayer?
    fileprivate var callObserver = CXCallObserver()

    override init() {
        super.init()
        subsribeForNotifications()
        observerPhoneCalls()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func playLast() {
        guard let fileURL = recorder?.url, !isRecording else { return }
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

        let url = AudioEngineFileURLGenerator.generateAudioFileURL()

        let recorder: IterruptableAudioRecorder
        do {
            recorder = try IterruptableAudioRecorder(url: url, format: audioFormat)
        } catch {
            let message = "Failed init IterruptableAudioRecorder. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
        recorder.record()
        self.recorder = recorder
    }

    func stop() {
        guard isRecording else { return }
        recorder?.stop()
    }

    private var audioFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 2, interleaved: true)
    }
    
}

// MARK: - Recording methods

private extension InterruptableAudioEngine {

    func pauseRecording(interruption: AudioEngineInterruption) {
        guard let recorder = recorder else { return }
        recorder.pause(interruption: interruption)
        delegate?.audioEngineDidPause(self)
    }

    func resumeRecording() {
        guard let recorder = recorder else { return }
        recorder.record()
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
