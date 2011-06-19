//
//
// CDXCardDeckListViewController.m
//
//
// Copyright (c) 2009-2011 Arne Harren <ah@0xc0.de>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "CDXCardDeckListViewController.h"
#import "CDXCardDeckCardViewController.h"
#import "CDXCardDeckCardEditViewController.h"
#import "CDXSettingsViewController.h"
#import "CDXImageFactory.h"
#import "CDXCardDecks.h"
#import "CDXCardDeckURLSerializer.h"
#import "CDXAppSettings.h"

#undef ql_component
#define ql_component lcl_cController


@implementation CDXCardDeckListViewController

- (id)initWithCardDeckViewContext:(CDXCardDeckViewContext *)aCardDeckViewContext {
    if ((self = [super initWithNibName:@"CDXCardDeckListView" bundle:nil titleText:aCardDeckViewContext.cardDeck.name backButtonText:@"Cards"])) {
        ivar_assign_and_retain(cardDeckViewContext, aCardDeckViewContext);
        ivar_assign_and_retain(cardDeck, aCardDeckViewContext.cardDeck);
        viewWasAlreadyVisible = NO;
    }
    return self;
}

- (void)dealloc {
    ivar_release_and_clear(cardDeckViewContext);
    ivar_release_and_clear(cardDeck);
    ivar_release_and_clear(shuffleButton);
    ivar_release_and_clear(actionButton);
    ivar_release_and_clear(activeActionSheet);
    [super dealloc];
}

- (void)viewDidUnload {
    ivar_release_and_clear(shuffleButton);
    ivar_release_and_clear(actionButton);
    ivar_release_and_clear(activeActionSheet);
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = cardDeckViewContext.cardDeck.name;
    if ([viewTableView numberOfRowsInSection:1] != 0) {
        [viewTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:cardDeckViewContext.currentCardIndex inSection:1] atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([cardDeck isShuffled]) {
        if (!viewWasAlreadyVisible) {
            [[CDXAppWindowManager sharedAppWindowManager] showNoticeWithImageNamed:@"Notice-Shuffle.png" text:@"shuffle" timeInterval:0.4 orientation:UIDeviceOrientationFaceUp];
        }
    }
    viewWasAlreadyVisible = YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        default:
        case 0:
            return 0;
        case 1:
            return [cardDeck cardsCount];
        case 2:
            return 1;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    if (indexPath.section == 1) {
        NSUInteger groupSize = [cardDeck groupSize];
        if (groupSize > 0 && (indexPath.row / groupSize) % 2 == 0) {
            cell.backgroundColor = tableCellBackgroundColorAltGroup;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifierSection1 = @"Section1Cell";
    static NSString *reuseIdentifierSection2 = @"Section2Cell";
    switch (indexPath.section) {
        default:
        case 0: {
            return nil;
        }
        case 1: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifierSection1];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifierSection1] autorelease];
                cell.textLabel.font = tableCellTextFont;
                cell.textLabel.textColor = tableCellTextTextColor;
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            
            CDXCard *card = [cardDeck cardAtIndex:indexPath.row];
            cell.textLabel.text = card.text;
            cell.imageView.image = [[CDXImageFactory sharedImageFactory] imageForColor:card.backgroundColor size:tableCellImageSize];
            return cell;
        }
        case 2: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifierSection2];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifierSection2] autorelease];
                cell.textLabel.font = tableCellTextFontAction;
                cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
            }
            
            cell.textLabel.textColor = self.editing ? tableCellTextTextColorActionInactive : tableCellTextTextColorAction;
            switch (indexPath.row) {
                default:
                case 0: {
                    cell.textLabel.text = @"  CARD DEFAULTS";
                    break;
                }
            }
            
            return cell;
        }
    }
}

