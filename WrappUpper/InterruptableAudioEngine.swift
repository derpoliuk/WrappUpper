//
//  InterruptableAudioEngine.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import UIKit
import AVFoundation

final class InterruptableAudioEngine: AudioEngine {

    weak var delegate: AudioEngineDelegate?

    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }

    fileprivate var recorder: AudioRecorder?
    fileprivate var player: AVAudioPlayer?

    init() {
        subsribeForNotifications()
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
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
//            try AVAudioSession.sharedInstance().setActive(true)

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

// MARK: - Notifications

private extension InterruptableAudioEngine {

    func subsribeForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(audioSessionInterruption(_:)), name: Notification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        notificationCenter.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(aplicationDidEnterBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    @objc func audioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let interruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? Int else { return }
        print("interruptionType: \(interruptionType)")
        //        if interruptionType == .began {
        //
        //        }
        print(#function)
    }

    @objc func applicationWillEnterForeground(_ notification: Notification) {
        print(#function)
    }

    @objc func aplicationDidEnterBackground(_ notification: Notification) {
        print(#function)
    }

    @objc func applicationWillResignActive(_ notification: Notification) {
        print(#function)
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        print(#function)
        do {
            try AVAudioSession.sharedInstance().setActive(true)
//            recorder?.record()
        } catch {
            let message = "Failed activate AVAudioSession. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
    }

}
