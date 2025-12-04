#import "PostDetailViewController.h"
#import "SetBG.h"
@implementation PostDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyRepeatingBackground];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.replyTextField.delegate = self;
    self.replyTextField.returnKeyType = UIReturnKeyDone;
    
    self.replies = [NSMutableArray array];
    
    self.usernameLabel.text = [self.postData objectForKey:@"username"];
    self.messageLabel.text = [self.postData objectForKey:@"message"];
    
    [self adjustMessageLabelHeight];
    
    NSInteger likeCount = [[self.postData objectForKey:@"likes"] integerValue];
    [self.likeButton setTitle:[NSString stringWithFormat:@"%ld ❤️", (long)likeCount] forState:UIControlStateNormal];
    [self.likeButton addTarget:self action:@selector(likeTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self fetchReplies];
}

#pragma mark - Popup
- (void)showUIPopup:(NSString *)title :(NSString *)contents {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:contents
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.replyTextField) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

#pragma mark - Adjust message label
- (void)adjustMessageLabelHeight {
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    CGSize maxSize = CGSizeMake(self.messageLabel.frame.size.width, CGFLOAT_MAX);
    CGSize neededSize = [self.messageLabel sizeThatFits:maxSize];
    
    CGRect msgFrame = self.messageLabel.frame;
    msgFrame.size.height = neededSize.height;
    self.messageLabel.frame = msgFrame;
    
    CGRect lowerFrame = self.lowerContainerView.frame;
    lowerFrame.origin.y = CGRectGetMaxY(self.messageLabel.frame) + 0;
    self.lowerContainerView.frame = lowerFrame;
}

#pragma mark - Like button
- (void)likeTapped:(UIButton *)sender {
    NSInteger postID = [[self.postData objectForKey:@"id"] integerValue];
    sender.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
        NSString *urlStr = [NSString stringWithFormat:
                            @"https://calvink19.co/services/rg/like.php?id=%ld&username=%@",
                            (long)postID, username];
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
        NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
        if (authToken) [req setValue:authToken forHTTPHeaderField:@"Authorization"];
        
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
        NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            if (!responseStr) return;
            
            NSInteger currentCount = [[self.postData objectForKey:@"likes"] integerValue];
            if ([responseStr isEqualToString:@"Liked"]) {
                currentCount++;
            } else if ([responseStr isEqualToString:@"Unliked"]) {
                currentCount = MAX(currentCount - 1, 0);
            }
            
            NSMutableDictionary *mutablePost = [self.postData mutableCopy];
            [mutablePost setObject:[NSNumber numberWithInteger:currentCount] forKey:@"likes"];
            self.postData = mutablePost;
            
            [self.likeButton setTitle:[NSString stringWithFormat:@"%ld ❤️", (long)currentCount] forState:UIControlStateNormal];
        });
    });
}

#pragma mark - Fetch replies
- (void)fetchReplies {
    NSInteger postID = [[self.postData objectForKey:@"id"] integerValue];
    NSString *urlStr = [NSString stringWithFormat:@"https://calvink19.co/services/rg/get_replies.php?id=%ld", (long)postID];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    if (authToken) [req setValue:authToken forHTTPHeaderField:@"Authorization"];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    if (!data) return;
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([jsonDict isKindOfClass:[NSDictionary class]]) {
        NSNumber *count = [jsonDict objectForKey:@"count"];
        NSArray *repliesArray = [jsonDict objectForKey:@"replies"];
        NSLog(@"%@", repliesArray);

        if ([count isKindOfClass:[NSNumber class]]) {
            NSMutableDictionary *mutablePost = [self.postData mutableCopy];
            [mutablePost setObject:count forKey:@"replyCount"];
            self.postData = mutablePost;
            
            [self.sendButton setTitle:[NSString stringWithFormat:@"%ld 💬", (long)[count integerValue]] forState:UIControlStateNormal];
        }
        
        if ([repliesArray isKindOfClass:[NSArray class]]) {
            [self.replies removeAllObjects];
            [self.replies addObjectsFromArray:repliesArray];
            [self.tableView reloadData];
            [self scrollToBottom];
        }
    }
}

#pragma mark - Send reply
- (IBAction)replyBtnTapped:(id)sender {
    NSString *text = self.replyTextField.text;
    if (text.length == 0) return;
    
    NSInteger postID = [[self.postData objectForKey:@"id"] integerValue];
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    NSString *encodedText = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlStr = [NSString stringWithFormat:
                        @"https://calvink19.co/services/rg/reply.php?id=%ld&text=%@&username=%@",
                        (long)postID, encodedText, username];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    if (authToken) [req setValue:authToken forHTTPHeaderField:@"Authorization"];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    
    if (data) {
        self.replyTextField.text = @"";
        
        NSDictionary *newReply = @{
                                   @"username": username ?: @"",
                                   @"text": text ?: @""
                                   };
        [self.replies addObject:newReply];
        
        NSInteger currentCount = [[self.postData objectForKey:@"replyCount"] integerValue];
        currentCount++;
        
        NSMutableDictionary *mutablePost = [self.postData mutableCopy];
        [mutablePost setObject:[NSNumber numberWithInteger:currentCount] forKey:@"replyCount"];
        self.postData = mutablePost;
        
        //[self.sendButton setTitle:[NSString stringWithFormat:@"%ld 💬", (long)currentCount] forState:UIControlStateNormal];
        
        [self.tableView reloadData];
        [self scrollToBottom];
    }
}

#pragma mark - Scroll to bottom
- (void)scrollToBottom {
    if (self.replies.count == 0) return;
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.replies.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.replies.count > 0) ? self.replies.count : 1; 
}

#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"ReplyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    if (self.replies.count == 0) {
        // Placeholder
        cell.textLabel.text = @"No replies";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        // actual replies
        NSDictionary *reply = [self.replies objectAtIndex:indexPath.row];
        cell.textLabel.text = [reply objectForKey:@"username"];
        cell.detailTextLabel.text = [reply objectForKey:@"text"];
        cell.detailTextLabel.numberOfLines = 0;
        //cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    return cell;
}


#pragma mark - Dismiss
- (IBAction)dismissBtn:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload {
    [self setSendButton:nil];
    [super viewDidUnload];
}
@end