- (void)pushCardDeckCardViewController {
    CDXCardDeckCardViewController *vc = [[[CDXCardDeckCardViewController alloc] initWithCardDeckViewContext:cardDeckViewContext] autorelease];
    [[CDXAppWindowManager sharedAppWindowManager] pushViewController:vc animated:YES];
    
    [viewTableView deselectRowAtIndexPath:[viewTableView indexPathForSelectedRow] animated:YES];
    [self performBlockingSelectorEnd];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL deselectRow = YES;
    switch (indexPath.section) {
        default:
        case 0: {
            break;
        }
        case 1: {
            cardDeckViewContext.currentCardIndex = indexPath.row;
            [self performBlockingSelector:@selector(pushCardDeckCardViewController)
                               withObject:nil];
            deselectRow = NO;
            break;
        }
        case 2: {
            switch (indexPath.row) {
                default:
                case 0: {
                    [self defaultsButtonPressed];
                    deselectRow = NO;
                    break;
                }
            }
        }
    }
    if (deselectRow) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)pushCardDeckEditViewController {
    CDXCardDeckCardEditViewController *vc = [[[CDXCardDeckCardEditViewController alloc] initWithCardDeckViewContext:cardDeckViewContext editDefaults:NO] autorelease];
    [[CDXAppWindowManager sharedAppWindowManager] pushViewController:vc animated:YES];
    [self performBlockingSelectorEnd];
}

