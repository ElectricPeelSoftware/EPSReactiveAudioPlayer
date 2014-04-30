//
//  AVPlayer+RAC.h
//  ReactiveAudioPlayer
//
//  Created by Peter Stuart on 4/24/14.
//  Copyright (c) 2014 Electric Peel, LLC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface AVPlayer (RAC)

- (RACSignal *)rac_duration;
- (RACSignal *)rac_currentTimeWithObservationInterval:(NSTimeInterval)timeInterval;

@end
