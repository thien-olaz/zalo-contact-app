//
//  ZaloContactService.m
//  zalo-contact
//
//  Created by Thiện on 06/12/2021.
//

#import "ZaloContactService.h"
#import "UserContacts.h"
#import "NSArrayExt.h"
#import "ContactGroupEntity.h"
#import "ContactEntity.h"
//MARK: - Usage
/*
 User for external and internal use
 */
@implementation ZaloContactService {
    NSMutableArray<id<ZaloContactEventListener>> *listeners;
    
    NSLock *contactDictionaryLock;
    NSMutableDictionary<NSString *, ContactEntity *> *accountDictionary;
    NSLock *accountDictionaryLock;
    
    //    id<APIServiceProtocol> apiService;
}

static ZaloContactService *sharedInstance = nil;

+ (ZaloContactService *)sharedInstance {
    @synchronized([ZaloContactService class]) {
        if (!sharedInstance)
            sharedInstance = [self new];
        return sharedInstance;
    }
    return nil;
}

- (instancetype)init {
    self = super.init;
    
    contactDictionaryLock = [NSLock new];
    accountDictionaryLock = [NSLock new];
    
    _apiService = [MockAPIService new];
    
    _contactDictionary = [ContactDictionary new];
    accountDictionary = [NSMutableDictionary new];
    
    // load saved data
    [self load];
    
    //setup server method
    [self setUp];
    
    //fetching data form server
    __weak typeof(self) weakSelf = self;
    [_apiService fetchContacts:^(NSArray<ContactEntity *> * contactsFromServer) {
        if (contactsFromServer.count <= 0) return;
        
        NSArray<ContactEntity *> *sortedArr = [ContactEntity insertionSort:contactsFromServer];
        
        [weakSelf didReceiveNewFullList:sortedArr];
    }];
    return self;
}

- (void)fetchLocalContact {
    [UserContacts.sharedInstance fetchLocalContacts];
    _contactDictionary = UserContacts.sharedInstance.getContactDictionary;
    
    // Complexity == all contacts
    for (NSArray<ContactEntity *> *contacts in [_contactDictionary allValues]) {
        for (ContactEntity *contact in contacts) [accountDictionary setObject:contact forKey:contact.phoneNumber.copy];
    }
}

- (void)setUp {
    __weak typeof(self) weakSelf = self;
    [_apiService setOnContactAdded:^(ContactEntity * newContact) {
        [weakSelf didAddContact:newContact];
    }];
    
    [_apiService setOnContactDeleted:^(ContactEntity * deleteContact) {
        [weakSelf didDeleteContact:deleteContact];
    }];
    
    [_apiService setOnContactUpdated:^(ContactEntity * oldContact, ContactEntity * newContact) {
        [weakSelf didUpdateContact:oldContact toContact:newContact];
    }];
    
    [_apiService setOnContactUpdatedWithPhoneNumber:^(NSString * phoneNumber, ContactEntity * newContact) {
        [weakSelf didUpdateContactWihPhoneNumber:phoneNumber toContact:newContact];
    }];
    
    //    [_apiService fakeServerUpdate];
}


- (ContactDictionary *)getFullContactDict {
    return _contactDictionary;
}

- (NSArray<ContactEntity *>*)getFullContactList {
    return [_contactDictionary.allValues flatMap:^id(id obj) { return obj; }];
}

// chắc chắn có phone number
// đẩy phone number vào -> gọi từ dictionary -> tìm ra được thông tin -> từ cái thông tin đó tìm trong tableview =-> ra được section

// Check if a friend with phone number exist
- (ContactEntity *)getContactsWithPhoneNumber:(NSString *)phoneNumber {
    return [accountDictionary objectForKey:phoneNumber];
}

- (BOOL)isFriendWithPhoneNumber:(NSString *)phoneNumber {
    return [accountDictionary objectForKey:phoneNumber] != nil;
}


#pragma mark - Observer

- (void)subcribe:(id<ZaloContactEventListener>)listener {
    if (!listeners) {
        listeners = NSMutableArray.new;
    }
    [listeners addObject:listener];
}

