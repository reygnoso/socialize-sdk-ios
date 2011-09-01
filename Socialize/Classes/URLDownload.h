//
//  URLDownload.h
//  HitFix
//
//  Created by PointAbout Developer on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "URLDownloadOperation.h"

typedef URLDownloadOperation*(^OperationFactoryBlock)(id target, SEL method, id object);

@interface URLDownload : NSObject
{
@private
    NSString *urlForDownload;
	NSObject *requestedObject;
	SEL notificationSelector;
	NSObject *objectIdentifier;
	NSMutableData *urlData;
	URLDownloadOperation * operation;
    NSOperationQueue* downloadQueue;
}

@property(nonatomic, retain) NSString* urlForDownload;
@property(nonatomic, retain) NSObject* objectIdentifier;
@property(nonatomic, assign) NSObject* requestedObject;
@property(nonatomic, retain) NSMutableData *urlData;
@property(nonatomic, readonly) URLDownloadOperation * operation;
@property(nonatomic, retain) NSOperationQueue * downloadQueue;

+ (NSOperationQueue *)downloadQueue;

- (id) initWithURL:(NSString *)url sender:(NSObject *)caller selector:(SEL)Selector tag:(NSObject *)downloadTag;
- (id) initWithURL:(NSString *)url sender:(NSObject *)caller selector:(SEL)Selector tag:(NSObject *)downloadTag downloadQueue:(NSOperationQueue*)queue operationFactory:(OperationFactoryBlock) factoryBlock;

- (void) cancelDownload;

@end
