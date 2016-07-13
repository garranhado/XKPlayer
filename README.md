# XKPlayer
Clean and full feature AVPlayer extension.

##Objects

###XKPlayer

```Objective-C
@interface XKPlayer: AVPlayer

- (instancetype)initWithURL:(NSURL *)url
                       time:(BOOL)time
                   delegate:(id<XKPlayerDelegate>)delegate;

- (instancetype)initWithURLForSnapshot:(NSURL *)url
                              delegate:(id<XKPlayerDelegate>)delegate;

- (double)secondsFromTime:(CMTime)time;
- (CMTime)timeFromSeconds:(double)seconds;

- (UIImage *)takeSnapshot;

@end
```

###XKPlayerView

```Objective-C
@interface XKPlayerView: UIView

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) AVPlayerLayer *playerLayer;

- (void)restore:(AVPlayerLayer *)layer;

@end
```

###XKPlayerDelegate

```Objective-C
@protocol XKPlayerDelegate <NSObject>

- (void)buffering:(XKPlayer *)player;
- (void)ready:(XKPlayer *)player;
- (void)failed:(XKPlayer *)player;

- (void)playing:(XKPlayer *)player;
- (void)paused:(XKPlayer *)player;
- (void)ended:(XKPlayer *)player;

- (void)externalPlaybackChanged:(XKPlayer *)player;

- (void)timer:(XKPlayer *)player
      current:(double)current
     duration:(double)duration;

@end
```

##How to use

```Objective-C
// Use as a normal view, with autolayout (or not)

// Interface builder
@property (nonatomic, weak) IBOutlet XKPlayerView *playerView;

// Code (self.codePlayerView = [[XKPlayerView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)])
@property (nonatomic) XKPlayerView *codePlayerView;

// Picture-in-Picture (optional)
@property (nonatomic) AVPictureInPictureController *pipController;

// Snapshots player
@property (nonatomic) XKPlayer *snapshotPlayer;
```

```Objective-C
// For play

- (void)playURL:(NSURL *)url {

    self.playerView.player = [[XKPlayer alloc] initWithURL:url
                                                      time:YES // or NO (optionl)
                                                  delegate:self];
    [self.playerView.player play];
    
    // Setup Picture-in-Picture (optional)
    
    if ([AVPictureInPictureController isPictureInPictureSupported]) {
        self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.playerView.playerLayer];
        self.pipController.delegate = self;
    }
}

// For snapshot (local and live streaming)

- (void)setupPlayerForSnapshot:(NSURL *)url {
    self.snapshotPlayer = [[XKPlayer alloc] initWithURLForSnapshot:url
                                                          delegate:self];
}
```

```Objective-C
// Delegate, all methods required (but some can do nothing)

- (void)buffering:(XKPlayer *)player {
    // loading or start buffering
    
    // e.g. [self.activityIndicator startActivity];
}

- (void)ready:(XKPlayer *)player {
    // end buffering and ready to play (or to take a snapshot)
    
    // e.g. [self.activityIndicator stopActivity];
    // e.g. UIImage *image = [player takeSnapshot];
}

- (void)failed:(XKPlayer *)player {
    // when player failed to play url
    // e.g. show an error
}

- (void)playing:(XKPlayer *)player {
    // player changed to play state
    
    // e.g. [self updatePlaybackControls:YES];
}

- (void)paused:(XKPlayer *)player {
    // player changed to paused state
    
    // e.g. [self updatePlaybackControls:NO];
}

- (void)ended:(XKPlayer *)player {
    // player has played to its end time
    
    // e.g. dismiss player view controller
    // e.g. show other options
}

- (void)externalPlaybackChanged:(XKPlayer *)player {
    // airplay enabled or disabled
    
    // e.g. if (player.externalPlaybackActive) {} else {}
}

- (void)timer:(XKPlayer *)player
      current:(double)current
     duration:(double)duration {
    // player tick
    
    // e.g. self.timerLabel.text = [self formattedTimer:current duration:duration];
    // e.g. self.progressView.value = current / duration;
}
```
