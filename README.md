# WrappUpper

Test project. 

### Original task:

1. Record an audio file by streaming the byte data; The byte data for the audio file can be obtained by directly accessing what the mic outputs and use that to create a .wav file

	1. The outcome is to create a single audio file with the following specs:.wav with 16K sampling rate, PCM Le 16

2. In case of a call interruption during the recording,the app should pad the duration of recording which is taken by call with zeroes. Once the recording resumes, it should start writing the byte data to the file again.
3. Test that the audio file is created correctly, use any programming language to read the audio file and ensure no chunks are skipped because the compiler can't understand it.
4. Optional: Create a wave visualization during the recording based on mic input (sample visual is in the next page)

### Dev notes

Project is half-ready: I didn't test audio creating and didn't implement sound wave visualization.

Total time I took is around 10 hours. Here's how I built this project with approx timeline and my reasoning.

At first I had multiple levels of abstraction:

* AVKit - I didn't use it because it's too high level of abstraction (view-level)
* AVFoundation:
    * AVAudioRecorder
    * AVCaptureSession and AVAssertWriter

• AudioToolbox

So I decided to go with highest level that is available for me - AVAudioRecorder.

First ~5 hours I was reading about AVFoundation, looking at my old code, reading docs and SO questions and experimenting with AVAudioRecorder.

I really liked how easy it is to use AVAudioRecorder, pause/resume it to handle call and other interruptions. However I faced problem - while I could save audio files as "wav", I could not add silence to tracks nor concatenate multiple wav files together. I tried using AVAssetExportSession, but it didn't work with "wav". Nor it was good performance choice - I would need to store all tracks and then read them again.

On the next day I decided to go 1 level deeper - AVCaptureSession + AVAssetWriter.  I did implement writing (you can see it on branch avcapturesession), but I faced same multiple problems:

1. I need to write more code to handle interruptions, pausing and resuming session
2. Again, I could not concatenate multiple files or add silence

I a lot of time already so I decided make it "fast and dirty" - go back to AVAudiRecorder and edit "raw" wav files. This saved me from overhead with interruptions and pausing record. And the downside - no easy way to get data to visualize sound wave.

I understand that it is not the best option, but my goal was working solution, even not the best one. Hopefully it will give you an overview how I write code.

One more comment about git commits. I was experimenting a lot, so I didn't make them as small as possible. I make them small enough to jump back and forth in history and not lose my sanity while doing that :)

One more thing: WavDataConcatinator is in Objective-C. I decided to leave it this way because I copied most of it from SO (link is in .m file).