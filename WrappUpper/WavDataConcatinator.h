//
//  WavDataConcatinator.h
//  WrappUpper
//
//  Created by derp on 1/9/17.
//  Copyright © 2017 Stanislav Derpoliuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WavDataConcatinator : NSObject

+ (NSData *)concatWavData:(NSData *)data1 withWavData:(NSData *)data2;

@end
