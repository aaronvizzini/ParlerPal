//
//  PPTopReplaceSegue.m
//  Parler Pal
//
//  Created by Aaron Vizzini on 6/18/14.
//  Copyright (c) 2014 Aaron Vizzini. All rights reserved.
//

#import "PPTopReplaceSegue.h"

@implementation PPTopReplaceSegue

-(void)perform
{
    UIViewController *dst = [self destinationViewController];
    UIViewController *src = [self sourceViewController];
    
    [src.view setUserInteractionEnabled:NO];
    
    [dst viewWillAppear:NO];
    [dst viewDidAppear:NO];
    
    [src.view addSubview:dst.view];
    
    dst.view.frame = CGRectMake(0, -1 * dst.view.frame.size.height, dst.view.frame.size.width, dst.view.frame.size.height);
    src.view.frame = CGRectMake(0, 0, src.view.frame.size.width, src.view.frame.size.height);
    
    [UIView beginAnimations:nil context:nil];
    
    dst.view.layer.speed = .5;
    dst.view.frame = CGRectMake(0, -1 * dst.view.frame.size.height, dst.view.frame.size.width, dst.view.frame.size.height);

    src.view.layer.speed = .5;
    src.view.frame = CGRectMake(0, src.view.frame.size.height, src.view.frame.size.width, src.view.frame.size.width);
    [UIView commitAnimations];
    
    [self performSelector:@selector(animationDone:) withObject:dst afterDelay:.6f];
}

- (void)animationDone:(id)vc
{
    UIViewController *dst = (UIViewController*)vc;
    UINavigationController *nav = [[self sourceViewController] navigationController];
    
    [nav popViewControllerAnimated:NO];
    [nav pushViewController:dst animated:NO];
    [dst.view setUserInteractionEnabled:YES];
}

@end
