//
//  SettingsViewController.m
//  requesttesting
//
//  Created by CalvinK19 on 7/19/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.usernameLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        //NSLog(@"Response from server: %@", responseString);
        return responseString;
    }
}



- (IBAction)logoutBtn:(id)sender {
    NSString *response = [self makeHTTPRequest:@"https://calvink19.co/services/rg/logout.php"];
    NSLog(@"Logout response: %@", response);
    if (response) {
        NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (!jsonError && [json isKindOfClass:[NSDictionary class]]) {
            BOOL success = [[json objectForKey:@"success"] boolValue];
            NSString *message = [json objectForKey:@"message"];
            
            if (!success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:(success ? @"Logout Successeful" : @"Logout Failed")
                                      message:message
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alert show];
            });
            }
        } else {
            NSLog(@"JSON parse error: %@", jsonError);
        }
    } else {
        NSLog(@"No response received.");
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    
    loginVC.view.frame = CGRectMake(-screenFrame.size.width, 0, screenFrame.size.width, screenFrame.size.height);
    [window addSubview:loginVC.view];
    

    [UIView animateWithDuration:0.5 animations:^{

        self.view.frame = CGRectMake(screenFrame.size.width, 0, screenFrame.size.width, screenFrame.size.height);

        loginVC.view.frame = screenFrame;
    } completion:^(BOOL finished) {

        window.rootViewController = loginVC;
    }];
}

- (IBAction)dismissBtn:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)termsBtn:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://calvink19.co/services/rg/tos.txt"]];
}

- (IBAction)conditionsBtn:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://calvink19.co/services/rg/cg.txt"]];
}
@end
