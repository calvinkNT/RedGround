//
//  ViewController.h
//  requesttesting
//
//  Created by CalvinK19 on 5/28/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

//signp
- (IBAction)makeSuReq:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *userSuTextField;
@property (weak, nonatomic) IBOutlet UITextField *passSuTextField;

//login
- (IBAction)makeLiReq:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *userLiTextField;
@property (weak, nonatomic) IBOutlet UITextField *passLiTextField;

// spin
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIView *loadingOverlay;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *loadingLabel;

@property (nonatomic, strong) NSURLConnection *loginConnection;
@property (nonatomic, strong) NSMutableData *loginConnectionData;

- (IBAction)termsBtn:(id)sender;
- (IBAction)conditionsBtn:(id)sender;
@property (nonatomic, strong) IBOutlet UILabel *motdLabel;

@end


