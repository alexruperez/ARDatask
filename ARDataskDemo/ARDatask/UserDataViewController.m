//
//  UserDataViewController.m
//  ARDatask
//
//  Created by alexruperez on 16/04/13.
//  Copyright (c) 2013 alexruperez. All rights reserved.
//

#import "UserDataViewController.h"

@interface UserDataViewController ()

@end

@implementation UserDataViewController

@synthesize name;
@synthesize email;
@synthesize phone;

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == name) {
        [name setTextColor:[UIColor blackColor]];
        [name resignFirstResponder];
        [email becomeFirstResponder];
    }
    if (textField == email) {
        [email setTextColor:[UIColor blackColor]];
        [email resignFirstResponder];
        [phone becomeFirstResponder];
    }
    if (textField == phone) {
        [phone setTextColor:[UIColor blackColor]];
        [phone resignFirstResponder];
        [self send:self];
    }
    return true;
}

- (IBAction)send:(id)sender
{
    if (!name.text || ([name.text length] <= 0)) {
        [name setTextColor:[UIColor redColor]];
        [name becomeFirstResponder];
        return;
    }
    if (!email.text || ([email.text length] <= 0)) {
        [email setTextColor:[UIColor redColor]];
        [email becomeFirstResponder];
        return;
    }
    if (!phone.text || ([phone.text length] <= 0)) {
        [phone setTextColor:[UIColor redColor]];
        [phone becomeFirstResponder];
        return;
    }
    // Save the user data
    [ARDatask setRequestCompleted:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
