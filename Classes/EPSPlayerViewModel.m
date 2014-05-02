//
//  EPSPlayerViewModel.m
//  ReactiveAudioPlayer
//
//  Created by Peter Stuart on 4/24/14.
//  Copyright (c) 2014 Electric Peel, LLC. All rights reserved.
//

#import "EPSPlayerViewModel.h"

#import "AVPlayer+RAC.h"
#import <MediaPlayer/MediaPlayer.h>
#import <ReactiveCocoa/RACEXTScope.h>

@interface EPSPlayerViewModel ()

@property (nonatomic) RACCommand *playCommand;
@property (nonatomic) RACCommand *pauseCommand;
@property (nonatomic) RACCommand *togglePlayPauseCommand;

@property (nonatomic) AVPlayer *player;

@end

@implementation EPSPlayerViewModel

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    NSError *setCategoryError = nil;
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    RAC(self, player) = [RACObserve(self, audioURL)
        map:^AVPlayer *(NSURL *audioURL) {
            if (audioURL == nil) {
                return nil;
            }
            else {
                return [[AVPlayer alloc] initWithURL:audioURL];
            }
        }];
    
    RAC(self, duration) = [[RACObserve(self, player)
        map:^RACSignal *(AVPlayer *player) {
            if (player == nil) {
                return [RACSignal return:@0];
            }
            else {
                return player.rac_duration;
            }
        }]
        switchToLatest];
    
    RAC(self, currentTime) = [[RACObserve(self, player)
        map:^RACSignal *(AVPlayer *player) {
            return [player rac_currentTimeWithObservationInterval:1];
        }]
        switchToLatest];
    
    RAC(self, elapsedTimeString) = [RACObserve(self, currentTime)
        map:^NSString *(NSNumber *time) {
            return [EPSPlayerViewModel timeAsString:time.doubleValue];
        }];
    
    RAC(self, remainingTimeString) = [RACSignal
        combineLatest:@[ RACObserve(self, currentTime), RACObserve(self, duration) ]
        reduce:^NSString *(NSNumber *time, NSNumber *duration){
            NSTimeInterval remainingTime = duration.doubleValue - time.doubleValue;
            return [EPSPlayerViewModel timeAsString:remainingTime];
        }];
    
    RAC(self, playing) = [RACObserve(self, player.rate)
        map:^NSNumber *(NSNumber *rate) {
            return @(rate.doubleValue > 0);
        }];
    
    RACSignal *artworkSignal = [RACObserve(self, audioArtwork) map:^MPMediaItemArtwork *(UIImage *image) {
        if (image == nil) return nil;
        
        return [[MPMediaItemArtwork alloc] initWithImage:image];
    }];
    
    NSArray *nowPlayingSignals = @[ RACObserve(self, audioTitle),
                                    RACObserve(self, audioArtist),
                                    RACObserve(self, audioAlbumTitle),
                                    artworkSignal,
                                    RACObserve(self, currentTime),
                                    RACObserve(self, duration) ];
                                    
    RAC([MPNowPlayingInfoCenter defaultCenter], nowPlayingInfo) = [[RACSignal
        combineLatest:nowPlayingSignals
        reduce:^NSDictionary *(NSString *title, NSString *artist, NSString *albumTitle, MPMediaItemArtwork *artwork, NSNumber *currentTime, NSNumber *duration){
            NSMutableDictionary *dictionary = [NSMutableDictionary new];
            
            if (title) dictionary[MPMediaItemPropertyTitle] = title;
            if (artist) dictionary[MPMediaItemPropertyArtist] = artist;
            if (albumTitle) dictionary[MPMediaItemPropertyAlbumTitle] = albumTitle;
            if (artwork) dictionary[MPMediaItemPropertyArtwork] = artwork;
            if (currentTime) dictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime;
            if (duration) dictionary[MPMediaItemPropertyPlaybackDuration] = duration;
            
            return dictionary;
        }] logAll];
    
    @weakify(self);
    
    RACSignal *seekingBegins = [[RACObserve(self, seeking)
        distinctUntilChanged]
        filter:^BOOL(NSNumber *seeking) {
            return seeking.boolValue == YES;
        }];
    
    RACSignal *seekingEnds = [[RACObserve(self, seeking)
        distinctUntilChanged]
        filter:^BOOL(NSNumber *seeking) {
            return seeking.boolValue == NO;
        }];
    
    [seekingBegins subscribeNext:^(id x) {
        @strongify(self);
        
        [self.pauseCommand execute:nil];
    }];
    
    [[[RACObserve(self, playing)
        sample:seekingBegins]
        sample:seekingEnds]
        subscribeNext:^(NSNumber *playing) {
            @strongify(self);
            
            if (playing.boolValue == YES) {
                [self.playCommand execute:nil];
            }
        }];
    
    RACSignal *readyToPlaySignal = [RACObserve(self.player, status)
        map:^NSNumber *(NSNumber *statusNumber) {
            AVPlayerStatus status = statusNumber.integerValue;
            return @(status == AVPlayerStatusReadyToPlay);
        }];
    
    self.playCommand = [[RACCommand alloc] initWithEnabled:readyToPlaySignal signalBlock:^RACSignal *(id input) {
        @strongify(self);
        
        [self.player play];
        
        return [RACSignal empty];
    }];
    
    self.pauseCommand = [[RACCommand alloc] initWithEnabled:readyToPlaySignal signalBlock:^RACSignal *(id input) {
        @strongify(self);
        
        [self.player pause];
        
        return [RACSignal empty];
    }];
    
    RACSignal *toggleEnabled = [RACSignal merge:@[ self.playCommand.enabled, self.pauseCommand.enabled ]];
    
    self.togglePlayPauseCommand = [[RACCommand alloc] initWithEnabled:toggleEnabled signalBlock:^RACSignal *(id input) {
        @strongify(self);
        
        if (self.player.rate > 0) {
            [self.player pause];
        }
        else {
            [self.player play];
        }
        
        return [RACSignal empty];
    }];
    
    return self;
}

- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMake(time, 1)];
}

+ (NSString *)timeAsString:(NSTimeInterval)timeInterval {
    if (timeInterval <= 0) return @"0:00";
    
    NSInteger totalSeconds = timeInterval;
    NSInteger minutes = floor(totalSeconds / 60);
    NSInteger seconds = round(totalSeconds - minutes * 60);

    NSString *secondsString;
    if (seconds < 10) {
        secondsString = [NSString stringWithFormat:@"0%d", seconds];
    }
    else {
        secondsString = [NSString stringWithFormat:@"%d", seconds];
    }
    
    return [NSString stringWithFormat:@"%d:%@", minutes, secondsString];
}

#pragma mark - UIResponder Methods

- (void)handleRemoteControlEvent:(UIEvent *)event {
    if (event.type != UIEventTypeRemoteControl) return;
    
    if (event.subtype == UIEventSubtypeRemoteControlPlay) {
        [self.playCommand execute:nil];
    }
    else if (event.subtype == UIEventSubtypeRemoteControlPause) {
        [self.pauseCommand execute:nil];
    }
}

@end
