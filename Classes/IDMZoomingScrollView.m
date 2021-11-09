//
//  IDMZoomingScrollView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "IDMZoomingScrollView.h"
#import "IDMPhotoBrowser.h"
#import "IDMPhoto.h"
#import <SDWebImage/SDWebImage.h>

enum {
    kVideoWindowVertivalInset = 50
};

NSString *const PlayerFrameDidChangeNotification = @"PlayerFrameDidChangeNotification";

// Declare private methods of browser
@interface IDMPhotoBrowser ()
- (UIImage *)imageForPhoto:(id<IDMPhoto>)photo;
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)handleSingleTap;
@end

// Private methods and properties
@interface IDMZoomingScrollView ()
@property (nonatomic, weak) IDMPhotoBrowser *photoBrowser;
@property (nonatomic, strong) IDMTapDetectingImageView *videoFailureIndicator;
@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, assign) BOOL videoReachedEnd;
@property (nonatomic, assign) NSTimeInterval videoDuration;

- (void)handleSingleTap:(CGPoint)touchPoint;
- (void)handleDoubleTap:(CGPoint)touchPoint;
@end

@implementation IDMZoomingScrollView

@synthesize photoImageView = _photoImageView,
videoPlayerView = _videoPlayerView,
photoBrowser = _photoBrowser,
photo = _photo,
captionView = _captionView;

