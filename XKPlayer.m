#import "XKPlayer.h"

// Macros

#define XKWelf __weak typeof(self)

#define XKEqualCI(s1, s2) [s1.lowercaseString isEqualToString:s2.lowercaseString]

#define XKMainThread(execute)\
dispatch_async(dispatch_get_main_queue(), ^{\
    execute();\
});

@interface XKPlayer ()

@property (nonatomic, weak) id<XKPlayerDelegate> delegate;
@property (nonatomic) id playbackTimer;

@end

@implementation XKPlayer

- (instancetype)initWithURL:(NSURL *)url
                       time:(BOOL)time
                   delegate:(id<XKPlayerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        if (self.delegate) {
            [self.delegate buffering:self];
        }
        
        [self addObserver:self
               forKeyPath:@"externalPlaybackActive"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        [self addObserver:self
               forKeyPath:@"rate"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        
        if (time) {
            XKWelf welf = self;
            self.playbackTimer = [self addPeriodicTimeObserverForInterval:CMTimeMake(1, 4)
                                                                    queue:nil
                                                               usingBlock:^(CMTime time) {
                                                                   XKMainThread(^{
                                                                       if (welf.delegate &&
                                                                           welf.currentItem &&
                                                                           welf.currentItem.status == AVPlayerItemStatusReadyToPlay &&
                                                                           welf.currentItem.playbackLikelyToKeepUp) {
                                                                           [welf.delegate timer:welf
                                                                                        current:CMTimeGetSeconds(time)
                                                                                       duration:CMTimeGetSeconds(welf.currentItem.duration)];
                                                                       }
                                                                   });
                                                               }];
        }
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidPlayToEndTime:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];
        
        [playerItem addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:nil];
        [playerItem addObserver:self
                     forKeyPath:@"playbackLikelyToKeepUp"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:nil];
        
        [self replaceCurrentItemWithPlayerItem:playerItem];
    }
    return self;
}

- (instancetype)initWithURLForSnapshot:(NSURL *)url
                              delegate:(id<XKPlayerDelegate>)delegate;
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        if (self.delegate) {
            [self.delegate buffering:self];
        }
        
        self.muted = YES;
        self.allowsExternalPlayback = NO;
        
        [self addObserver:self
               forKeyPath:@"externalPlaybackActive"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        [self addObserver:self
               forKeyPath:@"rate"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        
        [playerItem addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:nil];
        [playerItem addObserver:self
                     forKeyPath:@"playbackLikelyToKeepUp"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:nil];
        
        AVPlayerItemVideoOutput *output = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:nil];
        output.suppressesPlayerRendering = YES;
        [playerItem addOutput:output];
        
        [self replaceCurrentItemWithPlayerItem:playerItem];
    }
    return self;
}

- (double)secondsFromTime:(CMTime)time {
    return CMTimeGetSeconds(time);
}

- (CMTime)timeFromSeconds:(double)seconds {
    CMTime t = self.currentTime;
    return CMTimeMakeWithSeconds(seconds, t.timescale);
}

- (UIImage *)takeSnapshot {
    UIImage *image = nil;
    
    @try {
        image = [self snapshot];
    } @catch (NSException *exception) {
        image = nil;
    }
    
    return image;
}

- (void)dealloc {
    if (self.playbackTimer) {
        [self removeTimeObserver:self.playbackTimer];
        self.playbackTimer = nil;
    }
    
    [self removeObserver:self
              forKeyPath:@"rate"];
    [self removeObserver:self
              forKeyPath:@"externalPlaybackActive"];
    
    if (self.currentItem) {
        [self.currentItem removeObserver:self
                              forKeyPath:@"status"];
        [self.currentItem removeObserver:self
                              forKeyPath:@"playbackLikelyToKeepUp"];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
}

- (void)itemDidPlayToEndTime:(NSNotification *)notification {
    if (notification.object == self.currentItem &&
        self.delegate) {
        [self.delegate ended:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (XKEqualCI(keyPath, @"externalPlaybackActive")) {
        XKMainThread(^{
            if (self.delegate) {
                [self.delegate externalPlaybackChanged:self];
            }
        });
    }
    else if (XKEqualCI(keyPath, @"rate")) {
        XKMainThread(^{            
            if (self.delegate &&
                self.status == AVPlayerStatusReadyToPlay) {
                if (self.rate == 0.0)
                    [self.delegate paused:self];
                else
                    [self.delegate playing:self];
            }
        });
    }
    else if (XKEqualCI(keyPath, @"status")) {
        XKMainThread(^{
            if (self.delegate &&
                self.currentItem &&
                self.currentItem.status == AVPlayerItemStatusFailed) {
                    [self.delegate failed:self];
            }
        });
    }
    else if (XKEqualCI(keyPath, @"playbackLikelyToKeepUp")) {
        XKMainThread(^{
            if (self.delegate &&
                self.currentItem) {
                if (self.currentItem.playbackLikelyToKeepUp) {
                    [self.delegate ready:self];
                } else {
                    [self.delegate buffering:self];
                }
            }
        });
    }
    else
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
}

- (UIImage *)snapshot
{
    AVPlayerItemVideoOutput *output = (AVPlayerItemVideoOutput *)self.currentItem.outputs.lastObject;
    
    if (!output) {
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer = [output copyPixelBufferForItemTime:self.currentTime
                                                   itemTimeForDisplay:nil];
    
    if (!pixelBuffer) {
        return nil;
    }
    
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:pixelBuffer];
    if (!ciImage) {
        return nil;
    }
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage
                                       fromRect:ciImage.extent];
    if (!cgImage) {
        return nil;
    }
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    if (!image) {
        return nil;
    }
    
    return image;
}


@end

@implementation XKPlayerView

- (void)dealloc
{
    if (self.playerLayer) {
        self.playerLayer.player = nil;
        [self.playerLayer removeFromSuperlayer];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.playerLayer) {
        self.playerLayer.frame = self.bounds;
    }
}

- (void)setPlayer:(AVPlayer *)player {
    if (self.playerLayer) {
        self.playerLayer.player = nil;
        [self.playerLayer removeFromSuperlayer];
    }
    
    if (!player) {
        return;
    }
    
    AVPlayerLayer *playerLayer = [[AVPlayerLayer alloc] init];
    playerLayer.frame = self.bounds;
    playerLayer.player = player;
    [self.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
}

- (AVPlayer *)player {
    if (!self.playerLayer)
        return nil;
    
    return self.playerLayer.player;
}

- (void)restore:(AVPlayerLayer *)playerLayer {
    if (!playerLayer)
        return;
    
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
    }
    
    playerLayer.frame = self.bounds;
    [self.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
}

@end