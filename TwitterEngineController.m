//
//  TwitterEngineController.m
//  socialpass
//
//  Created by Corey Floyd on 6/26/10.
//  Copyright 2010 Flying Jalapeño Software. All rights reserved.
//

#import "TwitterEngineController.h"
#import "MGTwitterEngine.h"


//TODO: add type def for method calls so we can track what we are doing.

@interface TwitterEngineController()

@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *XAuthFetchID;
@property (nonatomic, retain) OAToken *token;
@property (nonatomic, copy, readwrite) NSString *userID;
@property (nonatomic, copy) NSString *postID;


@end


@implementation TwitterEngineController

@synthesize twitterEngine;
@synthesize XAuthFetchID;
@synthesize username;
@synthesize password;
@synthesize delegate;
@synthesize token;
@synthesize postID;
@synthesize userID;





SYNTHESIZE_SINGLETON_FOR_CLASS(TwitterEngineController);



- (void) dealloc
{
    
    delegate = nil;
    
    
    [userID release];
    userID = nil;
    
    [postID release];
    postID = nil;
        
    [token release];
    token = nil;
        
    [username release];
    username = nil;
    
    [password release];
    password = nil;
    
    [XAuthFetchID release];
    XAuthFetchID = nil;
    
    [twitterEngine release];
    twitterEngine = nil;
    
    [super dealloc];
}




- (id) init
{
    self = [super init];
    if (self != nil) {
        
        self.twitterEngine = [MGTwitterEngine twitterEngineWithDelegate:self];
        [self.twitterEngine setConsumerKey:kTwitterOAuthConsumerKey secret:kTwitterOAuthConsumerSecret];
        
        self.username = [[NSUserDefaults standardUserDefaults] objectForKey:kTwitterNameKey];
        
        self.token = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:kTwitterProvider prefix:kTwitterPrefix] autorelease];
        
        [self.twitterEngine setAccessToken:self.token];
                
    }
    return self;
}

- (BOOL)loggedIn{
    
    return (self.token != nil);
}

- (BOOL)loginWithUserName:(NSString*)name password:(NSString*)pwd{
    
    if(name == nil || pwd == nil)
        return NO;
    
    self.username = name;
    self.password = pwd;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject: nil forKey:kTwitterNameKey];
    [OAToken removeFromUserDefaultsWithServiceProviderName:kTwitterProvider prefix:kTwitterPrefix];
    
    [defaults synchronize];
    
    self.token = nil;
        
    self.XAuthFetchID = [self.twitterEngine getXAuthAccessTokenForUsername:self.username password:self.password];
    
    if(self.XAuthFetchID != nil)
        return YES;
    
    return NO;
    
}

- (BOOL)logoutAClearCredentials{
    
    [OAToken removeFromUserDefaultsWithServiceProviderName:kTwitterProvider prefix:kTwitterPrefix];
    
    self.token = nil;
    self.userID = nil;
    self.username = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults removeObjectForKey:kTwitterNameKey];
    
    [defaults synchronize];
    
    return YES;
    
}

- (BOOL)getFollowers{
    
    if(self.loggedIn == NO)
        return NO;
    
    if([self.twitterEngine getFollowerIDsFor:self.username startingFromCursor:-1])
        return YES;
    
    return NO;
    
    
}
- (BOOL)getFollowing{
    
    if(self.loggedIn == NO)
        return NO;
    
    if([self.twitterEngine getFriendIDsFor:self.username startingFromCursor:-1])
        return YES;
    
    return NO;
    
}

- (BOOL)postMessage:(NSString*)message{
    
    if(self.loggedIn == NO)
        return NO;
    
    self.postID = [self.twitterEngine sendUpdate:message];
    
    if(postID != nil)
        return YES;
    
    return NO;
    
    
}

#pragma mark -
#pragma mark MGTwitterEngineDelegate

- (void)accessTokenReceived:(OAToken *)aToken forRequest:(NSString *)connectionIdentifier{
    
    self.XAuthFetchID = nil;
    self.token = aToken;
    [self.twitterEngine setAccessToken:aToken];
    
    [aToken storeInUserDefaultsWithServiceProviderName:kTwitterProvider prefix:kTwitterPrefix];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:username forKey:kTwitterNameKey];
	
	[defaults synchronize];
    
    self.userID = self.twitterEngine.userID;

    if([delegate respondsToSelector:@selector(twitterEngineController:didLogin:error:)])
        [delegate twitterEngineController:self didLogin:YES error:nil];

    
    
}


- (void)requestSucceeded:(NSString *)connectionIdentifier{
    
    debugLog(@"yeah!");
    
    if([connectionIdentifier isEqualToString:self.postID]){
        
        self.postID = nil;
        
        if([delegate respondsToSelector:@selector(twitterEngineController:postSuccessful:error:)])
            [delegate twitterEngineController:self postSuccessful:YES error:nil];
                
    }
    
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error{
	
    debugLog(@"neah!");
    
    if([connectionIdentifier isEqualToString:self.XAuthFetchID]){
        
        self.XAuthFetchID = nil;
                
        
        if([delegate respondsToSelector:@selector(twitterEngineController:didLogin:error:)])
            [delegate twitterEngineController:self didLogin:NO error:error];
    

    }else if([connectionIdentifier isEqualToString:self.postID]){

        
        self.postID = nil;
        
        if([delegate respondsToSelector:@selector(twitterEngineController:postSuccessful:error:)])
            [delegate twitterEngineController:self postSuccessful:NO error:error];
        
        
    }else{
        

        if([delegate respondsToSelector:@selector(twitterEngineController:didFetchFollowing:error:)])
            [delegate twitterEngineController:self didFetchFollowing:nil error:error];

        
    }
}

- (void)socialGraphInfoReceived:(NSArray *)socialGraphInfo forRequest:(NSString *)connectionIdentifier{
    
    NSLog(@"super yeah! %@", [socialGraphInfo description]);
    
    if([socialGraphInfo isKindOfClass:[NSArray class]] && [socialGraphInfo count] > 0){
        
        NSDictionary* response = [socialGraphInfo objectAtIndex:0];
        NSArray* ids = [response objectForKey:@"ids"];
        
        if([ids count] > 0){
            
            if([delegate respondsToSelector:@selector(twitterEngineController:didFetchFollowing:error:)])
                [delegate twitterEngineController:self didFetchFollowing:ids error:nil];
            
        }else{
            
            if([delegate respondsToSelector:@selector(twitterEngineController:didFetchFollowing:error:)])
                [delegate twitterEngineController:self didFetchFollowing:nil error:nil];
            
        }
    }
}



@end
