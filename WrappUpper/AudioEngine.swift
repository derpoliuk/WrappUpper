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
    func record() throws
    func stop() throws
}

enum AudioEngineInterruption {
    case call, `default`
}

protocol AudioRecorder {
    init(url: URL, format: AVAudioFormat)
    var url: URL { get }
    var isRecording: Bool { get }
    func record() throws
    func stop() throws
    func pause(interruption: AudioEngineInterruption) throws
}
