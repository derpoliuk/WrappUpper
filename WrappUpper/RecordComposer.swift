//
//  RecordComposer.swift
//  WrappUpper
//
//  Created by derp on 1/10/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

import Foundation

enum RecordType {
    case file(url: URL)
    case silence(duration: TimeInterval)

    var isFile: Bool {
        return url != nil
    }

    var url: URL? {
        if case .file(let url) = self {
            return url
        } else {
            return nil
        }
    }
}

struct RecordComposer {

    static func compose(records: [RecordType], toURL url: URL) throws {
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
