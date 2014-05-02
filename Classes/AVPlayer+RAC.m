//
//  AVPlayer+RAC.m
//  ReactiveAudioPlayer
//
//  Created by Peter Stuart on 4/24/14.
//  Copyright (c) 2014 Electric Peel, LLC. All rights reserved.
//

#import "AVPlayer+RAC.h"

#import <ReactiveCocoa/RACEXTScope.h>

@implementation AVPlayer (RAC)

- (RACSignal *)rac_duration {
    return [[RACObserve(self, currentItem.asset.duration)
        map:^NSNumber *(NSValue *durationValue) {
            CMTime time = durationValue.CMTimeValue;
            return[AVPlayer rac_timeIntervalFromTime:time];
        }]
        map:^NSNumber *(NSNumber *duration) {
            if (duration == nil) return @0;
            else return duration;
        }];
}

- (RACSignal *)rac_currentTimeWithObservationInterval:(NSTimeInterval)timeInterval {
    @weakify(self);
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        id observer = [self addPeriodicTimeObserverForInterval:CMTimeMake(timeInterval, 1) queue:NULL usingBlock:^(CMTime time) {
            NSNumber *number = [AVPlayer rac_timeIntervalFromTime:time];
            [subscriber sendNext:number];
        }];
        
        return [RACDisposable disposableWithBlock:^{
            [self removeTimeObserver:observer];
        }];
    }];
}

+ (NSNumber *)rac_timeIntervalFromTime:(CMTime)time {
    if (CMTIME_IS_VALID(time)) {
        return @(CMTimeGetSeconds(time));
    }
    else {
        return nil;
    }
}

@end
