//
//  BlankFooterCell.m
//  zalo-contact
//
//  Created by Thiện on 24/11/2021.
//

#import "BlankFooterView.h"

@implementation BlankFooterView {
    UIView *separateLine;
}

- (instancetype)init {
    self = [super init];
    [self setBackgroundColor: UIColor.zaloLightGrayColor];    
    return self;
}

+ (CGFloat)heightForFooterWithObject:(FooterObject *)object {
    return 6;
}

- (void)setNeedsObject:(nonnull FooterObject *)object {
    return;
}

@end
