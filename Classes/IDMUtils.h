//
//  IDMUtils.h
//  PhotoBrowserDemo
//
//  Created by Oliver ONeill on 2/12/17.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IDMUtils : NSObject

+ (CGRect)adjustRect:(CGRect)rect forSafeAreaInsets:(UIEdgeInsets)insets forBounds:(CGRect)bounds adjustForStatusBar:(BOOL)adjust statusBarHeight:(int)statusBarHeight;

/// Returns an `AVPlayer` for the given video URL. For `file://` URLs (e.g. Photo Library), uses
/// `AVURLAsset` + `AVPlayerItem` instead of `+[AVPlayer playerWithURL:]`, which can fail for some
/// local paths on newer iOS. Non-file URLs use `+[AVPlayer playerWithURL:]`.
+ (nullable AVPlayer *)playerForVideoURL:(nullable NSURL *)url;

@end

NS_ASSUME_NONNULL_END
