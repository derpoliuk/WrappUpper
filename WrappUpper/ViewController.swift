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
    private let audioEngine = InterruptableAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine.delegate = self
    }

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

    private func startRecording() {
        audioEngine.record()
    }

    private func stopRecording() {
        audioEngine.stop()
    }

}

// MARK: - AudioEngineDelegate

extension ViewController: AudioEngineDelegate {

    func audioEngineDidPause(_ audioEngine: AudioEngine) {
        recordButton.setTitle("Resume", for: .normal)
    }

    func audioEngineDidResume(_ audioEngine: AudioEngine) {
        recordButton.setTitle("Stop", for: .normal)
    }

    func audioEngineDidStop(_ audioEngine: AudioEngine) {
        recordButton.setTitle("Record", for: .normal)
    }
    
}