- (void)unsubcribe:(id<ZaloContactEventListener>)listener {
    if (!listeners) {
        return;
    }
    [listeners removeObject:listener];
}

- (void)didReceiveNewFullList:(NSArray<ContactEntity *>*)sortedArray {    
    NSString *currentHeader = sortedArray[0].header;
    ContactDictionary *temp = [ContactDictionary new];
    NSMutableArray<ContactEntity *> *tempArray = NSMutableArray.new;
    
    for (ContactEntity *contact in sortedArray) {
        
        if (![contact.header isEqualToString:currentHeader]) {
            [temp setObject:tempArray.copy forKey:currentHeader];
            
            currentHeader = contact.header;
            tempArray = NSMutableArray.new;
        }
        [tempArray addObject:contact];
    }
    [temp setObject:tempArray.copy forKey:currentHeader];
    
    _contactDictionary = temp;
    
    [self save];
    
    for (id<ZaloContactEventListener> listener in listeners) {
        if ([listener respondsToSelector:@selector(onReceiveNewList)]) {
            [listener onReceiveNewList];
        }
    }

}

- (void)didAddContact:(ContactEntity *)contact {
    [contactDictionaryLock lock];
    [accountDictionaryLock lock];
    [accountDictionary setObject:contact forKey:contact.phoneNumber.copy];
    if (![_contactDictionary objectForKey:contact.header]) {
        [_contactDictionary setObject:@[contact] forKey:contact.header];
    } else {
        //        insert to array
        NSMutableArray *arr = [_contactDictionary objectForKey:contact.header].mutableCopy;
        for (int i = 0; i < arr.count; i++) {
            if ([contact compare:arr[i]] == NSOrderedDescending) {
                
                if (i + 1 < arr.count && [contact compare:arr[i + 1]] == NSOrderedSame) {
                    continue;
                } else {
                    [arr insertObject:contact atIndex:i];
                }
                
                break;
            }
        }
        [_contactDictionary setObject:arr forKey:contact.header];
    }
    
    [contactDictionaryLock unlock];
    [accountDictionaryLock unlock];
    
    [self didChange];
    
    // Notify subscriber
    for (id<ZaloContactEventListener> listener in listeners) {
        if ([listener respondsToSelector:@selector(onAddContact:)]) {
            [listener onAddContact:contact];
        }
    }

}

- (void)didDeleteContact:(ContactEntity *)contact {
    [contactDictionaryLock lock];
    [accountDictionaryLock lock];
    
    [accountDictionary removeObjectForKey:contact.phoneNumber];
    if ([_contactDictionary objectForKey:contact.header]) {
        //        delete from to array
        NSMutableArray *arr = [_contactDictionary objectForKey:contact.header].mutableCopy;
        for (int i = 0; i < arr.count; i++) {
            if ([contact compare:arr[i]] == NSOrderedSame) {
                [arr removeObjectAtIndex:i];
                break;
            }
        }
        if (arr.count > 0) [_contactDictionary setObject:arr forKey:contact.header];
        else [_contactDictionary removeObjectForKey:contact.header];
    }
    
    [contactDictionaryLock unlock];
    [accountDictionaryLock unlock];
    
    [self didChange];
    
    for (id<ZaloContactEventListener> listener in listeners) {
        if ([listener respondsToSelector:@selector(onDeleteContact:)]) {
            [listener onDeleteContact:contact];
        }
    }
    
}

