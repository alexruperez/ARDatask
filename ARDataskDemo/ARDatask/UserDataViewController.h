//
//  UserDataViewController.h
//  ARDatask
//
//  Created by alexruperez on 16/04/13.
//  Copyright (c) 2013 alexruperez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserDataViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField *name;
@property (nonatomic, strong) IBOutlet UITextField *email;
@property (nonatomic, strong) IBOutlet UITextField *phone;

@end
