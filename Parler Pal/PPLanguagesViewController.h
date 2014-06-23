//
//  PPLanguagesViewController.h
//  Parler Pal
//
//  Created by Aaron Vizzini on 6/18/14.
//  Copyright (c) 2014 Aaron Vizzini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPLanguageTableViewCell.h"

@interface PPLanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PPLanguageTableViewCellDelegate>
{
    IBOutlet UITableView *table;
    NSArray *languages;
    
    NSArray *allUserLanguages;
}
@property(nonatomic, strong) IBOutlet UITableView *table;

@end
