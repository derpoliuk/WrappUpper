//
//  AudioEngineFileURLGenerator.swift
//  WrappUpper
//
//  Created by derp on 1/8/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation

final class AudioEngineFileURLGenerator {

    static func generateAudioFileURL() -> URL {
        return documentsURL.appendingPathComponent(generateFileName()).appendingPathExtension(fileExtension)
    }

    private static var fileExtension = "wav"
    private static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return dateFormatter
    }()

    private static var documentsURL: URL = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: documentsPath)
    }()

    private static func generateFileName() -> String {
        return dateFormatter.string(from: Date())
    }
    
}
