//
//  ContactViewModel.h
//  zalo-contact
//
//  Created by Thiện on 23/11/2021.
//

#import <Foundation/Foundation.h>
#import "ContactTableViewDataSource.h"
#import "CellFactory.h"
#import "ContactObject.h"
#import "OnlineContactObject.h"

@import UIKit;
@import CoreGraphics;

@protocol ZaloDataSource <NSObject>

@required

- (id _Nonnull )objectAtIndexPath:(NSIndexPath *_Nonnull)indexPath;

- (NSIndexPath * _Nullable)indexPathForContactEntity:(ContactEntity *_Nonnull)contact;
- (NSIndexPath * _Nullable)indexPathForOnlineContactEntity:(OnlineContactEntity *_Nonnull)contact;
- (nullable HeaderObject *)headerObjectInSection:(NSInteger)index;
- (nullable FooterObject *)footerObjectInSection:(NSInteger)index;
- (CGFloat)tableView:(UITableView *_Nonnull)tableView heightForRowAtIndexPath:(NSIndexPath *_Nonnull)indexPath;


@end

@interface ContactTableViewDataSource : NSObject<UITableViewDataSource, ZaloDataSource>

- (void)compileDatasource:(NSArray *_Nonnull)dataArray;

@end

