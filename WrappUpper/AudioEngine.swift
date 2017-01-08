//
//  AudioEngine.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioEngineDelegate: class {
    func audioEngineDidPause(_ audioEngine: AudioEngine)
    func audioEngineDidResume(_ audioEngine: AudioEngine)
    func audioEngineDidStop(_ audioEngine: AudioEngine)
}

protocol AudioEngine {
    weak var delegate: AudioEngineDelegate? { get set }
    var isRecording: Bool { get }
    func record()
    func stop()
}

enum AudioEngineInterruption {
    case Call, `default`
}

protocol AudioRecorder {
    init(url: URL, format: AVAudioFormat) throws
    var url: URL { get }
    var isRecording: Bool { get }
    func record()
    func stop()
    func pause(interruption: AudioEngineInterruption)
}
