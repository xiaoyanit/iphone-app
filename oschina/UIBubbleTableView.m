//
//  UIBubbleTableView.m
//
//  Created by Alex Barinov
//  StexGroup, LLC
//  http://www.stexgroup.com
//
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "UIBubbleTableView.h"
#import "NSBubbleData.h"
#import "NSBubbleDataInternal.h"

@interface UIBubbleTableView ()

@property (nonatomic, retain) NSMutableDictionary *bubbleDictionary;

@end

@implementation UIBubbleTableView

@synthesize bubbleDataSource = _bubbleDataSource;
@synthesize snapInterval = _snapInterval;
@synthesize bubbleDictionary = _bubbleDictionary;
@synthesize typingBubble = _typingBubble;

#pragma mark - Initializators

- (void)initializator
{
    // UITableView properties
    
    self.backgroundColor = [UIColor clearColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    assert(self.style == UITableViewStylePlain);
    
    self.delegate = self;
    self.dataSource = self;
    
    // UIBubbleTableView default properties
    
//    self.snapInterval = 120;
    self.snapInterval = 120;
    self.typingBubble = NSBubbleTypingTypeMe;
//    self.typingBubble = NSBubbleTypingTypeSomebody;
}

- (id)init
{
    self = [super init];
    if (self)
        [self initializator];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) [self initializator];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) [self initializator];
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) [self initializator];
    return self;
}

- (void)dealloc
{
    [_bubbleDictionary release];
	_bubbleDictionary = nil;
	_bubbleDataSource = nil;
    [super dealloc];
}

#pragma mark - Override

- (void)reloadData
{
    
    // Cleaning up
	self.bubbleDictionary = nil;
    
    // Loading new data
    int count = 0;
    count = [self.bubbleDataSource rowsForBubbleTable:self];
    if (count <= 0) {
        return;
    }
    NSLog(@"内部 这一次个数: %d", count);
    if (count == 1) {
        NSBubbleData *data = [self.bubbleDataSource bubbleTableView:self dataForRow:0];
        if (data == nil || [data.text isEqualToString:@" "]) {
            NSLog(@"内部 果然为空 取消方法");
            return;
        }
    }
    NSLog(@"内部 %d",count);
    self.bubbleDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    
    if (self.bubbleDataSource && count > 0)
    {        
        NSMutableArray *bubbleData = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
        for (int i = 0; i < count; i++)
        {
            //调用该方法需要更改 在数据还没有的时候不能执行
            NSObject *object = [self.bubbleDataSource bubbleTableView:self dataForRow:i];
            NSBubbleData * data = (NSBubbleData *)object;
//            NSLog(@"%@_%@",data.text, data.date);
            if (object == nil ) {
                continue;
            }
            else {
                [bubbleData addObject:object];
            }
//            assert([object isKindOfClass:[NSBubbleData class]]);
        }
        
        [bubbleData sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
        {
//            NSBubbleData *bubbleData1 = (NSBubbleData *)obj1;
//            NSBubbleData *bubbleData2 = (NSBubbleData *)obj2;
            
            NSBubbleData *bubbleData1 = (NSBubbleData *)obj2;
            NSBubbleData *bubbleData2 = (NSBubbleData *)obj1;
            
            return [bubbleData1.date compare:bubbleData2.date];            
        }];
        
        NSDate *last = [NSDate dateWithTimeIntervalSince1970:0];
        NSMutableArray *currentSection = nil;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        for (int i = 0; i < count; i++)
        {
            NSBubbleDataInternal *dataInternal = [[[NSBubbleDataInternal alloc] init] autorelease];
            
            NSBubbleData * bu = [bubbleData objectAtIndex:i];
            if (bu == nil ) {
                continue;
            }
            
            dataInternal.data = (NSBubbleData *)bu;
            dataInternal.type = NSBubbleDataTypeNormalBubble;
            
            // Calculating cell height
            dataInternal.labelSize = [(dataInternal.data.text ? dataInternal.data.text : @"") sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:UILineBreakModeWordWrap];
            
            dataInternal.height = dataInternal.labelSize.height + 5 + 11;
            
            dataInternal.header = nil;
            
            if ([dataInternal.data.date timeIntervalSinceDate:last] < -self.snapInterval)
            {
                currentSection = [[[NSMutableArray alloc] init] autorelease];
                [self.bubbleDictionary setObject:currentSection forKey:[NSString stringWithFormat:@"%d", i]];
                dataInternal.header = [dateFormatter stringFromDate:dataInternal.data.date];
                dataInternal.height += 30;
            }

            [currentSection addObject:dataInternal];
            last = dataInternal.data.date;
        }
        
        [dateFormatter release];
    }
    
    // Adding the typing bubble at the end of the table
    
    if (self.typingBubble != NSBubbleTypingTypeNobody)
    {
        NSBubbleDataInternal *dataInternal = [[[NSBubbleDataInternal alloc] init] autorelease];
        
        dataInternal.data = nil;
        dataInternal.type = NSBubbleDataTypeTypingBubble;
        dataInternal.labelSize = CGSizeMake(0, 0);
        dataInternal.height = 40;
        
        [self.bubbleDictionary setObject:[NSMutableArray arrayWithObject:dataInternal] forKey:[NSString stringWithFormat:@"%d", count]];
    }
    
    [super reloadData];
}

