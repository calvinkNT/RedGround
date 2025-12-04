//
//  UserViewController.m
//  requesttesting
//
//  Created by CalvinK19 on 8/2/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "UserViewController.h"

#import "MainAppViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PostView.h"
#import "PostDetailViewController.h"
#import "SetBG.h"

@interface UserViewController () <UIAlertViewDelegate, UITextFieldDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableArray *postViews;
@property (nonatomic, strong) NSMutableArray *likedPosts;
@end

@implementation UserViewController

@synthesize likedPosts = _likedPosts;

- (void)showUIPopup:(NSString *)title: (NSString *)contents {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:contents
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyRepeatingBackground];
    self.likedPosts = [NSMutableArray array];
    self.postViews = [NSMutableArray array];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.delegate = self;
    [self assignDelegatesForTextFieldsInView:self.view];
    
    if (self.username.length > 0) {
        self.usernameLabel.text = [NSString stringWithFormat: @"%@", self.username];
        NSString *escapedUser = [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.currentPostsURL = [NSString stringWithFormat:@"https://calvink19.co/services/rg/userposts.php?user=%@", escapedUser];
    } else {
        self.titlebar.topItem.title = @"User";
    }
    [self fetchPosts];

}



/*- (void)keyboardWillShow:(NSNotification *)notification {
 [UIView beginAnimations:nil context:nil];
 [UIView setAnimationDuration:0.3];
 
 CGRect frame = self.view.frame;
 if (frame.origin.y == 0) {
 frame.origin.y = -150; // shift up
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
 }*/

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fetchPosts];
    });
}

- (void)clearPostViews {
    for (UIView *v in self.scrollView.subviews) {
        [v removeFromSuperview];
    }
    [self.postViews removeAllObjects];
    [self.likedPosts removeAllObjects];
}

- (NSString *)makeHTTPRequest:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10.0];
    
    // Load token from NSUserDefaults
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

- (void)fetchPosts {
    if (!self.currentPostsURL) return;
    
    NSString *jsonString = [self makeHTTPRequest:self.currentPostsURL];
    if (!jsonString) return;
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error || ![jsonArray isKindOfClass:[NSArray class]]) {
        NSLog(@"JSON parse error: %@", error);
        return;
    }
    
    [self clearPostViews];
    
    CGFloat yOffset = 0;
    for (NSDictionary *dict in jsonArray) {
        NSInteger postId = [[dict objectForKey:@"id"] integerValue];
        
        // Get timestamp if it exists
        NSTimeInterval ts = 0;
        id tsObj = [dict objectForKey:@"timestamp"];
        if ([tsObj respondsToSelector:@selector(doubleValue)]) {
            ts = [tsObj doubleValue];
        }
        NSLog(@"%f",ts);
        NSString *formattedTime = @"";
        if (ts > 0) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"MMM d, HH:mm"; 
            formattedTime = [formatter stringFromDate:date];
        }
        
        // Get reply count
        NSString *repliesUrl = [NSString stringWithFormat:@"https://calvink19.co/services/rg/get_replies.php?id=%ld", (long)postId];
        NSString *repliesJsonStr = [self makeHTTPRequest:repliesUrl];
        
        NSInteger replyCount = 0;
        if (repliesJsonStr) {
            NSData *repliesData = [repliesJsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *repliesJson = [NSJSONSerialization JSONObjectWithData:repliesData options:0 error:nil];
            if ([repliesJson isKindOfClass:[NSDictionary class]]) {
                replyCount = [[repliesJson objectForKey:@"count"] integerValue];
            }
        }
        
        NSMutableDictionary *mutablePost = [dict mutableCopy];
        [mutablePost setObject:[NSNumber numberWithInteger:replyCount] forKey:@"replyCount"];
        [mutablePost setObject:formattedTime forKey:@"formattedTime"];
        
        UIView *postView = [self createPostView:mutablePost yOffset:yOffset];
        yOffset += postView.frame.size.height;
        
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(10, yOffset, self.view.frame.size.width - 20, 1)];
        separator.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        [self.scrollView addSubview:separator];
        
        yOffset += 11;
    }
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, yOffset);
}


