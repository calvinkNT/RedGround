//
//  PostView.m
//  requesttesting
//
//  Created by CalvinK19 on 7/28/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "PostView.h"
#import <UIKit/UIKit.h>

@implementation PostView


+ (id)loadFromNib {
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"PostView" owner:nil options:nil];
    for (id object in nibContents) {
        if ([object isKindOfClass:[self class]]) {
            return object;
        }
    }
    return nil;
}

- (void)configureWithPost:(NSDictionary *)post target:(id)target {
    self.tag = [[post objectForKey:@"id"] integerValue];
    
    NSString *username = [post objectForKey:@"username"] ?: @"";
    self.usernameLabel.text = username;
    self.messageLabel.text = [post objectForKey:@"message"];
    
    // Set author button label to username
    [self.authorBtn setTitle:username forState:UIControlStateNormal];
    
    // Remove previous targets to avoid duplicates
    [self.authorBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    // Attach tap action
    [self.authorBtn addTarget:self action:@selector(openUserVCBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    // Store the username for later use
    self.authorBtn.tag = self.tag;
    self.authorBtn.accessibilityLabel = username;
    
    // Show/hide delete button depending on owner
    NSString *currentUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    if ([username isEqualToString:currentUsername]) {
        self.deleteBtn.hidden = NO;
        [self.deleteBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.deleteBtn addTarget:self action:@selector(deleteBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.deleteBtn.hidden = YES;
    }
    BOOL isMod = [[[NSUserDefaults standardUserDefaults] objectForKey:@"cachedMods"] containsObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"username"]];
    
    if (isMod) {
        self.deleteBtn.hidden = NO;
    }
    
    if ([post objectForKey:@"formattedTime"]) {
        self.timeLabel.text = [post objectForKey:@"formattedTime"];
    } else {
        self.timeLabel.text = @"";
    }
    
    // Allow wrapping and multiple lines
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    // Calculate needed size for the message
    CGFloat maxWidth = self.messageLabel.frame.size.width;
    CGSize textSize = [self.messageLabel.text
                       sizeWithFont:self.messageLabel.font
                       constrainedToSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                       lineBreakMode:UILineBreakModeWordWrap];
    
    // Resize message label
    CGRect msgFrame = self.messageLabel.frame;
    msgFrame.size.height = ceil(textSize.height);
    self.messageLabel.frame = msgFrame;
    
    // Move the container view (everything below the message)
    CGFloat containerY = CGRectGetMaxY(self.messageLabel.frame) + 8;
    CGRect lowerFrame = self.lowerContainerView.frame; // <-- Add this UIView in Interface Builder
    lowerFrame.origin.y = containerY;
    self.lowerContainerView.frame = lowerFrame;
    
    // Adjust entire post view height
    CGRect myFrame = self.frame;
    myFrame.size.height = CGRectGetMaxY(self.lowerContainerView.frame) + 8;
    self.frame = myFrame;
    
    // Like button setup
    NSInteger likeCount = [[post objectForKey:@"likes"] integerValue];
    [self.likeButton setTitle:[NSString stringWithFormat:@"%d ❤️", likeCount] forState:UIControlStateNormal];
    [self.likeButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.likeButton addTarget:target action:@selector(likeTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Reply button setup
    NSInteger replyCount = [[post objectForKey:@"replyCount"] integerValue];
    [self.replyButton setTitle:[NSString stringWithFormat:@"%d 💬", replyCount] forState:UIControlStateNormal];
    [self.replyButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.replyButton addTarget:target action:@selector(showPostDetail:) forControlEvents:UIControlEventTouchUpInside];
    
    // Info
    [self.infoButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.infoButton addTarget:target action:@selector(showPostDetail:) forControlEvents:UIControlEventTouchUpInside];
    
    // Replies list
    self.replies = [post objectForKey:@"replies"];
    for (UIView *subview in self.repliesContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    NSArray *replies = [post objectForKey:@"replies"];
    if ([replies isKindOfClass:[NSArray class]] && [replies count] > 0) {
        NSUInteger count = MIN(3, [replies count]);
        NSArray *lastReplies = [replies subarrayWithRange:NSMakeRange([replies count] - count, count)];
        
        CGFloat yOffset = 0;
        for (NSDictionary *reply in lastReplies) {
            NSString *username = [reply objectForKey:@"username"] ?: @"";
            NSString *text = [reply objectForKey:@"text"] ?: @"";
            NSString *replyText = [NSString stringWithFormat:@"%@: %@", username, text];
            
            UILabel *replyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, self.repliesContainerView.frame.size.width, 20)];
            replyLabel.font = [UIFont systemFontOfSize:12];
            replyLabel.textColor = [UIColor darkGrayColor];
            replyLabel.text = replyText;
            
            [self.repliesContainerView addSubview:replyLabel];
            yOffset += 22;
        }
        
        CGRect frame = self.repliesContainerView.frame;
        frame.size.height = yOffset;
        self.repliesContainerView.frame = frame;
    } else {
        self.repliesContainerView.frame = CGRectMake(self.repliesContainerView.frame.origin.x,
                                                     self.repliesContainerView.frame.origin.y,
                                                     self.repliesContainerView.frame.size.width,
                                                     0);
    }
}


- (IBAction)openUserVCBtn:(id)sender {
    NSString *username = ((UIButton *)sender).accessibilityLabel ?: @"";
    
    UIViewController *userVC = [[NSClassFromString(@"UserViewController") alloc] initWithNibName:@"UserViewController" bundle:nil];
    
    if ([userVC respondsToSelector:@selector(setUsername:)]) {
        [userVC setValue:username forKey:@"username"];
    }
    
    UIResponder *responder = self;
    while (responder && ![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
    }
    
    if ([responder isKindOfClass:[UIViewController class]]) {
        UIViewController *parentVC = (UIViewController *)responder;
        [parentVC presentModalViewController:userVC animated:YES];
    }
}


- (IBAction)deleteBtnTapped:(id)sender {
    NSInteger postID = self.tag;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Post"
                                                    message:@"Are you sure you want to delete this post?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Delete", nil];
    alert.tag = postID;
    alert.delegate = self;
    [alert show];
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // "Delete"
        [self deletePostWithID:alertView.tag];
    }
}

- (void)deletePostWithID:(NSInteger)postID {
    NSString *urlStr = @"https://calvink19.co/services/rg/deletepost.php";
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    if (authToken) {
        [request setValue:authToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSDictionary *body = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:postID] forKey:@"id"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        NSLog(@"Error deleting post: %@", error);
        return;
    }
    
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([[jsonResponse objectForKey:@"success"] boolValue]) {
        NSLog(@"Post deleted successfully");
        
        // Find the parent VC and tell it to reload
        UIResponder *responder = self;
        while (responder && ![responder isKindOfClass:[UIViewController class]]) {
            responder = [responder nextResponder];
        }
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *parentVC = (UIViewController *)responder;
            if ([parentVC respondsToSelector:@selector(fetchPosts)]) {
                [parentVC performSelector:@selector(fetchPosts)];
            }
        }
        
    } else {
        NSLog(@"Delete failed: %@", [jsonResponse objectForKey:@"error"]);
    }
}

@end