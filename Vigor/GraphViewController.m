//
//  GraphViewController.m
//  Vigor
//
//  Created by YASH on 23/04/16.
//  Copyright © 2016 Dark Army. All rights reserved.
//

#import "GraphViewController.h"

@interface GraphViewController () <ChartViewDelegate, ORKPieChartViewDataSource>
{
    NSMutableArray *kinveyDataArray;
}

@property (strong, nonatomic) IBOutlet LineChartView *chartView;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet ORKPieChartView *pieview;

@end

@implementation GraphViewController
{
	NSArray *legendTitles;
	
	NSInteger posCount;
	NSInteger negCount;
	
	CGFloat one;
	CGFloat two;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	posCount = 1;
	negCount = 1;
	
	legendTitles = @[@"SUN", @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT"];
	
    _chartView.delegate = self;
    
    [self setupBarLineChartView:_chartView];
    
    _chartView.dragEnabled = YES;
    [_chartView setScaleEnabled:YES];
    _chartView.pinchZoomEnabled = YES;
    _chartView.drawGridBackgroundEnabled = NO;
    
	
    ChartYAxis *leftAxis = _chartView.leftAxis;
    [leftAxis removeAllLimitLines];
    leftAxis.axisMaxValue = 1.2;
    leftAxis.axisMinValue = -1.2;
    leftAxis.drawZeroLineEnabled = NO;
    leftAxis.drawLimitLinesBehindDataEnabled = YES;
	
    _chartView.legend.form = ChartLegendFormLine;
	
	[self updateSegmentedControl:self.segmentedControl];
	
}

- (void)viewWillAppear:(BOOL)animated
{
    if (![KCSUser activeUser])
    {
        [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)   {
            if (errorOrNil != nil)
            {
                //load failed
                NSLog(@"load fail user auth");
            }
            else
            {
                [self load:nil];
            }
        }];
    } else
    {
        [self load:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	
	self.pieview.dataSource = self;
	self.pieview.showsTitleAboveChart = YES;
	self.pieview.text = @"Feedback";
	self.pieview.lineWidth = 4.0;
//	[self.pieview animateWithDuration:1.0];
	
    [_chartView animateWithXAxisDuration:2.5 easingOption:ChartEasingOptionEaseInOutCirc];
	
	[super viewDidAppear:animated];
}

- (void) load:(id) sender
{
    
    KCSCollection *listObjects = [KCSCollection collectionFromString:@"Feedback" ofClass:[OnlineFeedback class]];
    KCSAppdataStore *store = [KCSAppdataStore storeWithCollection:listObjects options:nil];
    KCSQuery *query = [KCSQuery query];
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:KCSMetadataFieldLastModifiedTime inDirection:kKCSDescending]];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //        [sender endRefreshing];
        if (errorOrNil != nil)
        {
            //An error happened, just log for now
            NSLog(@"An error occurred on fetch: %@", errorOrNil);
        }
        else
        {
            //got all events back from server -- update graph
			NSString *pgrmString = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentProgram"];
			kinveyDataArray = [[objectsOrNil filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"programName == %@", pgrmString]] mutableCopy];
//            kinveyDataArray = [NSMutableArray arrayWithArray:objectsOrNil];
        }
    } withProgressBlock:nil];
    
}