- (void)pushCardDeckEditViewControllerForDefaults {
    CDXCardDeckCardEditViewController *vc = [[[CDXCardDeckCardEditViewController alloc] initWithCardDeckViewContext:cardDeckViewContext editDefaults:YES] autorelease];
    [[CDXAppWindowManager sharedAppWindowManager] pushViewController:vc animated:YES];
    [self performBlockingSelectorEnd];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    cardDeckViewContext.currentCardIndex = indexPath.row;
    [self performBlockingSelector:@selector(pushCardDeckEditViewController)
                       withObject:NO];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [cardDeck removeCardAtIndex:indexPath.row];
        [cardDeckViewContext updateStorageObjectsDeferred:YES];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateToolbarButtons];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    qltrace();
    [cardDeck moveCardAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
    [cardDeckViewContext updateStorageObjectsDeferred:YES];
    
    [viewTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
}

- (void)updateShuffleButton {
    if ([cardDeck isShuffled]) {
        shuffleButton.image = [UIImage imageNamed:@"Toolbar-Sort.png"];
    } else {
        shuffleButton.image = [UIImage imageNamed:@"Toolbar-Shuffle.png"];
    }
    shuffleButton.enabled = ([self tableView:viewTableView numberOfRowsInSection:1] != 0);
}

- (void)updateToolbarButtons {
    [super updateToolbarButtons];
    [self updateShuffleButton];
    actionButton.enabled = ([self tableView:viewTableView numberOfRowsInSection:1] != 0);
}

- (IBAction)addButtonPressedDelayed {
    CDXCard *card = [cardDeck cardWithDefaults];
    [cardDeck addCard:card];
    [cardDeckViewContext updateStorageObjectsDeferred:YES];
    
    cardDeckViewContext.currentCardIndex = [cardDeck cardsCount]-1;
    NSIndexPath *path = [NSIndexPath indexPathForRow:cardDeckViewContext.currentCardIndex inSection:1];
    [viewTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    [viewTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    [viewTableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
    [viewTableView deselectRowAtIndexPath:path animated:YES];
    [self updateToolbarButtons];
}

- (IBAction)addButtonPressed {
    if (![[viewTableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:2]] ||
        [viewTableView isEditing]) {
        qltrace();
        [self setEditing:NO animated:YES];
        [viewTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionNone animated:YES];
        [self performSelector:@selector(addButtonPressedDelayed) withObject:nil afterDelay:0.3];
    } else {
        [self addButtonPressedDelayed];
    }
}

- (IBAction)defaultsButtonPressed {
    qltrace();
    cardDeckViewContext.currentCardIndex = [cardDeck cardsCount]-1;
    [self performBlockingSelector:@selector(pushCardDeckEditViewControllerForDefaults)
                       withObject:NO];
}

- (IBAction)settingsButtonPressed {
    qltrace();
    CDXCardDeckSettings *settings = [[[CDXCardDeckSettings alloc] initWithCardDeck:cardDeck] autorelease];
    CDXSettingsViewController *vc = [[[CDXSettingsViewController alloc] initWithSettings:settings] autorelease];
    [self presentModalViewController:vc animated:YES];
}

- (IBAction)shuffleButtonPressed {
    if ([cardDeck isShuffled]) {
        [cardDeck sort];
        [[CDXAppWindowManager sharedAppWindowManager] showNoticeWithImageNamed:@"Notice-Sort.png" text:@"sort" timeInterval:0.4 orientation:UIDeviceOrientationFaceUp];
    } else {
        [cardDeck shuffle];
        [[CDXAppWindowManager sharedAppWindowManager] showNoticeWithImageNamed:@"Notice-Shuffle.png" text:@"shuffle" timeInterval:0.4 orientation:UIDeviceOrientationFaceUp];
    }
    [cardDeck updateStorageObjectDeferred:YES];
    
    [self updateShuffleButton];
    [viewTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)dismissActionSheet {
    if (activeActionSheet != nil) {
        [activeActionSheet dismissWithClickedButtonIndex:[activeActionSheet cancelButtonIndex] animated:NO];
        ivar_release_and_clear(activeActionSheet);
    }
}

- (IBAction)actionButtonPressed {
    UIActionSheet *actionSheet = [[[UIActionSheet alloc]
                                   initWithTitle:nil
                                   delegate:self
                                   cancelButtonTitle:@"Cancel"
                                   destructiveButtonTitle:nil
                                   otherButtonTitles:@"Email Deck", @"Duplicate Deck", nil]
                                  autorelease];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    if (activeActionSheet != nil) {
        [self dismissActionSheet];
        // don't open a new sheet, just closed the same one
        return;
    }
    [[CDXAppWindowManager sharedAppWindowManager] showActionSheet:actionSheet fromBarButtonItem:actionButton];
    ivar_assign_and_retain(activeActionSheet, actionSheet);
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    qltrace();
    ivar_release_and_clear(activeActionSheet);
    switch (buttonIndex) {
        default:
            break;
        case 0: {
            NSString *body = [@"carddecks:///2/add?" stringByAppendingString:[CDXCardDeckURLSerializer version2StringFromCardDeck:cardDeck]];
            if ([[CDXAppSettings sharedAppSettings] useMailApplication] || ![MFMailComposeViewController canSendMail]) {
                NSString *urlString = [NSString stringWithFormat:@"mailto:?&subject=%@&body=%@",
                                       [[cardDeck.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                        stringByReplacingOccurrencesOfString:@"&" withString:@"%26"],
                                       [[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                        stringByReplacingOccurrencesOfString:@"&" withString:@"%26"]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
            } else {
                MFMailComposeViewController *vc = [[[MFMailComposeViewController alloc] init] autorelease];
                [vc setMailComposeDelegate:self];
                [vc setSubject:cardDeck.name];
                [vc setMessageBody:[body stringByAppendingString:@" "] isHTML:NO];
                [[CDXKeyboardExtensions sharedKeyboardExtensions] setEnabled:NO];
                [self presentModalViewController:vc animated:YES];
            }
            break;
        }
        case 1: {
            CDXCardDeck *deck = [[cardDeck copy] autorelease];
            deck.name = [deck.name stringByAppendingString:@" - Copy"];
            [deck updateStorageObjectDeferred:NO];
            CDXCardDeckHolder *holder = [CDXCardDeckHolder cardDeckHolderWithCardDeck:deck];
            [cardDeckViewContext.cardDecks addPendingCardDeckAdd:holder];
            [[CDXAppWindowManager sharedAppWindowManager] popViewControllerAnimated:YES];
            break;
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [controller dismissModalViewControllerAnimated:YES];
    [[CDXKeyboardExtensions sharedKeyboardExtensions] setEnabled:YES];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    qltrace();
    [super dismissModalViewControllerAnimated:animated];
    [self dismissActionSheet];
}

@end

