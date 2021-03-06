//
//  SocializeDeviceTokenSenderTests.m
//  SocializeSDK
//
//  Created by Nathaniel Griswold on 2/14/12.
//  Copyright (c) 2012 Socialize, Inc. All rights reserved.
//

#import "SocializeDeviceTokenSenderTests.h"
#import "_Socialize.h"
#import "SocializePrivateDefinitions.h"
#import "SocializeTestCase.h"

@interface SocializeDeviceTokenSender ()
- (void)startTimer;
- (void)timerCheck;
@property (nonatomic, assign) BOOL tokenOnServer;
@property (nonatomic, assign) BOOL tokenIsDevelopment;
@end

@implementation SocializeDeviceTokenSenderTests
@synthesize deviceTokenSender = deviceTokenSender_;
@synthesize mockSocialize = mockSocialize_;
@synthesize testTokenData = testTokenData_;
@synthesize testTokenString = testTokenString_;

- (void)setUp {
    self.deviceTokenSender = [[[SocializeDeviceTokenSender alloc] init] autorelease];
    self.deviceTokenSender = [OCMockObject partialMockForObject:self.deviceTokenSender];
    
    // Mock Socialize
    self.mockSocialize = [OCMockObject mockForClass:[Socialize class]];
    [[self.mockSocialize stub] setDelegate:nil];
    self.deviceTokenSender.socialize = self.mockSocialize;
    
    char testTokenData[2] = "\xaa\xff";
    self.testTokenData = [NSData dataWithBytes:&testTokenData length:sizeof(testTokenData)];
    self.testTokenString = @"aaff";
}

- (void)tearDown {
    [self.mockSocialize verify];
    self.mockSocialize = nil;
    self.deviceTokenSender = nil;
}

- (void)testThatDeviceTokenResentOnUserChange {
    NSString *testToken = @"FFFF1234";
    
    [[NSUserDefaults standardUserDefaults] setObject:testToken forKey:kSocializeDeviceTokenKey];
    self.deviceTokenSender.tokenOnServer = YES;
    self.deviceTokenSender.tokenIsDevelopment = YES;
    
    [[self.mockSocialize expect] _registerDeviceTokenString:testToken development:YES];
    [[[self.mockSocialize stub] andReturnBool:YES] isAuthenticated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SocializeAuthenticatedUserDidChangeNotification object:nil];
    
    BOOL registered = self.deviceTokenSender.tokenOnServer;
    GHAssertFalse(registered, @"Should not be registered");
}

- (void)testThatFailureStartsTimer {
    self.deviceTokenSender.tokenOnServer = NO;
    
    [[(id)self.deviceTokenSender expect] startTimer];
    
    [self.deviceTokenSender service:nil didFail:nil];
}

- (void)testSuccessfulCreateUpdatesRegisteredStatus {
    NSString *testToken = @"ffff1234";

    [[NSUserDefaults standardUserDefaults] setObject:testToken forKey:kSocializeDeviceTokenKey];
    self.deviceTokenSender.tokenOnServer = NO;

    
    // Simulate server response with capitalized token string
    SocializeDeviceToken *deviceToken = [[[SocializeDeviceToken alloc] init] autorelease];
    [deviceToken setDevice_token:[testToken uppercaseString]];
    
    [self.deviceTokenSender service:nil didCreate:deviceToken];
    
    GHAssertTrue(self.deviceTokenSender.tokenOnServer, @"Should be registered");
}

- (void)testSuccessfulCreateWithMismatchedTokenFailsAndStartsTimer {
    NSString *testToken = @"FFFF1234";

    [[NSUserDefaults standardUserDefaults] setObject:testToken forKey:kSocializeDeviceTokenKey];
    self.deviceTokenSender.tokenOnServer = NO;
    
    SocializeDeviceToken *deviceToken = [[[SocializeDeviceToken alloc] init] autorelease];
    [deviceToken setDevice_token:@"blah"];

    // Timer should start
    [[(id)self.deviceTokenSender expect] startTimer];

    [self.deviceTokenSender service:nil didCreate:deviceToken];
    
    GHAssertFalse(self.deviceTokenSender.tokenOnServer, @"Should not be registered");
}

- (void)testDeviceTokenRegistrationWithNoUserAuths {
    self.deviceTokenSender.tokenOnServer = NO;
    [[[self.mockSocialize stub] andReturnBool:NO] isAuthenticated];
    [[self.mockSocialize expect] authenticateAnonymously];
    
    [self.deviceTokenSender registerDeviceToken:self.testTokenData development:YES];
}

- (void)testDeviceTokenRegistrationWithUserDoesSend {
    self.deviceTokenSender.tokenOnServer = NO;

    [[[self.mockSocialize stub] andReturnBool:YES] isAuthenticated];
    [[self.mockSocialize expect] _registerDeviceTokenString:self.testTokenString development:YES];
    
    [self.deviceTokenSender registerDeviceToken:self.testTokenData development:YES];
}

- (void)testTokenAvailableWhenSet {
    NSString *testToken = @"FFFF1234";
    [[NSUserDefaults standardUserDefaults] setObject:testToken forKey:kSocializeDeviceTokenKey];

    BOOL available = [self.deviceTokenSender tokenAvailable];
    GHAssertTrue(available, @"should be available");
}

- (void)testTimerCheckInvalidatesTimerIfNotNeeded {
    id mockTimer = [OCMockObject mockForClass:[NSTimer class]];
    self.deviceTokenSender.timer = mockTimer;

    // Token already sent
    self.deviceTokenSender.tokenOnServer = YES;
    
    // Should invalidate
    [[mockTimer expect] invalidate];

    [self.deviceTokenSender timerCheck];
    [mockTimer verify];
}

- (void)expectRegistrationAndSucceed {
    [[[self.mockSocialize expect] andDo:^(NSInvocation *inv) {
        NSString *deviceTokenString;
        [inv getArgument:&deviceTokenString atIndex:2];
        SocializeDeviceToken *deviceToken = [[[SocializeDeviceToken alloc] init] autorelease];
        [deviceToken setDevice_token:deviceTokenString];
        [self.deviceTokenSender service:nil didCreate:deviceToken];
    }] _registerDeviceTokenString:OCMOCK_ANY development:YES];
}

- (void)testSendingMultipleTokens {
    char testTokenData1[2] = "\x11\x22";
    NSData *testToken1 = [NSData dataWithBytes:&testTokenData1 length:sizeof(testTokenData1)];

    char testTokenData2[2] = "\xbb\xee";
    NSString *testTokenString2 = @"bbee";
    NSData *testToken2 = [NSData dataWithBytes:&testTokenData2 length:sizeof(testTokenData2)];

    [[[self.mockSocialize stub] andReturnBool:YES] isAuthenticated];
    
    [self expectRegistrationAndSucceed];
    
    [[self.mockSocialize expect] _registerDeviceTokenString:testTokenString2 development:YES];
    
    [self.deviceTokenSender registerDeviceToken:testToken1 development:YES];
    [self.deviceTokenSender registerDeviceToken:testToken2 development:YES];
}

@end
