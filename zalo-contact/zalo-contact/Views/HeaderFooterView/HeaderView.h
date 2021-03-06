//
//  ContactSectionCell.h
//  zalo-contact
//
//  Created by Thiện on 16/11/2021.
//

@import Foundation;
@import UIKit;
@import PureLayout;
#import "CommonHeaderAndFooterViews.h"

NS_ASSUME_NONNULL_BEGIN

@interface HeaderView : UITableViewHeaderFooterView<ZaloHeader>

- (void) setSectionTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
