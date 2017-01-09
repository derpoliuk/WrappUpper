//
//  InterruptableAudioRecorder.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation
import AVFoundation

enum RecordType {
    case file(url: URL)
    case silence(duration: TimeInterval)
}

final class InterruptableAudioRecorder: AudioRecorder {

    let url: URL
    var isRecording = false

    fileprivate var recorder: AVAudioRecorder?
    fileprivate let audioFormat: AVAudioFormat

    fileprivate var records = [RecordType]()

    init(url: URL, format: AVAudioFormat) {
        print("url: \(url)")
        self.url = url
        audioFormat = format
    }

    func record() throws {
        guard !isRecording else { return }
        isRecording = true

        if let date = callDate {
            let callDuration = Date().timeIntervalSince(date)
            let silenceRecord = RecordType.silence(duration: callDuration)
            records.append(silenceRecord)
            callDate = nil
        }
        try recordToTempFile()
    }

    func stop() throws {
        guard isRecording else { return }
        isRecording = false
        try stopRecording()
    }

    fileprivate var callDate: Date?

    func pause(interruption: AudioEngineInterruption) {
        guard isRecording else { return }
        isRecording = false
        print("InterruptableAudioRecorder.pause")
        pauseRecording()
        if interruption == .call {
            callDate = Date()
        }
    }

}

// MARK: - Recording methods

private extension InterruptableAudioRecorder {

    func recordToTempFile() throws {
        print("InterruptableAudioRecorder.recordToTempFile")
        let tempFileExtension = "~\(records.count).temp"
        let tempURL = url.appendingPathExtension(tempFileExtension)
        let fileRecord = RecordType.file(url: tempURL)
        records.append(fileRecord)
        let recorder = try AVAudioRecorder(url: tempURL, format: audioFormat)
        recorder.record()
        self.recorder = recorder
    }

    func pauseRecording() {
        recorder?.stop()
        recorder = nil
    }

    func stopRecording() throws {
        print("InterruptableAudioRecorder.stopRecording")
        pauseRecording()
        try finalizeRecordedTrack()
    }

    func finalizeRecordedTrack() throws {
        print(#function)
        guard records.count > 0 else { return }

        if records.count == 1 {
            let record = records[0]
            if case .file(let url) = record {
                try renameToOriginalURL(url: url)
            }
        } else {
            try composeFiles()
        }
    }

    func renameToOriginalURL(url: URL) throws {
        print(#function)
        let fileManager = FileManager.default
        try fileManager.moveItem(at: url, to: self.url)
    }

    func composeFiles() throws {
        print(#function)
        print("records: \(records)")
    }

}
