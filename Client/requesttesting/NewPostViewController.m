//
//  NewPostViewController.m
//  requesttesting
//
//  Created by CalvinK19 on 8/3/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "NewPostViewController.h"

@interface NewPostViewController () <UITextFieldDelegate>

@end

@implementation NewPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.delegate = self;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.text = @"Enter your text here...";
    self.textView.textColor = [UIColor lightGrayColor];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@"Enter your text here..."] && [textView.textColor isEqual:[UIColor lightGrayColor]]) {
        textView.text = @"";
        textView.textColor = [UIColor whiteColor];
    }
}

#pragma mark - Prevent newline and dismiss keyboard
- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    NSUInteger newLength = textView.text.length - range.length + text.length;
    return newLength <= 255;
}

#pragma mark - Live character count
- (void)textViewDidChange:(UITextView *)textView {
    NSInteger charCount = textView.text.length;
    self.titlebar.topItem.title = [NSString stringWithFormat:@"%ld/255 characters", (long)charCount];
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

- (void)showUIPopup:(NSString *)title: (NSString *)contents {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:contents
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)newPostBtn:(id)sender {
    NSString *text = self.textView.text;
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    
    if (username && text.length > 0) {
        NSString *encodedText = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedUser = [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *urlStr = [NSString stringWithFormat:
                            @"https://calvink19.co/services/rg/newpost.php?username=%@&message=%@",
                            encodedUser, encodedText];
        NSString *response = [self makeHTTPRequest:urlStr];
        
        if (!response) {
            [self showUIPopup:@"Error" :@"No response from server."];
            return;
        }
        
        NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
            [self showUIPopup:@"Error" :@"Invalid response from server."];
            return;
        }
        
        NSNumber *success = [json objectForKey:@"success"];
        NSString *message = [json objectForKey:@"message"];
        
        if (success && ![success boolValue]) {
            [self showUIPopup:@"Post Failed" :message ?: @"Unknown error"];
        } else {
            //[self fetchPosts];
            [self showUIPopup:@"" :@"Posted successfully!"];
            [self.textView resignFirstResponder];
            self.textView.text = @"";
        }
    } else {
        [self.textView resignFirstResponder];
    }
    
}
- (void)viewDidUnload {
    [self setTitlebar:nil];
    [self setTextView:nil];
    [super viewDidUnload];
}
- (IBAction)clearBtn:(id)sender {
    self.textView.text = @"";
}
@end
