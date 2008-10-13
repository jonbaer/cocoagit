//
//  GITTree.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITTree.h"
#import "GITRepo.h"
#import "GITTreeEntry.h"

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITTree ()
@property(readwrite,copy) NSArray * entries;

- (void)extractEntriesFromData:(NSData*)data;

@end
/*! \endcond */

@implementation GITTree
@synthesize entries;

- (id)initWithSha1:(NSString*)sha1 data:(NSData*)raw repo:(GITRepo*)theRepo
{
    if (self = [super initType:@"tree" sha1:sha1
                          size:[raw length] repo:theRepo])
    {
        [self extractEntriesFromData:raw];
    }
    return self;
}
- (void)dealloc
{
    self.entries = nil;
    [super dealloc];
}
- (id)copyWithZone:(NSZone*)zone
{
    GITTree * tree  = (GITTree*)[super copyWithZone:zone];
    tree.entries    = self.entries;
    
    return tree;
}
- (void)extractEntriesFromData:(NSData*)data
{
    NSString  * dataStr = [[NSString alloc] initWithData:data 
                                                encoding:NSASCIIStringEncoding];

    NSMutableArray *treeEntries = [NSMutableArray arrayWithCapacity:2];
    unsigned entryStart = 0;

    do {
        NSRange searchRange = NSMakeRange(entryStart, [dataStr length] - entryStart);
        NSUInteger entrySha1Start = [dataStr rangeOfString:@"\0" 
                                                   options:0
                                                     range:searchRange].location;

        NSRange entryRange = NSMakeRange(entryStart, 
            entrySha1Start - entryStart + kGITPackedSha1Length + 1);
        
        NSString * treeLine = [dataStr substringWithRange:entryRange];
        GITTreeEntry * entry = [[GITTreeEntry alloc] initWithTreeLine:treeLine repo:self.repo];
        [treeEntries addObject:entry];

        entryStart = entryRange.location + entryRange.length;
    } while(entryStart < [dataStr length]);
    
    self.entries = treeEntries;
}
- (NSData*)rawContent
{
    NSMutableData * content = [NSMutableData dataWithCapacity:self.size];
    for (GITTreeEntry * entry in self.entries)
    {
        [content appendData:[entry raw]];
    }
    return [content copy];
}

@end
