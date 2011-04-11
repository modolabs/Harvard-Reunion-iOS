#import "AboutTableViewController.h"
#import "KGOAppDelegate.h"
#import "UIKit+KGOAdditions.h"
#import "MITMailComposeController.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation AboutTableViewController
@synthesize request;
@synthesize moduleTag;

// TODO: clear these defaults if the user switches years, after a timeout, or both
static NSString * const AboutParagraphsPrefKey = @"AboutParagraphs";
static NSString * const AboutSectionsPrefKey = @"AboutSections";

- (void)viewDidLoad {
    _paragraphs = [[[NSUserDefaults standardUserDefaults] objectForKey:AboutParagraphsPrefKey] retain];
    _sections = [[[NSUserDefaults standardUserDefaults] objectForKey:AboutSectionsPrefKey] retain];
    
    if (!_paragraphs || !_sections) {
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                       module:self.moduleTag
                                                                         path:@"info"
                                                                       params:nil];
        self.request.expectedResponseType = [NSDictionary class];
        if (self.request) {
            [self.request connect];
        }
    }
    
    UILabel *footerLabel = [UILabel multilineLabelWithText:@"© 2011 The President and Fellows of Harvard College"
                                                      font:[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySmallPrint]
                                                     width:self.view.frame.size.width - 20];
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertySmallPrint];
    UIView *footerView = [[[UIView alloc] initWithFrame:footerLabel.frame] autorelease];
    [footerView addSubview:footerLabel];
    self.tableView.tableFooterView = footerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _paragraphs.count + _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < _paragraphs.count) {
        return 1;
    } else {
        NSDictionary *info = [_sections dictionaryAtIndex:section - _paragraphs.count];
        NSArray *links = [info arrayForKey:@"links"];
        return links.count;
    }
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < _paragraphs.count) {
        NSString *text = [_paragraphs objectAtIndex:indexPath.section];
        UILabel *label = [UILabel multilineLabelWithText:text
                                                    font:[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText]
                                                   width:tableView.frame.size.width - 40];
        label.frame = CGRectMake(10, 10, label.frame.size.width, label.frame.size.height);
        return [NSArray arrayWithObject:label];

    } else {
        return nil;
    }
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= _paragraphs.count) {
        return KGOTableCellStyleSubtitle;
    } else {
        return KGOTableCellStyleDefault;
    }
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= _paragraphs.count) {
        NSInteger section = indexPath.section - _paragraphs.count;
        NSDictionary *info = [_sections dictionaryAtIndex:section];
        NSArray *links = [info arrayForKey:@"links"];
        
        NSDictionary *linkInfo = [links dictionaryAtIndex:indexPath.row];
        
        NSString *title = [linkInfo stringForKey:@"title" nilIfEmpty:YES];
        NSString *subtitle = [linkInfo stringForKey:@"subtitle" nilIfEmpty:YES];
        NSString *class = [linkInfo stringForKey:@"class" nilIfEmpty:YES];
        
        NSString *accessory = nil;
        if ([class isEqualToString:@"email"]) {
            accessory = KGOAccessoryTypeEmail;
        } else if ([class isEqualToString:@"phone"]) {
            accessory = KGOAccessoryTypePhone;
        } else if ([class isEqualToString:@"external"]) {
            accessory = KGOAccessoryTypeExternal;
        }
        
        return [[^(UITableViewCell *cell) {
            cell.textLabel.text = title;
            cell.detailTextLabel.text = subtitle;
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
        } copy] autorelease];
        
    } else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section >= _paragraphs.count) {
        section -= _paragraphs.count;
        NSDictionary *info = [_sections dictionaryAtIndex:section];
        return [info stringForKey:@"title" nilIfEmpty:YES];
    } else {
        return nil;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section >= _paragraphs.count) {
        NSInteger section = indexPath.section - _paragraphs.count;
        NSDictionary *info = [_sections dictionaryAtIndex:section];
        NSArray *links = [info arrayForKey:@"links"];
        
        NSDictionary *linkInfo = [links dictionaryAtIndex:indexPath.row];
        NSString *urlString = [linkInfo stringForKey:@"url" nilIfEmpty:YES];

        // TODO: don't do this for email
        NSURL *url = [NSURL URLWithString:urlString];
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void)dealloc {
    [self.request cancel];
    self.request = nil;
    [_paragraphs release];
    [_sections release];
    [super dealloc];
}


#pragma mark KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request {
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    self.request = nil;
    
    NSLog(@"%@", [result description]);
    
    NSDictionary *resultDict = (NSDictionary *)result;
    [_paragraphs release];
    _paragraphs = [[resultDict arrayForKey:@"paragraphs"] retain];
    
    [_sections release];
    _sections = [[resultDict arrayForKey:@"sections"] retain];

    [[NSUserDefaults standardUserDefaults] setObject:_paragraphs forKey:AboutParagraphsPrefKey];
    [[NSUserDefaults standardUserDefaults] setObject:_sections forKey:AboutSectionsPrefKey];

    [self.tableView reloadData];
}

@end