- (IBAction)updateSegmentedControl:(id)sender
{
	
	NSMutableArray *xAxisValues = [[NSMutableArray alloc] init];
	NSMutableArray *yAxisValues = [[NSMutableArray alloc] init];
	
	posCount = 0.0;
	negCount = 0.0;
	
	NSInteger index = [sender selectedSegmentIndex];
	
	if (index == 0)
    {
		// Core data
		NSMutableArray *feedbacks = [Feedback getAllFeedbacks];
		
		for (int i = 0; i < feedbacks.count; i++)
		{
			Feedback *fback = [feedbacks objectAtIndex:i];
			[xAxisValues addObject:[NSString stringWithFormat:@"%@", legendTitles[i%7]]];
			[yAxisValues addObject:[[ChartDataEntry alloc] initWithValue:fback.value.floatValue xIndex:i]];
//			if ([fback.review isEqualToString:@"positive"]) posCount+=1;
//			if ([fback.review isEqualToString:@"negative"]) negCount+=1;
			if (fback.value.floatValue > 0.2)
				posCount += 1;
			if (fback.value.floatValue < -0.2)
				negCount += 1;
		}

		
	}
	else
    {
		// Kinvey
        for (NSInteger i = kinveyDataArray.count - 1; i >= 0; --i) {
            OnlineFeedback *fback = [kinveyDataArray objectAtIndex:i];
            [xAxisValues addObject:[NSString stringWithFormat:@"%@", legendTitles[i%7]]];
            [yAxisValues addObject:[[ChartDataEntry alloc] initWithValue:fback.valueForFeedback.floatValue xIndex:i]];
//			if ([fback.review isEqualToString:@"positive"]) posCount+=1;
//			if ([fback.review isEqualToString:@"negative"]) negCount+=1;
			if (fback.valueForFeedback.floatValue > 0.2)
				posCount += 1;
			if (fback.valueForFeedback.floatValue < -0.2)
				negCount += 1;
        }
        
	}
	
	one = (posCount + 0.0)/(posCount + negCount + 1.0);
	two = (negCount + 0.0)/(posCount + negCount + 1.0);
	
//	if (one == 0.0)
//		one = 1/3.0;
//	if (two == 0.0)
//		two = 1/3.0;
	
	NSLog(@"one : %f , two : %f",one,two);
	
	LineChartDataSet *dataSet = nil;
	
	dataSet = [[LineChartDataSet alloc] initWithYVals:yAxisValues label:@"Satisfaction"];
	
	[dataSet setColor:UIColor.blackColor];
	[dataSet setCircleColor:UIColor.darkGrayColor];
	dataSet.lineWidth = 1.0;
	dataSet.circleRadius = 2.5;
	dataSet.drawCircleHoleEnabled = YES;
	dataSet.valueFont = [UIFont systemFontOfSize:9.f];
	
	NSMutableArray *dataSets = [[NSMutableArray alloc] init];
	[dataSets addObject:dataSet];
	
	LineChartData *data = [[LineChartData alloc] initWithXVals:xAxisValues dataSets:dataSets];
	
	_chartView.data = data;
    
    
    self.pieview.dataSource = self;
    [self.pieview animateWithDuration:1.0];
	
    [_chartView animateWithXAxisDuration:2.5 easingOption:ChartEasingOptionEaseInOutCirc];
}

- (IBAction)dismissView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry dataSetIndex:(NSInteger)dataSetIndex highlight:(ChartHighlight * __nonnull)highlight
{
    NSLog(@"chartValueSelected");
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

- (void)setupBarLineChartView:(BarLineChartViewBase *)chartView
{
    chartView.descriptionText = @"";
    chartView.noDataTextDescription = @"You need to provide data for the chart.";
    
    chartView.drawGridBackgroundEnabled = NO;
    
    chartView.dragEnabled = YES;
    [chartView setScaleEnabled:YES];
    chartView.pinchZoomEnabled = NO;
    
    // ChartYAxis *leftAxis = chartView.leftAxis;
    
    ChartXAxis *xAxis = chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    
    chartView.rightAxis.enabled = NO;
}

#pragma mark - ORKPieChartDelegate

- (NSInteger)numberOfSegmentsInPieChartView:(ORKPieChartView *)pieChartView
{
	if (one == 0 && two == 0)
		return 1;
	if (one == 0 || two == 0)
		return 2;
	return 3;
}

- (CGFloat)pieChartView:(ORKPieChartView *)pieChartView valueForSegmentAtIndex:(NSInteger)index
{
	if (one == 0 && two == 0)
		return 1;
	if (one == 0 || two == 0) {
		if (index == 0)
			return one + two;
		return 1.0 - one - two;
	}
    if (index == 0)
        return one;
    else if (index == 1)
        return two;
    return 1.0 - one - two;
}

- (UIColor *)pieChartView:(ORKPieChartView *)pieChartView colorForSegmentAtIndex:(NSInteger)index
{
	if (index == 0) return GLOBAL_BLUE_COLOR;
	else if (index == 1) return GLOBAL_GREEN_COLOR;
	return GLOBAL_RED_COLOR;
}

- (NSString *)pieChartView:(ORKPieChartView *)pieChartView titleForSegmentAtIndex:(NSInteger)index
{
	if (index == 0) return @"Positive";
	else if (index == 1) return @"Neutral";
	return @"Negative";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
