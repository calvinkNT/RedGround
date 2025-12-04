//
//  ViewController.m
//  requesttesting
//
//  Created by CalvinK19 on 5/28/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonHMAC.h>
#import <QuartzCore/QuartzCore.h>
#import "SetBG.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyRepeatingBackground];
    [self loadMotd];
    
    // Existing observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Check for saved credentials and auto-login
    NSString *savedUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    NSString *savedPassword = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    
    if (savedUsername && savedPassword) {
        self.userLiTextField.text = savedUsername;
        self.passLiTextField.text = savedPassword;
        
        [self showLoadingSpinnerWithText:@""];
        
        [self performSelector:@selector(makeLiReq:) withObject:nil afterDelay:0.5];
    }

    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    if (username && username.length > 0) {
        NSLog(@"Username exists: %@", username);
    } else {
        // Key does not exist or is empty
        NSLog(@"Username is missing or empty");
    }

}

- (void)showLoadingSpinnerWithText:(NSString *)text {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    self.loadingOverlay = [[UIView alloc] initWithFrame:keyWindow.bounds];
    self.loadingOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]; // Semi-transparent black
    self.loadingOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //self.loadingOverlay.hidden = YES;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
    containerView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    containerView.layer.cornerRadius = 10.0;
    containerView.center = self.loadingOverlay.center;
    containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = CGPointMake(containerView.bounds.size.width / 2, containerView.bounds.size.height / 2 - 15);
    self.activityIndicator.hidesWhenStopped = NO;
    
    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, containerView.bounds.size.height - 35, containerView.bounds.size.width - 20, 20)];
    self.loadingLabel.text = @"Logging in";
    self.loadingLabel.textColor = [UIColor whiteColor];
    self.loadingLabel.backgroundColor = [UIColor clearColor];
    self.loadingLabel.textAlignment = UITextAlignmentCenter;
    self.loadingLabel.font = [UIFont boldSystemFontOfSize:18];
    
    [containerView addSubview:self.activityIndicator];
    [containerView addSubview:self.loadingLabel];
    [self.loadingOverlay addSubview:containerView];
    
    //UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:self.loadingOverlay];
    [self.activityIndicator startAnimating];


}

- (void)hideLoadingSpinner {
    [self.activityIndicator stopAnimating];
    [self.loadingOverlay removeFromSuperview];
    self.loadingOverlay = nil;
}


- (void)keyboardWillShow:(NSNotification *)notification {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    
    CGRect frame = self.view.frame;
    if (frame.origin.y == 0) {
        frame.origin.y = -150;
        self.view.frame = frame;
    }
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    
    CGRect frame = self.view.frame;
    frame.origin.y = 0; // shift down
    self.view.frame = frame;
    
    [UIView commitAnimations];
}


- (void)showUIPopup:(NSString *)title: (NSString *)contents {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:contents
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)loadMotd {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastFetchDate = [defaults objectForKey:@"motdLastFetchDate"];
    
    BOOL shouldFetch = YES;
    if (lastFetchDate) {
        NSTimeInterval timeSinceLastFetch = [[NSDate date] timeIntervalSinceDate:lastFetchDate];
        if (timeSinceLastFetch < 24 * 60 * 60) {
            shouldFetch = NO;
        }
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cacheFilePath = [documentsDirectory stringByAppendingPathComponent:@"motd.json"];
    
    if (!shouldFetch) {
        NSData *jsonData = [NSData dataWithContentsOfFile:cacheFilePath];
        if (jsonData) {
            [self parseMotdData:jsonData];
            return;
        }
    }
    
    NSString *motdURLString = @"https://calvink19.co/services/rg/motd.json";
    NSURL *motdURL = [NSURL URLWithString:motdURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:motdURL
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:10.0];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSData *jsonData = nil;
                               
                               if (error || !data) {
                                   NSLog(@"Failed to download MOTD JSON, trying cached file.");
                                   jsonData = [NSData dataWithContentsOfFile:cacheFilePath];
                                   if (!jsonData) {
                                       NSLog(@"No cached MOTD available.");
                                       self.motdLabel.text = @"Welcome!";
                                       return;
                                   }
                               } else {
                                   jsonData = data;
                                   [jsonData writeToFile:cacheFilePath atomically:YES];
                                   [defaults setObject:[NSDate date] forKey:@"motdLastFetchDate"];
                                   [defaults synchronize];
                               }
                               
                               [self parseMotdData:jsonData];
                           }];
}

