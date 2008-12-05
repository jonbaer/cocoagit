//
//  GITFileStore.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 07/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITFileStore.h"
#import "NSData+Compression.h"

/*! \cond */
@interface GITFileStore ()
@property(readwrite,copy) NSString * objectsDir;
@end
/*! \endcond */

@implementation GITFileStore
@synthesize objectsDir;

- (id)initWithRoot:(NSString*)root
{
    if (self = [super init])
    {
        self.objectsDir = [root stringByAppendingPathComponent:@"objects"];
    }
    return self;
}
- (NSString*)stringWithPathToObject:(NSString*)sha1
{
    NSString * ref = [NSString stringWithFormat:@"%@/%@",
                      [sha1 substringToIndex:2], [sha1 substringFromIndex:2]];
    
    return [self.objectsDir stringByAppendingPathComponent:ref];
}
- (NSData*)dataWithContentsOfObject:(NSString*)sha1
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * path = [self stringWithPathToObject:sha1];

    if ([fm isReadableFileAtPath:path])
    {
        NSData * zlibData = [NSData dataWithContentsOfFile:path];
        return [zlibData zlibInflate];
    }

    return nil;
}
- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)data
                      type:(GITObjectType*)type error:(NSError**)error
{
    NSUInteger errorCode = 0;
    NSString * errorDescription = nil;
    NSDictionary * errorUserInfo = nil;

    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * path = [self stringWithPathToObject:sha1];

    if ([fm isReadableFileAtPath:path])
    {
        NSData * zlibData = [NSData dataWithContentsOfFile:path];
        NSData * raw = [zlibData zlibInflate];

        NSRange range = [raw rangeOfNullTerminatedBytesFrom:0];
        NSData * meta = [raw subdataWithRange:range];
        *data = [raw subdataFromIndex:range.length + 1];

        NSString * metaStr = [[NSString alloc] initWithData:meta
                                                   encoding:NSASCIIStringEncoding];
        NSUInteger indexOfSpace = [metaStr rangeOfString:@" "].location;
        NSInteger size = [[metaStr substringFromIndex:indexOfSpace + 1] integerValue];

        // This needs to be a GITObjectType value instead of a string
        *type = [metaStr substringToIndex:indexOfSpace];

        if (data && type && size == [data length])
            return YES;
        else
        {
            errorCode = GITErrorObjectStoreSizeMismatch;
            errorDescription = NSLocalizedString(@"Object data sizes do not match", @"");
        }
    }
    else
    {
        errorCode = GITErrorObjectStoreMissingObject;
        errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Unable to load object with %@", @""), sha1];
    }

    if (errorCode != 0 && error != NULL)
    {
        errorUserInfo = [NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey];
        *error = [[NSError alloc] initWithDomain:GITErrorDomain code:errorCode userInfo:errorUserInfo];
    }

    return NO;
}
@end