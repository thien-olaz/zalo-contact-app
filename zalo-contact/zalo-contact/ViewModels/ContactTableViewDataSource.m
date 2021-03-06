//
//  ContactViewModel.m
//  zalo-contact
//
//  Created by Thiện on 23/11/2021.
//
#import "ContactTableViewDataSource.h"
#import "SectionObject.h"
#import "ZaloContactService.h"

@implementation ContactTableViewDataSource {
    NSMutableArray<SectionObject *> *sections;
    NSMutableArray<NSString *> *sectionTitles;
    NSMutableArray<NSNumber *> *remapedSectionIndex;
    CellFactory *cellFactory;
}

- (instancetype)init {
    self = [super init];
    cellFactory = [CellFactory new];
    
    return self;
}

- (void)compileDatasource:(NSArray *)dataArray {
    NSMutableArray<SectionObject *>* sectionsArray = [NSMutableArray array];
    
    SectionObject *currentSection = nil;
    
    // MARK: - remap section title and index when compile
    sectionTitles = NSMutableArray.array;
    remapedSectionIndex = NSMutableArray.array;
    
    for (id object in dataArray) {
        if ([object isKindOfClass:CellObject.class]) {
            if (currentSection) {
                [currentSection addRowObject:(CellObject *)object];
            }
        } else if ([object isKindOfClass:HeaderObject.class]) {
            if (currentSection) {
                [sectionsArray addObject:currentSection];
            }
            currentSection = SectionObject.new;
            currentSection.header = (HeaderObject *)object;
            
            if (currentSection.header.letterTitle) {
                [sectionTitles addObject:currentSection.header.letterTitle];
                [remapedSectionIndex addObject: [NSNumber numberWithUnsignedLong:sectionsArray.count]];
            }
            
        } else if ([object isKindOfClass:FooterObject.class]) {
            if (currentSection) {
                currentSection.footer = (FooterObject *)object;
            }
        }
    }
    
    if (currentSection) [sectionsArray addObject:currentSection];
    
    sections = sectionsArray;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    SectionObject *section = sections[indexPath.section];
    return [section getObjectForRow:indexPath.row];
}

- (NSIndexPath * _Nullable)indexPathForOnlineContactEntity:(OnlineContactEntity *)contact {
    OnlineContactObject *object = [OnlineContactObject.alloc initWithContactEntity:contact];
    NSUInteger sectionIndex = [UIConstants getContactIndex] - 1;
    NSArray* rows = [[sections objectAtIndex:sectionIndex] rows];
    NSUInteger foundIndex = [rows indexOfObject:object inSortedRange:NSMakeRange(0, [rows count]) options:NSBinarySearchingFirstEqual usingComparator:^NSComparisonResult(OnlineContactObject *obj1, OnlineContactObject *obj2) {
        return [obj1 revertCompare:obj2];
    }];
    if (foundIndex == NSNotFound) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:foundIndex inSection:sectionIndex];
}

- (NSIndexPath * _Nullable)indexPathForContactEntity:(ContactEntity *)contact {
    ContactObject *object = [ContactObject.alloc initWithContactEntity:contact];
    for (NSUInteger sectionIndex = [UIConstants getContactIndex]; sectionIndex < [sections count]; sectionIndex++) {
        if (![[contact header] isEqualToString: sections[sectionIndex].header.letterTitle]) continue;
        NSArray* rows = [[sections objectAtIndex:sectionIndex] rows];
        NSUInteger foundIndex = [rows indexOfObject:object inSortedRange:NSMakeRange(0, [rows count]) options:NSBinarySearchingFirstEqual usingComparator:^NSComparisonResult(ContactObject *obj1, ContactObject *obj2) {
            return [obj1 compareToSearch:obj2];
        }];
        if (foundIndex == NSNotFound) return nil;
        return [NSIndexPath indexPathForRow:foundIndex inSection:sectionIndex];
    }
    return nil;
}

- (nullable HeaderObject *)headerObjectInSection:(NSInteger)index {
    SectionObject *section = sections[index];
    return section.header;
}

- (nullable FooterObject *)footerObjectInSection:(NSInteger)index {
    SectionObject *section = sections[index];
    return section.footer;
}


// MARK: UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CellObject *object = [self objectAtIndexPath:indexPath];
    return [cellFactory cellForTableView:tableView atIndexPath:indexPath withObject:object];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sections[section].numberOfRowsInSection;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sections.count;
}

// Ref qua section
- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return remapedSectionIndex[index].intValue;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellObject *object = [self objectAtIndexPath: indexPath];
    return [cellFactory tableView:tableView heightForRowWithObject:object];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
