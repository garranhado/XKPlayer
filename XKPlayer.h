#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol XKPlayerDelegate;

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

@interface XKPlayerView: UIView

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) AVPlayerLayer *playerLayer;

- (void)restore:(AVPlayerLayer *)layer;

@end

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