- (id)initWithPhotoBrowser:(IDMPhotoBrowser *)browser {
    if ((self = [super init])) {
        // Delegate
        self.photoBrowser = browser;
        
		// Tap view for background
		_tapView = [[IDMTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor clearColor];
		[self addSubview:_tapView];

        // Video
        _videoPlayerView = [[IDMTapDetectingImageView alloc] initWithFrame:self.bounds];
        _videoPlayerView.tapDelegate = self;
        _videoPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _videoPlayerView.backgroundColor = [UIColor clearColor];
        _videoPlayerView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_videoPlayerView];

        _videoFailureIndicator = [[IDMTapDetectingImageView alloc] initWithFrame:self.bounds];
        _videoFailureIndicator.tapDelegate = self;
        _videoFailureIndicator.contentMode = UIViewContentModeCenter;
        _videoFailureIndicator.backgroundColor = [UIColor clearColor];
        _videoFailureIndicator.hidden = YES;
        [self addSubview:_videoFailureIndicator];

        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.hidden = YES;
        _playButton.adjustsImageWhenHighlighted = NO;
        [_playButton setImage:[UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/icon_play"]
                     forState:UIControlStateNormal];
        [_playButton sizeToFit];
        [_playButton addTarget:self
                        action:@selector(onPlayButtonClicked:)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playButton];

        self.playerController = [[AVPlayerViewController alloc] init];
        self.playerController.view.hidden = YES;
        _playerController.videoGravity = AVLayerVideoGravityResizeAspect;
        [_videoPlayerView addSubview:_playerController.view];

		// Image view
		_photoImageView = [[IDMTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
		_photoImageView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 11.0, *)) {
            _photoImageView.accessibilityIgnoresInvertColors = YES;
        } else {
            // Fallback on earlier versions
        }
		[self addSubview:_photoImageView];
        
        //Add darg&drop in iOS 11
        if (@available(iOS 11.0, *)) {
            UIDragInteraction *drag = [[UIDragInteraction alloc] initWithDelegate: self];
            [_photoImageView addInteraction:drag];
            [_videoPlayerView addInteraction:drag];
        }
        
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenBound.size.width;
        CGFloat screenHeight = screenBound.size.height;
        
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
            screenWidth = screenBound.size.height;
            screenHeight = screenBound.size.width;
        }
        
        // Progress view
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake((screenWidth-35.)/2., (screenHeight-35.)/2, 35.0f, 35.0f)];
        [_progressView setProgress:0.0f];
        _progressView.tag = 101;
        _progressView.thicknessRatio = 0.1;
        _progressView.roundedCorners = NO;
        _progressView.trackTintColor    = browser.trackTintColor    ? self.photoBrowser.trackTintColor    : [UIColor colorWithWhite:0.2 alpha:1];
        _progressView.progressTintColor = browser.progressTintColor ? self.photoBrowser.progressTintColor : [UIColor colorWithWhite:1.0 alpha:1];
        [self addSubview:_progressView];
        
		// Setup
		self.backgroundColor = [UIColor clearColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (NSTimeInterval)currentVideoDuration {
    if (!CMTIME_IS_VALID(_playerController.player.currentItem.duration)) { return 0; }
    if (CMTIME_IS_INDEFINITE(_playerController.player.currentItem.duration)) { return 0; }
    return CMTimeGetSeconds(_playerController.player.currentItem.duration);
}

- (void)setPhoto:(id<IDMPhoto>)photo {
    _photoImageView.image = nil; // Release image
    if (_photo != photo) {
        _photo = photo;
    }
    [self displayMedia];
}

- (void)prepareForReuse {
    [_progressView setProgress:0 animated:NO];
    [_progressView setIndeterminate:NO];

    [self stopVideo];

    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
}

#pragma mark - Drag & Drop

- (NSArray<UIDragItem *> *)dragInteraction:(UIDragInteraction *)interaction itemsForBeginningSession:(id<UIDragSession>)session NS_AVAILABLE_IOS(11.0) {
    return @[[[UIDragItem alloc] initWithItemProvider:[[NSItemProvider alloc] initWithObject:_photoImageView.image]]];
}

#pragma mark - Image

// Get and display image
- (void)displayMedia {
	if (_photo) {
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
        
		self.contentSize = CGSizeMake(0, 0);

        switch (_photo.type) {
            case kMediaTypeImage:
                [self showImage];
                break;

            case kMediaTypeVideo:
                [self showVideo];
                break;
        }

		[self setNeedsLayout];
	}
}

- (void)showImage {
    UIImage *img = [_photoBrowser imageForPhoto:_photo] ?: _photo.failureIcon;
    if (img) {
        // Hide video
        _videoPlayerView.hidden = YES;
        _videoFailureIndicator.hidden = YES;
        _playButton.hidden = YES;

        // Hide ProgressView
        //_progressView.alpha = 0.0f;
        [_progressView removeFromSuperview];

        // Set image
        _photoImageView.image = img;
        _photoImageView.hidden = NO;
        _photoImageView.contentMode = UIViewContentModeScaleToFill;

        // Setup photo frame
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = img.size;

        _photoImageView.frame = photoImageViewFrame;
        self.contentSize = photoImageViewFrame.size;

        // Set zoom to minimum zoom
        [self setMaxMinZoomScalesForCurrentBounds];
    }
}

- (void)setProgress:(CGFloat)progress forPhoto:(IDMPhoto*)photo {
    IDMPhoto *p = (IDMPhoto*)self.photo;

    if ([photo.photoURL.absoluteString isEqualToString:p.photoURL.absoluteString]) {
        if (_progressView.progress < progress) {
            [_progressView setProgress:progress animated:YES];
        }
    }
}

// Image failed so just show black!
- (void)displayImageFailure {
    [_progressView removeFromSuperview];
}

#pragma mark - video

- (void)showVideo {
    _photoImageView.hidden = YES;
    _videoFailureIndicator.hidden = YES;
    _playButton.hidden = YES;
    _videoPlayerView.hidden = NO;
    [_progressView removeFromSuperview];

    if (_photo.videoURL == nil) {
        if (_photo.videoThumbnail != nil) {
            _videoPlayerView.image = _photo.videoThumbnail;
        } else if (_photo.videoThumbnailURL != nil) {
            [_videoPlayerView sd_setImageWithURL:_photo.videoThumbnailURL];
        }

        _videoFailureIndicator.hidden = NO;
        _videoFailureIndicator.image = _photo.failureIcon;
        return;
    }

    [self startVideo];
}

- (void)startVideo {
    _playerController.view.hidden = NO;
    _videoDuration = 0;
    _videoReachedEnd = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:NULL];

    AVPlayer *player = [AVPlayer playerWithURL:_photo.videoURL];
    [player addObserver:self
             forKeyPath:@"timeControlStatus"
                options:NSKeyValueObservingOptionNew
                context:nil];

    _playerController.player = player;
    [_playerController.player play];
}

- (void)stopVideo {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playerController.player removeObserver:self forKeyPath:@"timeControlStatus"];
    [_playerController.player pause];
    _playerController.player = nil;
    _playerController.view.hidden = YES;

    [_photoBrowser performSelector:@selector(handleVideoDidEndPlaying:finishedVideo:)
                        withObject:_photo
                        withObject:@(_videoReachedEnd)];

    [_playerController removeFromParentViewController];
    _videoReachedEnd = NO;
    _videoDuration = 0;
}

