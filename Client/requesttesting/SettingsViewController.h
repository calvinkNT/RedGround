//
//  SettingsViewController.h
//  requesttesting
//
//  Created by CalvinK19 on 7/19/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
- (IBAction)logoutBtn:(id)sender;
- (IBAction)dismissBtn:(id)sender;
- (IBAction)termsBtn:(id)sender;
- (IBAction)conditionsBtn:(id)sender;

@end
