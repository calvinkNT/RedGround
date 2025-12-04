//
//  PostDetailViewController.h
//  requesttesting
//
//  Created by CalvinK19 on 7/29/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) NSDictionary *postData;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *replyTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
- (IBAction)dismissBtn:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *lowerContainerView;
- (IBAction)replyBtnTapped:(id)sender;

@property (nonatomic, strong) NSMutableArray *replies;

@end