#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {
	// Reset
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
    
	// Bail
	if (_photoImageView.image == nil) return;
    
	// Sizes
	CGSize boundsSize = self.bounds.size;
	boundsSize.width -= 0.1;
	boundsSize.height -= 0.1;
	
    CGSize imageSize = _photoImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
	// If image is smaller than the screen then ensure we show it at
	// min scale of 1
	if (xScale > 1 && yScale > 1) {
		//minScale = 1.0;
	}
    
	// Calculate Max
	CGFloat maxScale = 4.0; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		maxScale = maxScale / [[UIScreen mainScreen] scale];
		
		if (maxScale < minScale) {
			maxScale = minScale * 2;
		}
	}

	// Calculate Max Scale Of Double Tap
	CGFloat maxDoubleTapZoomScale = 4.0 * minScale; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxDoubleTapZoomScale = maxDoubleTapZoomScale / [[UIScreen mainScreen] scale];
        
        if (maxDoubleTapZoomScale < minScale) {
            maxDoubleTapZoomScale = minScale * 2;
        }
    }
    
    // Make sure maxDoubleTapZoomScale isn't larger than maxScale
    maxDoubleTapZoomScale = MIN(maxDoubleTapZoomScale, maxScale);
    
	// Set
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
	self.zoomScale = minScale;
	self.maximumDoubleTapZoomScale = maxDoubleTapZoomScale;
    
	// Reset position
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
	[self setNeedsLayout];    
}

#pragma mark - Layout

- (void)layoutSubviews {
	// Update tap view frame
	_tapView.frame = self.bounds;
    _videoPlayerView.frame = self.bounds;

    if (self.bounds.size.width < self.bounds.size.height) {
        CGRect playerFrame = CGRectInset(_videoPlayerView.bounds, 0, kVideoWindowVertivalInset);
        if (@available(iOS 11.0, *)) {
            playerFrame = CGRectInset(playerFrame, 0, self.safeAreaInsets.bottom);
        }

        if (!CGRectEqualToRect(playerFrame, _playerController.view.frame)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayerFrameDidChangeNotification object:nil];
            _playerController.view.frame = playerFrame;
        }
    } else {
        CGRect playerFrame = self.bounds;
        if (@available(iOS 11.0, *)) {
            playerFrame = CGRectInset(playerFrame, self.safeAreaInsets.left, 0);
        }

        if (!CGRectEqualToRect(playerFrame, _playerController.view.frame)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayerFrameDidChangeNotification object:nil];
            _playerController.view.frame = playerFrame;
        }
    }

    _videoFailureIndicator.frame = _videoPlayerView.frame;
    _playButton.center = _videoPlayerView.center;

    // Super
	[super layoutSubviews];
    
    [self centerView:_photoImageView];
}

- (void)centerView:(UIView *)view {
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = view.frame;

    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }

    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }

    // Center
    if (!CGRectEqualToRect(view.frame, frameToCenter)) {
        view.frame = frameToCenter;
    }
}

#pragma mark - Observer

- (void)playerDidFinishPlaying:(NSNotification *)notification {
    [_playerController.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    _videoReachedEnd = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object != _playerController.player) { return; }

    if ([keyPath isEqualToString:@"timeControlStatus"]) {
            AVPlayerTimeControlStatus status = [change[NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerTimeControlStatusPaused:
                    [_photoBrowser performSelector:@selector(handleVideoDidPaused:)
                                        withObject:_photo];
                    break;

                case AVPlayerTimeControlStatusPlaying:
                    if (_videoDuration == 0) {
                        self.videoDuration = [self currentVideoDuration];
                    }
                    [_photoBrowser performSelector:@selector(handleVideoDidStartPlaying:duration:)
                                        withObject:_photo
                                        withObject:@(_videoDuration)];
                    break;

                default:
                    break;
            }
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    [_photoBrowser performSelector:@selector(handleSingleTap:)
                        withObject:_photo];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
	
	// Zoom
	if (self.zoomScale == self.maximumDoubleTapZoomScale) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in
		CGSize targetSize = CGSizeMake(self.frame.size.width / self.maximumDoubleTapZoomScale, self.frame.size.height / self.maximumDoubleTapZoomScale);
		CGPoint targetPoint = CGPointMake(touchPoint.x - targetSize.width / 2, touchPoint.y - targetSize.height / 2);
		
		[self zoomToRect:CGRectMake(targetPoint.x, targetPoint.y, targetSize.width, targetSize.height) animated:YES];
		
	}
	
	// Delay controls
	[_photoBrowser hideControlsAfterDelay];
}

- (void)onPlayButtonClicked:(UIButton *)sender {
    [_photoBrowser performSelector:@selector(handlePlayVideo:) withObject:_photo];
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch { 
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:view]];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:view]];
}

@end
