//
//  PPMessagesComposeViewController.m
//  Parler Pal
//
//  Created by Aaron Vizzini on 6/26/14.
//  Copyright (c) 2014 Aaron Vizzini. All rights reserved.
//

#import "PPMessagesComposeViewController.h"
#import "SWRevealViewController.h"
#import "PPDatabaseManager.h"
#import "PPPal.h"
#import "PPDataShare.h"
#import "PPDraft.h"

#define kAudioTimeLimit 60

@implementation PPMessagesComposeViewController
@synthesize revealButton, toField, subjectField, messageBox, lm, deleteButton, stopButton, playButton, recordButton, currDraftID, toolbarTitle;

#pragma mark - View Methods

-(void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    [self.revealButton setTarget: self.revealViewController];
    [self.revealButton setAction: @selector( revealToggle: )];
    [self.view addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    self.revealViewController.panGestureRecognizer.delegate = self;
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    tapRec.delegate = self;
    [self.view addGestureRecognizer:tapRec];
    
    if(!self.lm)self.lm = [CLLocationManager new];
    self.lm.delegate = self;
    self.lm.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.lm.distanceFilter = 10.0f;
    self.lm.headingFilter = 5;
    [self.lm startUpdatingLocation];
    
    [[PPDatabaseManager sharedDatabaseManager]getAllPalsCompletionHandler:^(NSMutableArray *results) {
        pals = results;
    }];
    
    autoCompletePals = [[NSMutableArray alloc]initWithArray:pals];
    
    autocompleteTableView = [[UITableView alloc] initWithFrame:
                             CGRectMake(0, toField.frame.origin.y+toField.frame.size.height, 320, 120) style:UITableViewStylePlain];
    autocompleteTableView.delegate = self;
    autocompleteTableView.dataSource = self;
    autocompleteTableView.scrollEnabled = YES;
    autocompleteTableView.hidden = YES;
    autocompleteTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper"]];
    autocompleteTableView.alpha = .9;
    [self.view addSubview:autocompleteTableView];
    
    [self setUpAudio];
    
    self.currDraftID = -1;
    
    //If we are working with a draft.
    if([[PPDataShare sharedSingleton]draft])
    {
        __weak PPDraft *currDraft = [[PPDataShare sharedSingleton]draft];
        
        self.currDraftID = currDraft.dbID;
        self.toField.text = currDraft.to;
        self.subjectField.text = currDraft.subject;
        self.messageBox.text = currDraft.message;
        self.toolbarTitle.title = @"Drafted Message";
        //int memoID = currDraft.memoID;
        
        [[PPDataShare sharedSingleton]setDraft:nil];
    }
}

-(void)setUpAudio
{
    audioMessageRecorded = NO;
    
    self.stopButton.enabled = NO;
    self.playButton.enabled = NO;
    self.deleteButton.enabled = NO;
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    NSURL *soundFileURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:@"audioMessages/tempAudioMessage.m4a"]];
    
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt: 1], AVNumberOfChannelsKey, [NSNumber numberWithFloat:12000.0], AVSampleRateKey, [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,nil];
    
    NSError *error = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [self.audioRecorder prepareToRecord];
    }
}

#pragma mark - Core Location Delegate Method

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.location = [locations objectAtIndex:0];
}

#pragma mark - gesture methods

