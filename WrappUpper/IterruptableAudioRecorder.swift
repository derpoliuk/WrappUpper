//
//  IterruptableAudioRecorder.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation
import AVFoundation

final class IterruptableAudioRecorder: AudioRecorder {

    private let recorder: AVAudioRecorder

    var url: URL {
        return recorder.url
    }

    var isRecording: Bool {
        return recorder.isRecording
    }

    init(url: URL, format: AVAudioFormat) throws {
        recorder = try AVAudioRecorder(url: url, format: format)
    }

    func record() {
        recorder.record()
    }

    func stop() {
        recorder.stop()
    }

    func pause(interruption: AudioEngineInterruption) {
        recorder.pause()
    }
}
