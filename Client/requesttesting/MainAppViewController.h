//
//  MainAppViewController.h
//  requesttesting
//
//  Created by CalvinK19 on 5/28/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainAppViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (IBAction)logoutBtn:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *loggedInAsLabel;
//@property (nonatomic, strong) NSMutableSet *likedPosts;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

//@property (strong, nonatomic) UIScrollView *scrollView;

//@property (nonatomic, strong) NSMutableArray *postViews;

- (IBAction)newPostBtn;
@property (strong, nonatomic) IBOutlet UINavigationBar *titlebar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *postTypeSelector;
- (IBAction)postTypeChanged:(UISegmentedControl *)sender;
@property (nonatomic, strong) NSString *currentPostsURL;

@end
