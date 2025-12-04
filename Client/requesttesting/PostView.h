#import <UIKit/UIKit.h>

@interface PostView : UIView

// all are linked correctly.
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UITextField *replyField;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;

@property (nonatomic, strong) NSArray *replies;
@property (weak, nonatomic) IBOutlet UIView *repliesContainerView;

+ (instancetype)loadFromNib;
- (void)configureWithPost:(NSDictionary *)post target:(id)target;
@property (weak, nonatomic) IBOutlet UIView *lowerContainerView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *authorBtn;
- (IBAction)openUserVCBtn:(id)sender;
- (IBAction)infoBtn:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
- (IBAction)deleteBtnTapped:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@end
