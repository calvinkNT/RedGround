//
//  AppDelegate.m
//  requesttesting
//
//  Created by CalvinK19 on 5/28/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <UIAlertViewDelegate>
@property (nonatomic, strong) NSString *pendingPostText;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [NSURL URLWithString:@"https://calvink19.co/services/rg/mods.json"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        if (data) {
            NSArray *modsArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([modsArray isKindOfClass:[NSArray class]]) {
                [[NSUserDefaults standardUserDefaults] setObject:modsArray forKey:@"cachedMods"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSLog(@"Cached moderator list: %@", modsArray);
            }
        }
    });
    
    return YES;
}

- (void)setupTabBarControllerDelegate:(UITabBarController *)tabBarController {
    tabBarController.delegate = self;
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    NSInteger selectedIndex = [tabBarController.viewControllers indexOfObject:viewController];
    NSLog(@"Tab selected: %ld", (long)selectedIndex);
    
    if (selectedIndex == 1) {
        [self showTextInputDialog];
        return NO;
    }
    
    return YES;
}

- (void)showTextInputDialog {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Post"
                                                    message:[NSString stringWithFormat:@"%lu/255 characters", (unsigned long)self.pendingPostText.length]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Post", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alert textFieldAtIndex:0];
    textField.delegate = self;
    textField.placeholder = @"What's on your mind?";
    
    if (self.pendingPostText) {
        textField.text = self.pendingPostText;
    }
    
    [alert show];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = textField.text.length - range.length + string.length;
    
    if (newLength > 255) {
        return NO;
    }
    
    UIAlertView *alert = (UIAlertView *)textField.superview;
    alert.message = [NSString stringWithFormat:@"%lu/255 characters", (unsigned long)newLength];
    
    return YES;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *enteredText = textField.text;
    
    if (buttonIndex == 1) { 
        [self handlePostSubmission:enteredText];
    } else if (buttonIndex == 0) { 
        self.pendingPostText = nil;
    }
}

- (void)handlePostSubmission:(NSString *)text {
    if (!text || text.length == 0) {
        [self showErrorAlert:@"Post cannot be empty"];
        return;
    }
    
    if (text.length > 255) {
        [self showCharacterLimitAlert:text];
        return;
    }
    
    [self submitPost:text];
}

// too lazy to remove it
- (void)showCharacterLimitAlert:(NSString *)text {
    self.pendingPostText = text;
    
    UIAlertView *limitAlert = [[UIAlertView alloc] initWithTitle:@"Post Too Long"
                                                         message:@"Posts cannot exceed 255 characters. Please shorten your post."
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [limitAlert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Post Too Long"]) {
        [self showTextInputDialog];
    }
}

- (void)submitPost:(NSString *)text {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    
    if (!username) {
        [self showErrorAlert:@"You must be logged in to post"];
        return;
    }
    
    NSString *encodedText = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedUser = [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlStr = [NSString stringWithFormat:
                        @"https://calvink19.co/services/rg/newpost.php?username=%@&message=%@",
                        encodedUser, encodedText];
    
    NSString *response = [self makeHTTPRequest:urlStr];
    
    if (!response) {
        [self showErrorAlert:@"No response from server"];
        return;
    }
    
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
        [self showErrorAlert:@"Invalid response from server"];
        return;
    }
    
    NSNumber *success = [json objectForKey:@"success"];
    NSString *message = [json objectForKey:@"message"];
    
    if (success && [success boolValue]) {
        [self showSuccessAlert:@"Posted successfully!"];
        self.pendingPostText = nil;
        
        [self notifyPostsRefresh];
    } else {
        [self showErrorAlert:message ?: @"Post failed"];
    }
}

- (NSString *)makeHTTPRequest:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10.0];
    
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    
    if (authToken) {
        [request setValue:authToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    
    if (error) {
        NSLog(@"Request error: %@", error);
        return nil;
    } else {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response from server: %@", responseString);
        return responseString;
    }
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)showSuccessAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)notifyPostsRefresh {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostCreated" object:nil];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end