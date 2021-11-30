//
//  ContactObject.m
//  zalo-contact
//
//  Created by Thiện on 29/11/2021.
//

#import "ContactObject.h"

@implementation ContactObject

- (instancetype)initWithContactEntity:(ContactEntity *)contact {
    self = [super initWithCellClass:[ContactCell class]];
    _contact = contact;
    return self;
}

@end