- (IBAction)postTypeChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.currentPostsURL = @"https://calvink19.co/services/rg/popularposts.php";
            break;
        case 1:
            self.currentPostsURL = @"https://calvink19.co/services/rg/posts.php";
            break;
        default:
            self.currentPostsURL = @"https://calvink19.co/services/rg/popularposts.php";
            break;
    }
    
    [self fetchPosts];
}

/*- (UIView *)createPostView:(NSDictionary *)post yOffset:(CGFloat)y {
 CGFloat padding = 10;
 CGFloat width = self.view.frame.size.width - padding * 2;
 UIView *postContainer = [[UIView alloc] initWithFrame:CGRectMake(padding, y, width, 170)];
 postContainer.backgroundColor = [UIColor colorWithWhite:1 alpha:1.0];
 //postContainer.layer.cornerRadius = 10.0;
 postContainer.tag = [[post objectForKey: @"id"] integerValue];
 
 //UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(10, 100, postContainer.frame.size.width - 20, 1)];
 //separator.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1.0]; // iOS 6-style gray
 //[postContainer addSubview:separator];
 
 
 // Username
 UILabel *usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, width - 20, 20)];
 usernameLabel.font = [UIFont boldSystemFontOfSize:16];
 usernameLabel.text = [NSString stringWithFormat:@"%@", [post objectForKey:@"username"]];
 [postContainer addSubview:usernameLabel];
 
 // Message
 UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 35, width - 20, 40)];
 messageLabel.text = [post objectForKey:@"message"];
 messageLabel.numberOfLines = 3;
 [postContainer addSubview:messageLabel];
 
 // Like button
 UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
 likeButton.frame = CGRectMake(10, 80, 60, 30);
 NSInteger likeCount = [[post objectForKey:@"likes"] integerValue];
 [likeButton setTitle:[NSString stringWithFormat:@"%ld ❤️", (long)likeCount] forState:UIControlStateNormal];
 [likeButton addTarget:self action:@selector(likeTapped:) forControlEvents:UIControlEventTouchUpInside];
 [postContainer addSubview:likeButton];
 
 // Reply field
 UITextField *replyField = [[UITextField alloc] initWithFrame:CGRectMake(8, 120, width - 30, 30)];
 replyField.borderStyle = UITextBorderStyleRoundedRect;
 replyField.placeholder = @"Reply";
 [postContainer addSubview:replyField];
 
 // Reply button
 UIButton *replyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
 replyBtn.frame = CGRectMake(width - 40, 120, 30, 30);
 [replyBtn setTitle:@"💬" forState:UIControlStateNormal];
 [replyBtn addTarget:self action:@selector(replyTapped:) forControlEvents:UIControlEventTouchUpInside];
 [postContainer addSubview:replyBtn];
 
 // Show replies
 NSArray *replies = [post objectForKey:@"replies"];
 if ([replies isKindOfClass:[NSArray class]]) {
 CGFloat replyY = 160;
 for (NSDictionary *reply in replies) {
 NSString *rUser = [reply objectForKey:@"username"];
 NSString *rText = [reply objectForKey:@"text"];
 if (rUser && rText) {
 UILabel *replyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, replyY, width - 20, 20)];
 replyLabel.font = [UIFont systemFontOfSize:12];
 replyLabel.textColor = [UIColor darkGrayColor];
 replyLabel.text = [NSString stringWithFormat:@"%@: %@", rUser, rText];
 [postContainer addSubview:replyLabel];
 replyY += 20;
 }
 }
 CGRect frame = postContainer.frame;
 frame.size.height = replyY + 10;
 postContainer.frame = frame;
 }
 
 return postContainer;
 }*/

- (void)showPostDetail:(UIButton *)sender {
    
    UIView *view = sender;
    while (view && ![view isKindOfClass:[PostView class]]) {
        view = view.superview;
    }
    if (![view isKindOfClass:[PostView class]]) return;
    PostView *pv = (PostView *)view;
    
    NSDictionary *postDict = @{
                               @"id": @(pv.tag),
                               @"username": pv.usernameLabel.text ?: @"",
                               @"message": pv.messageLabel.text ?: @"",
                               @"likes": @([pv.likeButton.titleLabel.text integerValue]),
                               @"replies": pv.replies ?: @[]
                               };
    
    PostDetailViewController *detailVC = [[PostDetailViewController alloc] initWithNibName:@"PostDetailViewController" bundle:nil];
    detailVC.postData = postDict;
    [self presentViewController:detailVC animated:YES completion:nil];
}



