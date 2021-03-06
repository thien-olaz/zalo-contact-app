//
//  AppDelegate.m
//  zalo-contact
//
//  Created by LAp14886 on 15/11/2021.
//

#import "AppDelegate.h"
#import "ContactDataManager.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [ContactDataManager sharedInstance];
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navBarAppearance configureWithOpaqueBackground];
        [UINavigationBar appearance].standardAppearance = navBarAppearance;
        [UINavigationBar appearance].scrollEdgeAppearance = navBarAppearance;
        
        UITabBarAppearance *tabBarAppearance = [UITabBarAppearance.alloc init];
        [tabBarAppearance configureWithOpaqueBackground];
        [UITabBar appearance].standardAppearance = tabBarAppearance;
        [UITabBar appearance].scrollEdgeAppearance = tabBarAppearance;
        
    }
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
