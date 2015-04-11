//
//  DZImageCache.h
//  TimeUI
//
//  Created by Stone Dong on 13-12-15.
//  Copyright (c) 2013年 Stone Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define DZImageShareCache [DZImageCache shareCache]

#define DZCachedImageByName(name) [DZImageShareCache cachedImageForName:(name)]
#define DZCachedImageByPath(path) [DZImageShareCache cachedImageFroPath:(path)]


typedef enum {
    DZImageCacheSourceDefault,
    DZImageCacheSourceDirectory,
    DZImageCacheSourceAssets
}DZImageCacheSource;
typedef void(^GetImageBlock)(UIImage*image);

@interface DZImageCache : NSObject
@property (nonatomic, assign, readonly) DZImageCacheSource sourceType;
@property (nonatomic, strong) NSString* imagesDirectory;
+ (DZImageCache*) shareCache;
//
- (void) setupDefaultSourceType;
- (void) setupDirectorySourceTypeWithPath:(NSString*)directory;
- (void) setupAssetsSourceType;
//
- (UIImage*) cachedImageForName:(NSString*)name;
- (UIImage*) cachedImageForName:(NSString *)name inBundle:(NSBundle*)bundle;
- (UIImage*) cachedImageFroPath:(NSString*)path;
- (void) cachedImageForServerURL:(NSString*)url
            placeHolderImageName:(NSString*)name
                      downloaded:(GetImageBlock)block;
- (void) cachedImageUsingDefaultPlaceHolderForServerURL:(NSString *)url
                                             downloaded:(GetImageBlock)block;
@end