-(void)tap:(UITapGestureRecognizer *)tapRec
{
    [[self view] endEditing: YES];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if([touch.view isKindOfClass:[UIControl class]] || [touch.view isKindOfClass:[UITextView class]] || CGRectIntersectsRect(CGRectMake([touch locationInView:autocompleteTableView].x, [touch locationInView:autocompleteTableView].y, autocompleteTableView.frame.size.width, autocompleteTableView.frame.size.height), autocompleteTableView.frame)
) {
        return NO; // ignore the touch
    }

    return YES; // handle the touch
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Action Methods

-(IBAction)textFieldDidReturn:(id)sender
{
    [[self view] endEditing: YES];
}

-(IBAction)sendButton:(id)sender
{
    if(toField.text.length <= 0)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Can't Send Message" message:@"Please choose a recipient." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    else if(subjectField.text.length <= 0)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Can't Send Message" message:@"A message needs a subject!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    else if(messageBox.text.length <= 0)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Can't Send Message" message:@"A message needs content!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    if(![self isAValidPal])
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:[NSString stringWithFormat:@"%@: I'm not your friend, buddy.",toField.text] message:@"You can only send messages to those you are friends with." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    //If there is a draft delete it from the server since its being sent and no longer a draft.
    if(self.currDraftID != -1)
    {
        [[PPDatabaseManager sharedDatabaseManager]deleteDraftByID:self.currDraftID completionHandler:^(bool success) {
        }];
    }
    
    [[PPDatabaseManager sharedDatabaseManager]submitMessageTo:toField.text subject:subjectField.text andMessage:messageBox.text location: self.location sendMemo:audioMessageRecorded completionHandler:^(bool success) {
        subjectField.text = @"";
        messageBox.text = @"";
        
        self.stopButton.enabled = NO;
        self.playButton.enabled = NO;
        self.deleteButton.enabled = NO;
    }];
}

-(IBAction)saveButton:(id)sender
{
   [[PPDatabaseManager sharedDatabaseManager]submitDraftWithTo:toField.text subject:subjectField.text message:messageBox.text andMemoID:0 draftID:self.currDraftID completionHandler:^(bool success, int draftID) {
       self.currDraftID = draftID;
       
       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Draft Saved" message:@"The draft has been saved, keep in mind that any audio recordings are not saved." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
       [alert show];
   }];
}

-(IBAction)recordAudio:(id)sender
{
    if (!self.audioRecorder.recording)
    {
        //We want to limit audio recordings to a certain amount of time
        [self performSelector:@selector(stopAudio:) withObject:nil afterDelay:kAudioTimeLimit];
        
        audioMessageRecorded = YES;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        self.playButton.enabled = NO;
        self.stopButton.enabled = YES;
        [self.audioRecorder record];
    }
}

-(IBAction)playAudio:(id)sender
{
    if (!self.audioRecorder.recording)
    {
        self.stopButton.enabled = YES;
        self.recordButton.enabled = NO;
        
        NSError *error;
        
        self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:self.audioRecorder.url error:&error];
        self.audioPlayer.delegate = self;
        
        if (error)
            NSLog(@"Error: %@", [error localizedDescription]);
        else
            [self.audioPlayer play];
    }
}

-(IBAction)stopAudio:(id)sender
{
    //Cancel the previous selector call no matter what, since if the user hits stop before the time limit manually stops it we don't want this called again.
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    self.stopButton.enabled = NO;
    self.playButton.enabled = YES;
    self.recordButton.enabled = YES;
    self.deleteButton.enabled = YES;
    
    if (self.audioRecorder.recording)
    {
        [self.audioRecorder stop];
    } else if (self.audioPlayer.playing) {
        [self.audioPlayer stop];
    }
}

-(IBAction)deleteAudio:(id)sender
{
    audioMessageRecorded = NO;
    
    self.stopButton.enabled = NO;
    self.playButton.enabled = NO;
    self.deleteButton.enabled = NO;
}


#pragma mark - AVAudio delegate methods

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.recordButton.enabled = YES;
    self.stopButton.enabled = NO;
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"CALL");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

#pragma mark - textfield delegate methods

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField == self.subjectField)return;
    
    autocompleteTableView.hidden = YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField == self.subjectField)return YES;
    
    autocompleteTableView.hidden = NO;
    
    NSString *substring = [NSString stringWithString:textField.text];
    substring = [substring stringByReplacingCharactersInRange:range withString:string];
    [self searchAutocompleteEntriesWithSubstring:substring];
    return YES;
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    [autoCompletePals removeAllObjects];
    
    for(PPPal *curPal in pals)
    {
        NSRange substringRange = [curPal.username rangeOfString:substring];
        
        if (substringRange.location == 0 || [substring isEqualToString:@""])
        {
            [autoCompletePals addObject:curPal];
        }
    }
    [autocompleteTableView reloadData];
}

#pragma mark - table view delegate methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count =[autoCompletePals count];
    
    if(count > 0)tableView.hidden = NO;
    else tableView.hidden = YES;
    
    return count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Pal";
    
    UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:@"Noteworthy" size:25];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    PPPal *pal = [autoCompletePals objectAtIndex:indexPath.row];
    cell.textLabel.text = pal.username;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView  willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    toField.text = selectedCell.textLabel.text;
    tableView.hidden = YES;
    [[self view] endEditing: YES];
}

#pragma mark - valid user check

-(BOOL)isAValidPal
{
    for(PPPal *pal in pals)
    {
        if([pal.username isEqualToString:toField.text])
        {
            return YES;
        }
    }
    
    return NO;
}
@end