// MARK: - actually we just need the account id and new contact infor for this function when in use
- (void)didUpdateContact:(ContactEntity *)contact toContact:(ContactEntity *)newContact {
    [contactDictionaryLock lock];
    [accountDictionaryLock lock];
    
    [accountDictionary removeObjectForKey:contact.phoneNumber];
    [accountDictionary setObject:newContact forKey:newContact.phoneNumber];
    
    if ([_contactDictionary objectForKey:contact.header]) {
        //        delete from to array
        NSMutableArray *arr = [_contactDictionary objectForKey:contact.header].mutableCopy;
        for (int i = 0; i < arr.count; i++) {
            if ([contact compare:arr[i]] == NSOrderedSame) {
                [arr removeObjectAtIndex:i];
                break;
            }
        }
        if (arr.count > 0) [_contactDictionary setObject:arr forKey:contact.header];
        else [_contactDictionary removeObjectForKey:contact.header];
    }
    
    if (![_contactDictionary objectForKey:newContact.header]) {
        [_contactDictionary setObject:@[contact] forKey:newContact.header];
    } else {
        //        insert to array
        NSMutableArray *arr = [_contactDictionary objectForKey:newContact.header].mutableCopy;
        for (int i = 0; i < arr.count; i++) {
            if ([newContact compare:arr[i]] == NSOrderedDescending) {
                
                if (i + 1 < arr.count && [newContact compare:arr[i + 1]] == NSOrderedSame) {
                    continue;
                } else {
                    [arr insertObject:newContact atIndex:i];
                }
                
                break;
            }
        }
        [_contactDictionary setObject:arr forKey:newContact.header];
    }
    
    [contactDictionaryLock unlock];
    [accountDictionaryLock unlock];
    
    [self didChange];
    
    for (id<ZaloContactEventListener> listener in listeners) {
        if ([listener respondsToSelector:@selector(onUpdateContact:toContact:)]) {
            [listener onUpdateContact:contact toContact:newContact];
        }
    }
    
}

- (void)didUpdateContactWihPhoneNumber:(NSString *)phoneNumber toContact:(ContactEntity *)newContact {
    
    [contactDictionaryLock lock];
    [accountDictionaryLock lock];
    
    ContactEntity *contact = [accountDictionary objectForKey:phoneNumber];
    
    [accountDictionary removeObjectForKey:phoneNumber];
    [accountDictionary setObject:newContact forKey:phoneNumber];
    
    if ([_contactDictionary objectForKey:contact.header]) {
        //        delete from to array
        NSMutableArray *arr = [_contactDictionary objectForKey:contact.header].mutableCopy;
        for (int i = 0; i < arr.count; i++) {
            if ([contact compare:arr[i]] == NSOrderedSame) {
                [arr removeObjectAtIndex:i];
                break;
            }
        }
        if (arr.count > 0) [_contactDictionary setObject:arr forKey:contact.header];
        else [_contactDictionary removeObjectForKey:contact.header];
    }
    
    if (![_contactDictionary objectForKey:newContact.header]) {
        [_contactDictionary setObject:@[newContact] forKey:newContact.header];
    } else {
        //        insert to array
        NSMutableArray *arr = [_contactDictionary objectForKey:newContact.header].mutableCopy;
        for (int i = 0; i < arr.count; i++) {
            if ([newContact compare:arr[i]] == NSOrderedDescending) {
                
                if (i + 1 < arr.count && [newContact compare:arr[i + 1]] == NSOrderedSame) {
                    continue;
                } else {
                    [arr insertObject:newContact atIndex:i];
                }
                
                break;
            }
        }
        [_contactDictionary setObject:arr forKey:newContact.header];
    }
    
    [contactDictionaryLock unlock];
    [accountDictionaryLock unlock];
    
    [self didChange];
    
    for (id<ZaloContactEventListener> listener in listeners) {
        if ([listener respondsToSelector:@selector(onUpdateContact:toContact:)]) {
            [listener onUpdateContact:contact toContact:newContact];
        }
    }
    
}

// MARK: Perform operation when data changed
- (void)didChange {
    [self save];
}

- (void)save {    
    NSError *err = nil;
    NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject: self.getFullContactDict requiringSecureCoding:NO error:&err];
    if (err) {
        NSLog(@"saveData error %@", err.description);
    }
    [[NSUserDefaults standardUserDefaults] setObject:dataToSave forKey:@"data"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)load {
    NSError *err = nil;
    NSData *decoded = [NSUserDefaults.standardUserDefaults objectForKey:@"data"];
    NSSet *classes = [NSSet setWithObjects:[NSArray class], [ContactGroupEntity class] ,[ContactEntity class], [NSString class], [NSMutableDictionary class], nil];
    ContactDictionary *groups = (ContactDictionary *)[NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:decoded error:&err];
    if (err) {
        NSLog(@"loadSavedData error %@", err.description);
    }
    if (groups) _contactDictionary = groups;
}

@end
