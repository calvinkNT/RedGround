//
//  NewPostViewController.h
//  requesttesting
//
//  Created by CalvinK19 on 8/3/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewPostViewController : UIViewController
- (IBAction)newPostBtn:(id)sender;
@property (weak, nonatomic) IBOutlet UINavigationBar *titlebar;
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (IBAction)clearBtn:(id)sender;

@end
