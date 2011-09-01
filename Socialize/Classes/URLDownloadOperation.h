//
//  URLDownloadOperation.h
//  appbuildr
//
//  Created by Isaac Mosquera on 6/8/10.
//  Copyright 2010 pointabout. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface URLDownloadOperation : NSInvocationOperation {

	NSURLConnection * urlConnection;
}
@property(assign) NSURLConnection * urlConnection;

-(void) cancel;
@end