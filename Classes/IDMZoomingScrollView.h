//
//  IDMZoomingScrollView.h
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "IDMPhotoProtocol.h"
#import "IDMTapDetectingImageView.h"
#import "IDMTapDetectingView.h"

#import <DACircularProgress/DACircularProgressView.h>

@class IDMPhotoBrowser, IDMPhoto, IDMCaptionView;

AVF_EXPORT NSString *const PlayerFrameDidChangeNotification;

@interface IDMZoomingScrollView : UIScrollView <UIScrollViewDelegate, IDMTapDetectingImageViewDelegate, IDMTapDetectingViewDelegate, UIDragInteractionDelegate> {
	
	IDMPhotoBrowser *__weak _photoBrowser;
    id<IDMPhoto> _photo;
	
    // This view references the related caption view for simplified handling in photo browser
    IDMCaptionView *_captionView;
    
	IDMTapDetectingView *_tapView; // for background taps
    
    DACircularProgressView *_progressView;
}

@property (nonatomic, strong) IDMTapDetectingImageView *photoImageView;
@property (nonatomic, strong) IDMTapDetectingImageView *videoPlayerView;
@property (nonatomic, strong) AVPlayerViewController *playerController;
@property (nonatomic, strong) IDMCaptionView *captionView;
@property (nonatomic, strong) id<IDMPhoto> photo;
@property (nonatomic) CGFloat maximumDoubleTapZoomScale;
@property (nonatomic, readonly) BOOL oncePlayedVideoAd;

- (id)initWithPhotoBrowser:(IDMPhotoBrowser *)browser;
- (void)displayMedia;
- (void)displayImageFailure;
- (void)setProgress:(CGFloat)progress forPhoto:(IDMPhoto*)photo;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;
- (void)stopVideo;
- (void)didAddPlayerControllerToPhotoBrowser;

@end
