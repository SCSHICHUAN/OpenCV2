//
//  AppDelegate.m
//  FirstOpenCV
//
//  Created by Stan on 2023/8/12.
//

#import "AppDelegate.h"
#import "TXLiteAVSDK_Professional/TXLiteAVSDK.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
     
    
    
  
    [V2TXLivePremier setLicence:@"xx"
                                key:@"xx"];
       
    
    
    V2TXLiveLogConfig *log = [[V2TXLiveLogConfig alloc] init];
    log.logLevel = V2TXLiveLogLevelNULL;
    [V2TXLivePremier setLogConfig:log];

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
