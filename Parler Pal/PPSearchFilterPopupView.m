//
//  PPSearchFilterPopupView.m
//  Parler Pal
//
//  Created by Aaron Vizzini on 7/10/14.
//  Copyright (c) 2014 Aaron Vizzini. All rights reserved.
//

#import "PPSearchFilterPopupView.h"

@implementation PPSearchFilterPopupView
@synthesize view, usernameField, genderSegment, minAgeLabel, maxAgeLabel, minStepper, maxStepper, delegate, palRating;

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - setup methods

-(void)setup
{
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    [[NSBundle mainBundle]loadNibNamed:@"PPSearchFilterPopupView" owner:self options:nil];
    [self addSubview:self.view];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, screenSize.size.width, self.view.frame.size.height);
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    self.layer.shadowOffset = CGSizeMake(-3, 3);
    self.layer.shadowRadius = 2;
    self.layer.shadowOpacity = 0.4;
}

#pragma mark - action methods

-(void)show
{
    [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.frame = CGRectMake(self.view.frame.origin.x, 0, self.view.frame.size.width, self.view.frame.size.height);
    } completion:nil];
}

-(IBAction)hide:(id)sender
{
    [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.frame = CGRectMake(self.view.frame.origin.x, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        
        if(delegate)
        {
            if([delegate respondsToSelector:@selector(didFinishFiltering)])
            {
                [self.delegate didFinishFiltering];
            }
        }
    }];
}

-(IBAction)minStepper:(id)sender
{
    UIStepper *stepper = (UIStepper *)sender;
    
    if(stepper.value >= maxStepper.value)
    {
        maxStepper.value = stepper.value;
    }
    
    minAgeLabel.text = [NSString stringWithFormat:@"%i",(int)minStepper.value];
    maxAgeLabel.text = [NSString stringWithFormat:@"%i",(int)maxStepper.value];
}

-(IBAction)maxStepper:(id)sender
{
    UIStepper *stepper = (UIStepper *)sender;
    
    if(stepper.value <= minStepper.value)
    {
        minStepper.value = stepper.value;
    }
    
    minAgeLabel.text = [NSString stringWithFormat:@"%i",(int)minStepper.value];
    maxAgeLabel.text = [NSString stringWithFormat:@"%i",(int)maxStepper.value];
}

#pragma mark - UITextiField delegate methods

-(IBAction)fieldDidEndEditing:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    if(textField == self.palRating)
    {
        NSString *regex = @"^(\\+|-)?\\d+$";
        NSPredicate *numPred = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", regex];
        
        if(![numPred evaluateWithObject:textField.text])
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error!" message:@"Positive or negative integers only." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            [alert show];
            textField.text = @"";
        }
    }
    
    [textField resignFirstResponder];
}

@end
