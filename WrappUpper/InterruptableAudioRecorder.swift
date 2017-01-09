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
    var isRecording = false

    init(url: URL) {
        print("url: \(url)")
        self.url = url
    }

    func record() throws {
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
    }

    func pause(interruption: AudioEngineInterruption) {
        print("InterruptableAudioRecorder.pause")

        captureSession.stopRunning()

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
