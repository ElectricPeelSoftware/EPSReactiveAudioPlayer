//
//  EPSPlayerViewModel.h
//  ReactiveAudioPlayer
//
//  Created by Peter Stuart on 4/24/14.
//  Copyright (c) 2014 Electric Peel, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface EPSPlayerViewModel : NSObject

@property (nonatomic) NSURL *audioURL;

@property (nonatomic) NSString *audioTitle;
@property (nonatomic) NSString *audioArtist;
@property (nonatomic) NSString *audioAlbumTitle;
@property (nonatomic) UIImage *audioArtwork;

// Read-only

@property (readonly) AVPlayer *player;

@property (readonly) NSTimeInterval duration;

@property (readonly) NSTimeInterval currentTime;

@property (readonly) NSString *elapsedTimeString;

@property (readonly) NSString *remainingTimeString;

@property (readonly, getter = isPlaying) BOOL playing;

// Commands

@property (readonly) RACCommand *playCommand;

@property (readonly) RACCommand *pauseCommand;

@property (readonly) RACCommand *togglePlayPauseCommand;

@property (nonatomic, getter = isSeeking) BOOL seeking;

- (void)seekToTime:(NSTimeInterval)time;

- (void)handleRemoteControlEvent:(UIEvent *)event;

@end
