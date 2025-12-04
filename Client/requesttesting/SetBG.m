//
//  SetBG.m
//  requesttesting
//
//  Created by CalvinK19 on 8/4/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "SetBG.h"

@implementation UIViewController (Background)

- (void)applyRepeatingBackground {
    UIImage *bgImage = [UIImage imageNamed:@"backgroundStage.png"];
    
    UIColor *bgColor = [UIColor colorWithPatternImage:bgImage];
    
    self.view.backgroundColor = bgColor;
}

@end
