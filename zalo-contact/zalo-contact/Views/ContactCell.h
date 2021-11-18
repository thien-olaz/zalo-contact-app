//
//  ContactCell.h
//  zalo-contact
//
//  Created by Thiện on 16/11/2021.
//

@import Foundation;
@import UIKit;
@import PureLayout;

NS_ASSUME_NONNULL_BEGIN

@interface ContactCell : UICollectionViewCell

- (void) setNameWith:(NSString *)name;
- (void) setAvatarImage:(nonnull UIImage*)image;
@end

NS_ASSUME_NONNULL_END