//
//  InterruptableAudioRecorder.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation
import AVFoundation

private enum RecordType {
    case file(url: URL)
    case silence(duration: TimeInterval)

    var isFile: Bool {
        if case .file(_) = self {
            return true
        } else {
            return false
        }
    }

    var url: URL? {
        if case .file(let url) = self {
            return url
        } else {
            return nil
        }
    }
}

final class InterruptableAudioRecorder {

    let url: URL
    var isRecording = false

    fileprivate var recorder: AVAudioRecorder?
    fileprivate let audioFormat: AVAudioFormat
    fileprivate var callDate: Date?
    fileprivate var records = [RecordType]()

    init(url: URL, format: AVAudioFormat) {
        self.url = url
        audioFormat = format
    }

}

// MARK: - AudioRecorder

extension InterruptableAudioRecorder: AudioRecorder {

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

    func pause(interruption: AudioEngineInterruption) {
        guard isRecording else { return }
        isRecording = false
        pauseRecording()
        if interruption == .call {
            callDate = Date()
        }
    }

}

// MARK: - Recording methods

private extension InterruptableAudioRecorder {

    func recordToTempFile() throws {
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
        pauseRecording()
        try finalizeRecordedTrack()
    }

    func finalizeRecordedTrack() throws {
        guard records.count > 0 else { return }

        if records.count == 1 {
            let record = records[0]
            if case .file(let url) = record {
                try renameToOriginalURL(url: url)
            }
        } else {
            try composeFiles()
        }
        records = []
    }

    func renameToOriginalURL(url: URL) throws {
        let fileManager = FileManager.default
        try fileManager.moveItem(at: url, to: self.url)
    }

    func composeFiles() throws {
        var data: Data?
        for record in records {
            switch record {
            case .silence(let duration):
                guard let oldData = data else { continue }
                data = WavDataConcatinator.appendSilence(withDuration: duration, toWavData: oldData)
                break
            case .file(let url):
                let newData = try Data(contentsOf: url)
                if let oldData = data {
                    data = WavDataConcatinator.concatWavData(oldData, withWavData: newData)
                } else {
                    data = newData
                }
                break
            }
        }
        guard let newData = data else { return }
        try newData.write(to: url)
    }

}
