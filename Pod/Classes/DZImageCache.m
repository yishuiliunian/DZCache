//
//  DZImageCache.m
//  TimeUI
//
//  Created by Stone Dong on 13-12-15.
//  Copyright (c) 2013年 Stone Dong. All rights reserved.
//

#import "DZImageCache.h"
#import "DZMemoryCache.h"
#import "DZSingletonFactory.h"
#import "DZCDNActionManager.h"
#import "DZDevices.h"


NSString* ImageSubfixForCurrentScreen()
{
    static NSString* subfix = @"";
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat scale = [UIScreen mainScreen].scale;
        if (ABS(scale - 3) < 0.01) {
            subfix = @"@3x";
        } else if (ABS(scale - 2) < 0.01) {
            subfix = @"@2x";
        } else {
            subfix = @"";
        }
    });
    
    return subfix;
}

@implementation DZImageCache

+ (DZImageCache*) shareCache
{
    return DZSingleForClass([DZImageCache class]);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupDefaultSourceType];
    }
    return self;
}

- (void) setupAssetsSourceType
{
    _sourceType = DZImageCacheSourceAssets;
}

- (void) setupDirectorySourceTypeWithPath:(NSString *)directory
{
    _sourceType = DZImageCacheSourceDirectory;
    _imagesDirectory = directory;
}

- (void) setupDefaultSourceType
{
    _sourceType = DZImageCacheSourceDefault;
}

- (UIImage*) cachedImageForName:(NSString*)name
{
    return [self cachedImageForName:name inBundle:[NSBundle mainBundle]];
}

- (UIImage*) imageLoadFromDiretory:(NSString*)dir name:(NSString*)name bundle:(NSBundle*)bundle fileTypes:(NSArray*)fileTypes
{
    NSString* path = nil;
    
    NSString*(^ImagePathWithName)(NSString* realName) = ^(NSString* realName) {
        NSString* path;
        for (NSString* type in fileTypes) {
            if (self.imagesDirectory) {
                path = [bundle  pathForResource:realName ofType:type inDirectory:self.imagesDirectory];
            } else {
                path = [bundle pathForResource:realName ofType:type];
            }
            if (path) {
                return path;
            }
        }
        return (NSString*)nil;
    };
    
    NSString*(^ImagePathForSubfix)(NSString* name, NSString* subfix) = ^(NSString* name, NSString* subfix) {
        NSString* realName = [NSString stringWithFormat:@"%@%@",name,subfix];
        return ImagePathWithName(realName);
    };
    
    static NSMutableArray* ImageNameSubfixArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ImageNameSubfixArray = [@[@"@3x", @"@2x", @""] mutableCopy];
        NSString* imageSubfix = ImageSubfixForCurrentScreen();
        NSInteger index = NSNotFound;
        for (int i = 0; i < ImageNameSubfixArray.count; i++) {
            NSString* fix = ImageNameSubfixArray[i];
            if ([fix isEqualToString:imageSubfix]) {
                index = i;
            }
        }
        if (index != NSNotFound) {
            [ImageNameSubfixArray exchangeObjectAtIndex:index withObjectAtIndex:0];
        } else {
            [ImageNameSubfixArray insertObject:imageSubfix atIndex:0];
        }
    });
    
    for (NSString* subfix in ImageNameSubfixArray) {
        path = ImagePathForSubfix(name, subfix);
        if (path) {
            break;
        }
    }
    
    if (!path) {
        return nil;
    }
    return [UIImage imageWithContentsOfFile:path];
}
- (UIImage*) cachedImageForName:(NSString *)name inBundle:(NSBundle*)bundle
{
    if (name == nil) {
        return nil;
    }
    UIImage* image = [DZMemoryShareCache objectForKey:name];
    if (image) {
        return image;
    }
    
    NSArray* comps = [name componentsSeparatedByString:@"."];
    NSCAssert(comps.count <= 2, @"image name error %@", name);
    NSString* fileName = nil;
    
    NSMutableArray* fileTypes = [NSMutableArray new];
    if (comps.count == 1) {
        fileName = name;
        [fileTypes addObject:@"png"];
        [fileTypes addObject:@"jpg"];
        [fileTypes addObject:@"jpeg"];
    }
    else
    {
        fileName = comps[0];
        [fileTypes addObject:comps[1]];
    }
    if ([fileName hasSuffix:@"3x"]) {
        fileName = [fileName substringToIndex:fileName.length - @"3x".length];
    } else if ([fileName hasSuffix:@"2x"]) {
        fileName = [fileName substringToIndex:fileName.length - @"2x".length];
    }
    
    if (_sourceType == DZImageCacheSourceDefault) {
        image = [self imageLoadFromDiretory:nil name:fileName bundle:bundle fileTypes:fileTypes];
    } else if (_sourceType == DZImageCacheSourceDirectory) {
        image = [self imageLoadFromDiretory:self.imagesDirectory name:fileName bundle:bundle fileTypes:fileTypes];
    } else if (_sourceType == DZImageCacheSourceAssets)
    {
        image = [UIImage imageNamed:fileName];
    }
    
    if (image) {
        [DZMemoryShareCache setObject:image forKey:name];
    }
    
    return image;
}
- (UIImage*) cachedImageFroPath:(NSString*)path
{
    UIImage* image = [DZMemoryShareCache objectForKey:path];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:path];
        if (image) {
            [DZMemoryShareCache setObject:image forKey:path];
        }
    }
    return image;
}

- (void) cachedImageForServerURL:(NSString *)url
            placeHolderImageName:(NSString *)name
                      downloaded:(GetImageBlock)block
{
    UIImage* image = [DZMemoryShareCache objectForKey:url];
    if (image) {
        if (block) {
            block(image);
        }
    } else {
        [[DZCDNActionManager shareManager] downloadImage:url downloaded:^(UIImage *image, NSError *error) {
            if (!error && image) {
                if (block) {
                    block(image);
                    [DZMemoryShareCache setObject:image forKey:url];
                }
            } else {
                if (name) {
                    image = [self cachedImageForName:name];
                    if (block) {
                        block(image);
                    }
                }
            }
        }];
    }
}

- (void) cachedImageUsingDefaultPlaceHolderForServerURL:(NSString *)url  downloaded:(GetImageBlock)block
{
    return [self cachedImageForServerURL:url placeHolderImageName:@"basketball" downloaded:block];
}

@end

