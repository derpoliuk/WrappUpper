//
//  Sample.m
//  WrappUpper
//
//  Created by derp on 1/9/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Sample: NSObject  <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureAudioDataOutput *_audioOutput;
    AVCaptureSession *_capSession;
    AVAssetWriter *_videoWriter;
    AVAssetWriterInput *_videoWriterInput;
    AVAssetWriterInput *_audioWriterInput;
    BOOL _isRecording;
    CMTime lastSampleTime;
    NSURL *videoURL;
}

@end

@implementation Sample

- (void) some {
    NSError *error = nil;

    // Setup the video input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    // Setup the video output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.alwaysDiscardsLateVideoFrames = NO;
    _videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];

    // Setup the audio input
    AVCaptureDevice *audioDevice     = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error ];
    // Setup the audio output
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];

    // Create the session
    _capSession = [[AVCaptureSession alloc] init];
    [_capSession addInput:videoInput];
    [_capSession addInput:audioInput];
    [_capSession addOutput:_videoOutput];
    [_capSession addOutput:_audioOutput];

    _capSession.sessionPreset = AVCaptureSessionPresetLow;

    // Setup the queue
    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [_videoOutput setSampleBufferDelegate:self queue:queue];
    [_audioOutput setSampleBufferDelegate:self queue:queue];
//    dispatch_release(queue);
}

// Setting up AVAssetWriter and associating both audio and video AVAssetWriterInputs to it:

- (BOOL)setupWriter {
    NSError *error = nil;
    _videoWriter = [[AVAssetWriter alloc] initWithURL:videoURL
                                             fileType:AVFileTypeQuickTimeMovie
                                                error:&error];
    NSParameterAssert(_videoWriter);


    // Add video input
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:128.0*1024.0], AVVideoAverageBitRateKey,
                                           nil ];

    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:192], AVVideoWidthKey,
                                   [NSNumber numberWithInt:144], AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];

    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                           outputSettings:videoSettings];


    NSParameterAssert(_videoWriterInput);
    _videoWriterInput.expectsMediaDataInRealTime = YES;


    // Add the audio input
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;


    NSDictionary* audioOutputSettings = nil;
    // Both type of audio inputs causes output video file to be corrupted.
    if (/* DISABLES CODE */ (NO)) {
        // should work from iphone 3GS on and from ipod 3rd generation
        audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                               [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                               [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                               [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                               [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                               [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                               nil];
    } else {
        // should work on any device requires more space
        audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                               [ NSNumber numberWithInt: kAudioFormatAppleLossless ], AVFormatIDKey,
                               [ NSNumber numberWithInt: 16 ], AVEncoderBitDepthHintKey,
                               [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                               [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                               [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                               nil ];
    }

    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType: AVMediaTypeAudio
                                                           outputSettings: audioOutputSettings ];

    _audioWriterInput.expectsMediaDataInRealTime = YES;

    // add input
    [_videoWriter addInput:_videoWriterInput];
    [_videoWriter addInput:_audioWriterInput];

    return YES;
}


// here are functions to start/stop video recording

- (void)startVideoRecording
{
    if (!_isRecording) {
        NSLog(@"start video recording...");
        if (![self setupWriter]) {
            return;
        }
        [_capSession startRunning];
        _isRecording = YES;
    }
}

- (void)stopVideoRecording
{
    if (_isRecording) {
        _isRecording = NO;
        [_capSession stopRunning];
        [_videoWriter finishWriting];
        NSLog(@"video recording stopped");
    }
}

// And finally the CaptureOutput code

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }


    if (_isRecording == YES) {
        lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (_videoWriter.status != AVAssetWriterStatusWriting ) {
            [_videoWriter startWriting];
            [_videoWriter startSessionAtSourceTime:lastSampleTime];
        }

        if (captureOutput == _videoOutput) {
            [self newVideoSample:sampleBuffer];
        } else if (captureOutput == _audioOutput) {
            [self newAudioSample:sampleBuffer];
        }
    }
}

- (void)newVideoSample:(CMSampleBufferRef)sampleBuffer
{
    if (_isRecording) {
        if (_videoWriter.status > AVAssetWriterStatusWriting) {
            NSLog(@"Warning: writer status is %ld", (long)_videoWriter.status);
            if (_videoWriter.status == AVAssetWriterStatusFailed)
                NSLog(@"Error: %@", _videoWriter.error);
            return;
        }

        if (![_videoWriterInput appendSampleBuffer:sampleBuffer]) {
            NSLog(@"Unable to write to video input");
        }
    }
}



- (void)newAudioSample:(CMSampleBufferRef)sampleBuffer
{
    if (_isRecording) {
        if (_videoWriter.status > AVAssetWriterStatusWriting) {
            NSLog(@"Warning: writer status is %ld", (long)_videoWriter.status);
            if (_videoWriter.status == AVAssetWriterStatusFailed)
                NSLog(@"Error: %@", _videoWriter.error);
            return;
        }

        if (![_audioWriterInput appendSampleBuffer:sampleBuffer]) {
            NSLog(@"Unable to write to audio input");
        }
    }
}

@end
