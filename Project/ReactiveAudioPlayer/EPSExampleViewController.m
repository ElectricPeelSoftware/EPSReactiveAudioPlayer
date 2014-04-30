//
//  EPSViewController.m
//  ReactiveAudioPlayer
//
//  Created by Peter Stuart on 4/24/14.
//  Copyright (c) 2014 Electric Peel, LLC. All rights reserved.
//

#import "EPSExampleViewController.h"

#import "EPSPlayerViewModel.h"

@interface EPSExampleViewController ()

@property (weak, nonatomic) IBOutlet UILabel *timeElapsedLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;

@property (nonatomic) EPSPlayerViewModel *viewModel;

@end

@implementation EPSExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewModel = [EPSPlayerViewModel new];
    
    self.viewModel.audioURL = [NSURL URLWithString:AUDIO_URL];
    
    self.toggleButton.rac_command = self.viewModel.togglePlayPauseCommand;
    
    RAC(self.timeElapsedLabel, text) = RACObserve(self.viewModel, elapsedTimeString);
    RAC(self.timeRemainingLabel, text) = RACObserve(self.viewModel, remainingTimeString);
    RAC(self.timeSlider, maximumValue) = RACObserve(self.viewModel, duration);
    
    RACSignal *seeking = [RACSignal merge:@[ [[self.timeSlider rac_signalForControlEvents:UIControlEventTouchDown] mapReplace:@YES],
                                             [[self.timeSlider rac_signalForControlEvents:UIControlEventTouchUpInside] mapReplace:@NO],
                                             [[self.timeSlider rac_signalForControlEvents:UIControlEventTouchUpOutside] mapReplace:@NO] ]];
    RAC(self.viewModel, seeking) = seeking;
    
    RACSignal *timeSignalWhenNotSeeking = [[[RACSignal
        combineLatest:@[ RACObserve(self.viewModel, currentTime), RACObserve(self.viewModel, seeking) ]]
        filter:^BOOL(RACTuple *tuple) {
            NSNumber *seeking = tuple.second;
            return seeking.boolValue == NO;
        }]
        reduceEach:^NSNumber *(NSNumber *currentTime, NSNumber *seeking){
            return currentTime;
        }];
    
    [self.timeSlider rac_liftSelector:@selector(setValue:animated:) withSignals:timeSignalWhenNotSeeking, [RACSignal return:NO], nil];
    
    RACSignal *sliderSignalWhenSeeking = [[[RACSignal
        combineLatest:@[ [self.timeSlider rac_signalForControlEvents:UIControlEventValueChanged], RACObserve(self.viewModel, seeking) ]]
        filter:^BOOL(RACTuple *tuple) {
            NSNumber *seeking = tuple.second;
            return seeking.boolValue == YES;
        }]
        reduceEach:^NSNumber *(UISlider *slider, NSNumber *seeking){
            return @(slider.value);
        }];
    
    [self.viewModel rac_liftSelector:@selector(seekToTime:) withSignals:sliderSignalWhenSeeking, nil];
    
    RACSignal *buttonTitleSignal = [RACObserve(self.viewModel, playing)
        map:^NSString *(NSNumber *playing) {
            if (playing.boolValue == YES) {
                return @"Pause";
            }
            else {
                return @"Play";
            }
        }];
    [self.toggleButton rac_liftSelector:@selector(setTitle:forState:) withSignals:buttonTitleSignal, [RACSignal return:@(UIControlStateNormal)], nil];
}

@end
