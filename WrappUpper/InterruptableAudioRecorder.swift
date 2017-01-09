//
//  InterruptableAudioRecorder.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation
import AVFoundation

final class InterruptableAudioRecorder: AudioRecorder {

    let url: URL
    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }

    fileprivate var recorder: AVAudioRecorder?
    fileprivate var tempFileURLs = [URL]()
    fileprivate let audioFormat: AVAudioFormat

    init(url: URL, format: AVAudioFormat) {
        print("url: \(url)")
        self.url = url
        audioFormat = format
    }

    func record() throws {
        try recordToTempFile()
    }

    func stop() throws {
        try stopRecording()
    }

    func pause(interruption: AudioEngineInterruption) {
        print("InterruptableAudioRecorder.pause")
        pauseRecording()
        if interruption == .call {

        }
    }

}

// MARK: - Recording methods

private extension InterruptableAudioRecorder {

    func recordToTempFile() throws {
        print("InterruptableAudioRecorder.recordToTempFile")
        let tempFileExtension = "~\(tempFileURLs.count).temp"
        let tempURL = url.appendingPathExtension(tempFileExtension)
        tempFileURLs.append(tempURL)
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
        guard tempFileURLs.count > 0 else { return }

        if tempFileURLs.count == 1 {
            try renameToOriginalURL(url: tempFileURLs[0])
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
        let assetsDispatchGroup = DispatchGroup()
        var assets = [AVAsset]()
        for url in tempFileURLs {
            let asset = AVAsset(url: url)
            assetsDispatchGroup.enter()
            print("load tracks for asset")
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                print("finished loading tracks")
                var error: NSError? = nil
                let status = asset.statusOfValue(forKey: "tracks", error: &error)
                assetsDispatchGroup.leave()
            }
            assets.append(asset)
        }

        assetsDispatchGroup.wait()

        let mutableComposition = AVMutableComposition()
        let mutableTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)

        var time = CMTime()
        for asset in assets {
            let timeRanges = asset.tracks.map { NSValue(timeRange:$0.timeRange) }
            try mutableTrack.insertTimeRanges(timeRanges, of: asset.tracks, at: time)
            time = CMTimeAdd(time, asset.duration)
        }

        guard let exportSession = AVAssetExportSession(asset: mutableComposition, presetName: AVAssetExportPresetAppleM4A) else {
            // TODO: complete error
            let error = NSError(domain: "1", code: 1, userInfo: nil)
            throw error
        }
        exportSession.outputURL = url
        exportSession.outputFileType = AVFileTypeAppleM4A
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var success = false
        exportSession.exportAsynchronously {
            success = exportSession.error == nil
            dispatchGroup.leave()
        }
        print("exportSession.error: \(exportSession.error)")
        dispatchGroup.wait()

        if !success {
            // TODO: finish error
            let error = NSError(domain: "", code: 1, userInfo: nil)
            throw error
        }

    }

}
