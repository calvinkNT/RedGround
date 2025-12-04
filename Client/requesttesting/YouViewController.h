//
//  YouViewController.h
//  requesttesting
//
//  Created by CalvinK19 on 8/2/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YouViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

//@property (strong, nonatomic) UIScrollView *scrollView;

//@property (nonatomic, strong) NSMutableArray *postViews;

@property (strong, nonatomic) IBOutlet UINavigationBar *titlebar;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (nonatomic, strong) NSString *currentPostsURL;
@property (nonatomic, strong) NSString *username;

@property (weak, nonatomic) IBOutlet UILabel *totalLikesLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalPostsLabel;

- (IBAction)dismissVCBtn:(id)sender;
- (IBAction)settingsBtn:(id)sender;

@end