- (UIView *)createPostView:(NSDictionary *)post yOffset:(CGFloat)y {
    PostView *postView = [PostView loadFromNib];
    [postView configureWithPost:post target:self];
    
    CGFloat padding = 10;
    CGFloat width = self.view.frame.size.width - padding * 2;
    postView.frame = CGRectMake(padding, y, width, postView.frame.size.height);
    
    [self.scrollView addSubview:postView];
    [self.postViews addObject:postView];
    
    return postView;
}


- (void)likeTapped:(UIButton *)sender {
    UIView *container = sender;
    while (container && ![container isKindOfClass:[PostView class]]) {
        container = container.superview;
    }
    if (![container isKindOfClass:[PostView class]]) return; // safety
    
    NSInteger postID = container.tag;
    
    sender.enabled = NO; // Disable button while request is ongoing
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlStr = [NSString stringWithFormat:@"https://calvink19.co/services/rg/like.php?id=%ld&username=%@", (long)postID, [[NSUserDefaults standardUserDefaults] stringForKey:@"username"]];
        
        NSString *responseStr = [self makeHTTPRequest:urlStr];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            
            if (!responseStr) {
                NSLog(@"Like request failed (nil response)");
                return;
            }
            
            NSString *currentTitle = [sender titleForState:UIControlStateNormal];
            NSArray *parts = [currentTitle componentsSeparatedByString:@" "];
            NSInteger count = 0;
            if (parts.count > 1) {
                count = [[parts objectAtIndex:0] integerValue];
            }
            
            if ([responseStr isEqualToString:@"Liked"]) {
                count += 1;
                //[sender setTitle:[NSString stringWithFormat:@"%ld ❤️", (long)count] forState:UIControlStateNormal];
            }
            else if ([responseStr isEqualToString:@"Unliked"]) {
                count = MAX(count - 1, 0);
                //[sender setTitle:[NSString stringWithFormat:@"%ld ❤️", (long)count] forState:UIControlStateNormal];
            } else {
                NSLog(@"Unexpected response: %@", responseStr);
            }
            [sender setTitle:[NSString stringWithFormat:@"%ld ❤️", (long)count] forState:UIControlStateNormal];
        });
    });
}

- (void)replyTapped:(UIButton *)sender {
    UIView *container = sender.superview;
    NSInteger postID = container.tag;
    
    NSString *text = @"";
    for (UIView *sub in container.subviews) {
        if ([sub isKindOfClass:[UITextField class]]) {
            UITextField *tf = (UITextField *)sub;
            text = [tf.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            tf.text = @"";
        }
    }
    
    if (text.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"https://calvink19.co/services/rg/reply.php?id=%ld&text=%@&username=%@", (long)postID, text, [[NSUserDefaults standardUserDefaults] stringForKey:@"username"]];
        [self makeHTTPRequest:urlStr];
        [self fetchPosts];
    } else {
        [self showUIPopup:@"Reply field is empty." :@""];
        
        
        NSLog(@"Reply text is empty.");
    }
}

- (IBAction)newPostBtn {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Post"
                                                    message:@"What would you like to say?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Post", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *text = [[alertView textFieldAtIndex:0].text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
        
        if (username && text.length > 0) {
            NSString *urlStr = [NSString stringWithFormat:@"https://calvink19.co/services/rg/newpost.php?username=%@&message=%@", username, text];
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
                [self fetchPosts];
            }
        } else {
            [self showUIPopup:@"..." :@"you gotta say something."];
        }
        
    }
}

- (void)assignDelegatesForTextFieldsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            ((UITextField *)subview).delegate = self;
        } else {
            [self assignDelegatesForTextFieldsInView:subview];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat pullThreshold = -40;  // Negative because contentOffset.y is negative when pulled down
    
    if (scrollView.contentOffset.y < pullThreshold) {
        [self fetchPosts];
        NSLog(@"Refresh triggered");
        [self showUIPopup:@"" :@"Your feed has been refreshed."];
    }
}

- (void)viewDidUnload {
    [self setTotalLikesLabel:nil];
    [self setTotalPostsLabel:nil];
    [self setUsernameLabel:nil];
    [super viewDidUnload];
}

- (IBAction)dismissVCBtn:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end
