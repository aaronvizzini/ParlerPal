//
//  PPViewController.h
//  Parler Pal
//
//  Created by Aaron Vizzini on 6/8/14.
//  Copyright (c) 2014 Aaron Vizzini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPMainViewController.h"

@interface PPLoginViewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>
{
    int languageIndex;
    NSArray *welcomeLanguages;
    NSTimer *timer;
}
@property (nonatomic, weak) IBOutlet UITextField *userName, *password;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UILabel *welcomeMessage;
@property (nonatomic, weak) IBOutlet UISwitch *savePassword;

//Check if login credentials are correct
-(IBAction)login:(id)sender;

//Text field action methods for when fields did return
-(IBAction)userFieldDidReturn:(id)sender;
-(IBAction)passwordFieldDidReturn:(id)sender;

//Create an account button action
-(IBAction)createAccount:(id)sender;

//Save password or not...
-(IBAction)switchSelected:(id)sender;

-(IBAction)unwindToLogin:(UIStoryboardSegue *)segue;
@end
