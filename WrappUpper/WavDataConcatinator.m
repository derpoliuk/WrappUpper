//
//  WavDataConcatinator.m
//  WrappUpper
//
//  Created by derp on 1/9/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

#import "WavDataConcatinator.h"

@implementation WavDataConcatinator

// Code is taken from http://stackoverflow.com/a/8677726/1226304

+ (NSData *)concatWavData:(NSData *)data1 withWavData:(NSData *)data2 {
    if ([data1 length] > 0 && [data2 length] > 0) {

        // TODO: Inject settings or use settings from header
        long totalAudioLen = 0;
        long totalDataLen = 0;
        long longSampleRate = 16000;
        int channels = 2;
        long byteRate = 16 * longSampleRate * channels / 8;

        NSUInteger wav1DataSize = [data1 length] - 44;
        NSUInteger wav2DataSize = [data2 length] - 44;
        NSData *wave1 = [NSMutableData dataWithData:[data1 subdataWithRange:NSMakeRange(44, wav1DataSize)]];
        NSData *wave2 = [NSMutableData dataWithData:[data2 subdataWithRange:NSMakeRange(44, wav2DataSize)]];

        totalAudioLen = [wave1 length] + [wave2 length];

        totalDataLen = totalAudioLen + 44;

        Byte *header = (Byte*)malloc(44);
        header[0] = 'R';  // RIFF/WAVE header
        header[1] = 'I';
        header[2] = 'F';
        header[3] = 'F';
        header[4] = (Byte) (totalDataLen & 0xff);
        header[5] = (Byte) ((totalDataLen >> 8) & 0xff);
        header[6] = (Byte) ((totalDataLen >> 16) & 0xff);
        header[7] = (Byte) ((totalDataLen >> 24) & 0xff);
        header[8] = 'W';
        header[9] = 'A';
        header[10] = 'V';
        header[11] = 'E';
        header[12] = 'f';  // 'fmt ' chunk
        header[13] = 'm';
        header[14] = 't';
        header[15] = ' ';
        header[16] = 16;  // 4 bytes: size of 'fmt ' chunk
        header[17] = 0;
        header[18] = 0;
        header[19] = 0;
        header[20] = 1;  // format = 1
        header[21] = 0;
        header[22] = (Byte) channels;
        header[23] = 0;
        header[24] = (Byte) (longSampleRate & 0xff);
        header[25] = (Byte) ((longSampleRate >> 8) & 0xff);
        header[26] = (Byte) ((longSampleRate >> 16) & 0xff);
        header[27] = (Byte) ((longSampleRate >> 24) & 0xff);
        header[28] = (Byte) (byteRate & 0xff);
        header[29] = (Byte) ((byteRate >> 8) & 0xff);
        header[30] = (Byte) ((byteRate >> 16) & 0xff);
        header[31] = (Byte) ((byteRate >> 24) & 0xff);
        header[32] = (Byte) (2 * 8 / 8);  // block align
        header[33] = 0;
        header[34] = 16;  // bits per sample
        header[35] = 0;
        header[36] = 'd';
        header[37] = 'a';
        header[38] = 't';
        header[39] = 'a';
        header[40] = (Byte) (totalAudioLen & 0xff);
        header[41] = (Byte) ((totalAudioLen >> 8) & 0xff);
        header[42] = (Byte) ((totalAudioLen >> 16) & 0xff);
        header[43] = (Byte) ((totalAudioLen >> 24) & 0xff);


        NSData *headerData = [NSData dataWithBytes:header length:44];

        //Merge the sound data of the original file with the temp file and create a new sound file with the
        //update header.
        NSMutableData *soundFileData = [NSMutableData alloc];
        [soundFileData appendData:[headerData subdataWithRange:NSMakeRange(0, 44)]];
        [soundFileData appendData:wave1];
        [soundFileData appendData:wave2];

        return [soundFileData copy];
    } else {
        return nil;
    }
}

+ (NSData *)appendSilenceWithDuration:(NSTimeInterval)duration toWavData:(NSData *)data {
    long longSampleRate = 16000;
    int channels = 2;
    long byteRate = 16 * longSampleRate * channels / 8;

    long musicLength = duration * byteRate;
    long headerLength = 44; // header will be ignored anyway
    long ength = musicLength + headerLength;

    Byte *rawBytes = (Byte *)malloc(ength);
    for (long i = 0; i < ength; i++) {
        rawBytes[i] = 0;
    }

    NSData *silence = [NSData dataWithBytes:rawBytes length:ength];

    return [self concatWavData:data withWavData:silence];
}

@end
