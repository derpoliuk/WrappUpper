//
//  InterruptableAudioRecorder.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation
import AVFoundation

extension String: Error {}

final class InterruptableAudioRecorder: NSObject, AudioRecorder {

    let url: URL
    var isRecording: Bool = false

    fileprivate var recorder: AVAudioRecorder?
    fileprivate var tempFileURLs = [URL]()

    init(url: URL) {
        print("url: \(url)")
        self.url = url
    }

    func record() throws {
//        try recordToTempFile()

        try setupCaptureSession()
        try setupWriterInput()
        isRecording = true
        captureSession.startRunning()
    }

    func stop() throws {
        captureSession.stopRunning()
        assetWriter.finishWriting {
            print("finished writing")
        }
//        try stopRecording()
    }

    func pause(interruption: AudioEngineInterruption) {
        print("InterruptableAudioRecorder.pause")
        pauseRecording()
        if interruption == .call {

        }
    }

    var captureSession: AVCaptureSession!
    var dataOutput: AVCaptureAudioDataOutput!
    var writerInput: AVAssetWriterInput!
    var assetWriter: AVAssetWriter!

    func setupWriterInput() throws {
        var channelLayout = AudioChannelLayout()
        let size = MemoryLayout<AudioChannelLayout>.size
        memset(&channelLayout, 0, size)
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        let channelLayoutData = NSData(bytes: &channelLayout, length: size)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVNumberOfChannelsKey: 2,
            AVChannelLayoutKey: channelLayoutData
        ]

        let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: settings)
        writerInput.expectsMediaDataInRealTime = true

        let assetWriter = try AVAssetWriter(outputURL: url, fileType: AVFileTypeWAVE)
        guard assetWriter.canAdd(writerInput) else {
            throw "Can't add writer input to asset writer"
        }
        assetWriter.add(writerInput)
        self.writerInput = writerInput
        self.assetWriter = assetWriter
    }

    func setupCaptureSession() throws {
        let audioCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)

        let captureSession = AVCaptureSession()

        guard captureSession.canAddInput(audioInput) else {
            throw "Can't add audio input to capture session"
        }
        captureSession.addInput(audioInput)

        let dataOutput = AVCaptureAudioDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        guard captureSession.canAddOutput(dataOutput) else {
            throw "Can't add data output to capture session"
        }
        captureSession.addOutput(dataOutput)

        self.dataOutput = dataOutput
        self.captureSession = captureSession
    }

}

extension InterruptableAudioRecorder: AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if !CMSampleBufferDataIsReady(sampleBuffer) {
            print("Sample buffer is not ready. Skipping.")
        }
        guard isRecording else { return }

        let lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if assetWriter.status != .writing {
            if !assetWriter.startWriting() {
                print("asset writer can not start writing")
            }
            assetWriter.startSession(atSourceTime: lastSampleTime)
        }

        if !writerInput.append(sampleBuffer) {
            print("failed append sample buffer")
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
//        let recorder = try AVAudioRecorder(url: tempURL, format: audioFormat)
//        recorder.record()
//        self.recorder = recorder
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
