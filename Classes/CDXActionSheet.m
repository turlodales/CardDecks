//
//
// CDXActionSheet.m
//
//
// Copyright (c) 2009-2015 Arne Harren <ah@0xc0.de>
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

#import "CDXDevice.h"
#import "CDXActionSheet.h"
#import "CDXImageFactory.h"
#import "CDXAppWindowManager.h"


#undef ql_component
#define ql_component lcl_cView


@interface CDXUIActionSheetNonFirstResponder : UIActionSheet {
    
}

@end


@implementation CDXUIActionSheetNonFirstResponder

- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end


@implementation CDXActionSheet

@synthesize tag;
@synthesize buttonIndexBase;
@synthesize delegate;
@synthesize visible;

- (void)configureWithAlertController:(UIAlertController *)ac {
    qltrace();
    ivar_assign_and_retain(alertController, ac);
    ivar_release_and_clear(actionSheet);
}

- (void)configureWithActionSheet:(UIActionSheet *)as {
    qltrace();
    ivar_release_and_clear(alertController);
    ivar_assign_and_retain(actionSheet, as);
}

- (void)dealloc {
    qltrace();
    ivar_release_and_clear(alertController);
    ivar_release_and_clear(actionSheet);
    [super dealloc];
}

- (void)buttonClickedAtIndex:(NSInteger)buttonIndex {
    NSInteger modifiedButtonIndex = buttonIndex - buttonIndexBase;
    qltrace(@"%ld - %ld = %ld", (long)buttonIndex, (long)buttonIndexBase, (long)modifiedButtonIndex);
    [delegate buttonClickedActionSheet:self buttonAtIndex:modifiedButtonIndex];
    visible = NO;
}

- (void)presentActionSheetCompleted {
    qltrace();
    visible = YES;
    [delegate presentActionSheetCompleted:self];
}

- (void)presentWithViewController:(UIViewController *)viewController fromBarButtonItem:(UIBarButtonItem *)barButtomItem animated:(BOOL)animated {
    qltrace();
    if (alertController != nil) {
        alertController.popoverPresentationController.barButtonItem = barButtomItem;
        [viewController presentViewController:alertController animated:animated completion:
         ^() {
             qltrace();
             [self presentActionSheetCompleted];
         }
         ];
    } else if (actionSheet != nil) {
        [actionSheet showFromBarButtonItem:barButtomItem animated:animated];
    }
}

- (void)presentWithViewController:(UIViewController *)viewController view:(UIView *)view animated:(BOOL)animated {
    qltrace();
    if (alertController != nil) {
        [viewController presentViewController:alertController animated:animated completion:
         ^() {
             qltrace();
             [self presentActionSheetCompleted];
         }
         ];
    } else if (actionSheet != nil) {
        [actionSheet showInView:view];
    }
}

- (void)dismissActionSheetAnimated:(BOOL)animated {
    qltrace();
    if (alertController != nil) {
        [alertController dismissViewControllerAnimated:animated completion:nil];
    } else if (actionSheet != nil) {
        [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:animated];
    }
    visible = NO;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    qltrace();
    [self buttonClickedAtIndex:buttonIndex];
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet {
    qltrace();
    [self presentActionSheetCompleted];
}

+ (CDXActionSheet *)actionSheetWithTitle:(NSString *)title tag:(NSInteger)tag delegate:(id<CDXActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles{
    qltrace();
    
    CDXActionSheet* cas = [[[CDXActionSheet alloc] init] autorelease];
    cas.buttonIndexBase = 0;
    cas.tag = tag;
    cas.delegate = delegate;
    if (([[[CDXDevice sharedDevice] deviceSystemVersionString] floatValue] >= 8.0) && [[CDXDevice sharedDevice] deviceUIIdiom] != CDXDeviceUIIdiomPhone) {
        // iOS 8 UIAlertController; for now on iPad only
        qltrace(@"UIAlertController");
        UIAlertController* ac = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [cas configureWithAlertController:ac];
        NSInteger index = 0;
        for (NSString *buttonTile in otherButtonTitles) {
            [ac addAction:[UIAlertAction actionWithTitle:buttonTile style:UIAlertActionStyleDefault handler:
                           ^(UIAlertAction * action) {
                               qltrace(@"%ld", (long)index);
                               [cas buttonClickedAtIndex:index];
                           }
                           ]
             ];
            ++index;
        }
        
        [ac addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:
                       ^(UIAlertAction * action) {
                           qltrace(@"cancel: -1");
                           [cas buttonClickedAtIndex:index];
                       }
                       ]
         ];
    } else {
        // iOS 7 UIActionSheet
        qltrace(@"UIActionSheet");
        UIActionSheet *as = [[[CDXUIActionSheetNonFirstResponder alloc] initWithTitle:title delegate:cas cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
        [cas configureWithActionSheet:as];
        
        NSInteger index = 0;
        for (NSString *buttonTile in otherButtonTitles) {
            NSInteger buttonIndex = [as addButtonWithTitle:buttonTile];
            if (index == 0) {
                cas.buttonIndexBase = buttonIndex;
            }
            ++index;
        }
        [as addButtonWithTitle:cancelButtonTitle];
        as.cancelButtonIndex = index;
    }
    return cas;
}

@end

