//
//  ViewController.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var recordButton: UIButton!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    fileprivate let audioEngine = InterruptableAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine.delegate = self
    }

}

// MARK: - Actions

private extension ViewController {

    @IBAction func recordButtonPressed(_ sender: UIButton) {
        let title = !audioEngine.isRecording ? "Stop" : "Record"
        sender.setTitle(title, for: .normal)
        if !audioEngine.isRecording {
            statusLabel.text = "Recording started"
            startRecording()
        } else {
            statusLabel.text = "Recording stopped"
            stopRecording()
        }

    }

    @IBAction func playLastButtonPressed(_ sender: UIButton) {
        statusLabel.text = "Playing last"
        audioEngine.playLast()
    }

}

// MARK: - Record methods

private extension ViewController {

    func startRecording() {
        do {
            try audioEngine.record()
        } catch {
            let message = "Failed start recording. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
    }

    func stopRecording() {
        do {
            try audioEngine.stop()
        } catch {
            let message = "Failed stop recording. Reason: \(error.localizedDescription)"
            fatalError(message)
        }
    }

}

// MARK: - AudioEngineDelegate

extension ViewController: AudioEngineDelegate {

    func audioEngineDidPause(_ audioEngine: AudioEngine) {
        statusLabel.text = "Recording paused"
        recordButton.setTitle("Resume", for: .normal)
    }

    func audioEngineDidResume(_ audioEngine: AudioEngine) {
        statusLabel.text = "Recording resumed"
        recordButton.setTitle("Stop", for: .normal)
    }

    func audioEngineDidStop(_ audioEngine: AudioEngine) {
        statusLabel.text = "Recording stopped"
        recordButton.setTitle("Record", for: .normal)
    }
    
}
