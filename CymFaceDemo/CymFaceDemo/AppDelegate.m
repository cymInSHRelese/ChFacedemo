//
//  AppDelegate.m
//  CymFaceDemo
//
//  Created by 常永梅 on 2021/7/7.
//

#import "AppDelegate.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self ArcSoftFace];
    return YES;
}

-(void)ArcSoftFace{
    ArcSoftFaceEngine *engine = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [engine activeWithAppId:@"DZ6Rd8aAApEmSUvJUDXMRwVFPBUEW5uUP6NyEwjm8xdx" SDKKey:@"52Ps3PRkiRxrHVh7M871NJ8tcJb8h8BBWkhdS777T57B"];
    if (mr == ASF_MOK) {
        NSLog(@"SDK激活成功");
    } else if(mr == MERR_ASF_ALREADY_ACTIVATED){
        NSLog(@"SDK已激活");
    } else {
        NSString *result = [NSString stringWithFormat:@"SDK激活失败：%ld", mr];
        NSLog(@"%@",result);
    }
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