#pragma mark - UITableViewDelegate implementation

#pragma mark - UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.bubbleDictionary allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *keys = [self.bubbleDictionary allKeys];
	NSArray *sortedArray = [keys sortedArrayUsingComparator:^(id firstObject, id secondObject) {
		return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
	}];
    NSString *key = [sortedArray objectAtIndex:section];
    return [[self.bubbleDictionary objectForKey:key] count];
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *keys = [self.bubbleDictionary allKeys];
	NSArray *sortedArray = [keys sortedArrayUsingComparator:^(id firstObject, id secondObject) {
		return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
	}];
    NSString *key = [sortedArray objectAtIndex:indexPath.section];
    NSBubbleDataInternal *dataInternal = ((NSBubbleDataInternal *)[[self.bubbleDictionary objectForKey:key] objectAtIndex:indexPath.row]);

    return dataInternal.height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *keys = [self.bubbleDictionary allKeys];
	NSArray *sortedArray = [keys sortedArrayUsingComparator:^(id firstObject, id secondObject) {
		return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
	}];
    NSString *key = [sortedArray objectAtIndex:indexPath.section];
    
    NSBubbleDataInternal *dataInternal = ((NSBubbleDataInternal *)[[self.bubbleDictionary objectForKey:key] objectAtIndex:indexPath.row]);
    if (dataInternal.type == NSBubbleDataTypeTypingBubble)
    {    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NextBubble" object:self];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *keys = [self.bubbleDictionary allKeys];
	NSArray *sortedArray = [keys sortedArrayUsingComparator:^(id firstObject, id secondObject) {
		return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
//        return [((NSString *)secondObject) compare:((NSString *)firstObject) options:NSNumericSearch];
	}];
    NSString *key = [sortedArray objectAtIndex:indexPath.section];
    
    NSBubbleDataInternal *dataInternal = ((NSBubbleDataInternal *)[[self.bubbleDictionary objectForKey:key] objectAtIndex:indexPath.row]);
    
    
    if (dataInternal.type == NSBubbleDataTypeNormalBubble)
    {    
        static NSString *cellId = @"tblBubbleCell";
        UIBubbleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
        if (cell == nil)
        {
            [[NSBundle mainBundle] loadNibNamed:@"UIBubbleTableViewCell" owner:self options:nil];
            cell = bubbleCell;
        }
    
        cell.dataInternal = dataInternal;
        return cell;
    }
    
    if (dataInternal.type == NSBubbleDataTypeTypingBubble)
    {
        static NSString *cellTypingId = @"tblBubbleTypingCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellTypingId];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] init];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UIImage *bubbleImage = nil;
            float x = 0;
            
            if (self.typingBubble == NSBubbleTypingTypeMe)
            {
                bubbleImage = [UIImage imageNamed:@"typingMine.png"]; 
                x = cell.frame.size.width - 4 - bubbleImage.size.width;
            }
            else
            {
                bubbleImage = [UIImage imageNamed:@"typingSomeone.png"]; 
                x = 4;
            }

            
            UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:bubbleImage];
            bubbleImageView.frame = CGRectMake(x, 4, 73, 31);
            [cell addSubview:[bubbleImageView autorelease]];
        }
        
        return cell;
    }
    
    return nil;
}

@end