- (void)parseMotdData:(NSData *)jsonData {
    NSError *jsonError = nil;
    NSArray *motdArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    if (jsonError || ![motdArray isKindOfClass:[NSArray class]] || [motdArray count] == 0) {
        NSLog(@"Failed to parse MOTD JSON or empty array");
        self.motdLabel.text = @"Welcome!";
        return;
    }
    
    NSUInteger randomIndex = arc4random_uniform((uint32_t)[motdArray count]);
    NSString *randomMotd = [motdArray objectAtIndex:randomIndex];
    self.motdLabel.text = randomMotd;
}



- (NSString *)makeHTTPRequest:(NSString *)urlString {
    
    NSURL *url = [NSURL URLWithString:(urlString)];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:10.0];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    
    if (error) {
        NSLog(@"Request error: %@", error);
        //return error;
    } else {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response from server: %@", responseString);
        return responseString;
    }
}

//Signup
- (IBAction)makeSuReq:(id)sender {
    NSString *urlString = [NSString stringWithFormat:@"http://calvink19.co/services/rg/signup.php?user=%@&pass=%@", self.userSuTextField.text, self.passSuTextField.text];
    NSString *response = [self makeHTTPRequest:urlString];
    
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    NSString *messageToShow = @"An error occurred";
    BOOL success = NO;
    
    if (!jsonError && [jsonDict isKindOfClass:[NSDictionary class]]) {
        messageToShow = [jsonDict objectForKey: @"message"] ?: messageToShow;
        success = [[jsonDict objectForKey: @"success"] boolValue];
    }
    
    if (success) {
        [self showUIPopup:@"Signup Success" :messageToShow];
    } else {
        [self showUIPopup:@"Signup Error" :messageToShow];
    }
}

//Login
- (IBAction)makeLiReq:(id)sender {
    BOOL isAutoLogin = (sender == nil); 
    
    if (isAutoLogin) {
        [self showLoadingSpinnerWithText:@"Logging in..."];
    }
    
    NSString *urlString = @"https://calvink19.co/services/rg/login.php";
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSDictionary *jsonDict = @{
                               @"user": self.userLiTextField.text ?: @"",
                               @"pass": self.passLiTextField.text ?: @""
                               };
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
    if (error) {
        NSLog(@"JSON serialization error: %@", error);
        [self showUIPopup:@"Error" :@"Unable to create login request."];
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    self.loginConnectionData = [NSMutableData data];
    self.loginConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.loginConnectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self hideLoadingSpinner];
    
    NSError *jsonError = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:self.loginConnectionData options:0 error:&jsonError];
    NSLog(@"Raw response string: %@", [[NSString alloc] initWithData:self.loginConnectionData encoding:NSUTF8StringEncoding]);
    if (jsonError || !jsonDict) {
        [self showUIPopup:@"Error" :@"Failed to parse server response."];
        return;
    }
    
    BOOL success = [[jsonDict objectForKey:@"success"] boolValue];
    NSString *message = [jsonDict objectForKey:@"message"] ?: @"An error occurred";
    
    if (success) {
        NSString *token = [jsonDict objectForKey:@"token"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
        [[NSUserDefaults standardUserDefaults] setObject:self.userLiTextField.text forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:self.passLiTextField.text forKey:@"password"];
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"authToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UITabBarController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBarController"];
        
        // Set up tab bar delegate to intercept specific tab selections
        tabBarController.delegate = (id<UITabBarControllerDelegate>)[UIApplication sharedApplication].delegate;
        BOOL isMod = [[[NSUserDefaults standardUserDefaults] objectForKey:@"cachedMods"] containsObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"username"]];

        if (isMod){
            NSLog(@"User is a moderator.");
        }
        
        UIWindow *window = [UIApplication sharedApplication].delegate.window;
        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        tabBarController.view.frame = CGRectMake(screenFrame.size.width, 0, screenFrame.size.width, screenFrame.size.height);
        [window addSubview:tabBarController.view];
        
        [UIView animateWithDuration:0.25 animations:^{
            tabBarController.view.frame = screenFrame;
        } completion:^(BOOL finished) {
            window.rootViewController = tabBarController;
        }];
    } else {
        [self showUIPopup:@"Login Failed" :message];
    }
    
    self.loginConnection = nil;
    self.loginConnectionData = nil;
}

// Called on connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self hideLoadingSpinner];
    [self showUIPopup:@"Connection Error" :@"Unable to reach the server."];
    self.loginConnection = nil;
    self.loginConnectionData = nil;
}


- (IBAction)termsBtn:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://calvink19.co/services/rg/tos.txt"]];
}

- (IBAction)conditionsBtn:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://calvink19.co/services/rg/cg.txt"]];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
