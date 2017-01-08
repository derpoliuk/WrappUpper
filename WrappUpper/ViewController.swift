//
//  ViewController.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var recording = false

    @IBAction func recordButtonPressed(_ sender: UIButton) {
        recording = !recording
        let title = recording ? "Stop" : "Record"
        sender.setTitle(title, for: .normal)
    }

}

