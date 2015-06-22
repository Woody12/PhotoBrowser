//
//  MainViewController.m
//  PhotoBrowser
//
//  Created by Woody Lee on 6/20/15.
//  Copyright (c) 2015 Woody Lee. All rights reserved.
//

#import "MainViewController.h"
#import "PicsCollectionViewCell.h"

#import "PhotoEntity.h"
#import "AppDelegate.h"

#import "Reachability.h"
#import "Connectivity.h"

static NSCache *cache = nil;

@interface MainViewController () <UICollectionViewDataSource, UICollectionViewDelegate> {
	
	BOOL hasShownAlert;
	
}

@property(nonatomic, strong) NSURLSession *urlSession;
@property(nonatomic, strong) NSURLSessionDataTask *dataTask;
@property(nonatomic, strong) NSURLSessionConfiguration *configuration;

@property(nonatomic, strong) NSFetchedResultsController	*fetchedResultsController;

@property(nonatomic, strong) Connectivity *connectivity;

@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;

- (IBAction)refreshButton:(id)sender;

@end

NSString *const kSearchWord = @"landscape";
NSInteger const kTotalItems = 200;
NSInteger const kActivityIndicatorTag = 100;

@implementation MainViewController

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	
	[self configureCustomView];
	
}

- (void)didReceiveMemoryWarning {
	
	[super didReceiveMemoryWarning];

}

- (void) dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	
}


#pragma mark - UI Helper

- (void) configureCustomView {
	
	// Set to horizontal scroll only
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) self.photoCollectionView.collectionViewLayout;
	
	flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	
	//self.photoCollectionView.pagingEnabled = true;
	self.photoCollectionView.bounces = true;
	self.photoCollectionView.bouncesZoom = true;
	self.photoCollectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	
}

- (void) loadAndDisplay {
	
	// Load from Core Data if possible
	[self fetchData];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		// Reload the data in collection view
		[self.photoCollectionView reloadData];
		
	});
	
}

#pragma mark -
#pragma mark Event Handler

- (IBAction)refreshButton:(id)sender {

	// Display spinner if table has no row and there's connection
	if ((_photoCollectionView.numberOfSections == 0) && ([Connectivity checkConnectivity])){
		
		UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		
		activityIndicatorView.frame = CGRectMake(self.view.center.x, self.view.center.y, 50.0, 50.0);
		activityIndicatorView.tag = kActivityIndicatorTag;
		
		[self.view addSubview:activityIndicatorView];
		[activityIndicatorView startAnimating];
		
	}
	
	[self updateData];
	
	
}

#pragma mark -
#pragma mark Collection View DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	if ([self.fetchedResultsController.sections count] > 0) {
		
		// Stop Activity Indicator if displaying
		UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *) [self.view viewWithTag:kActivityIndicatorTag];
		
		if (activityIndicatorView)
			[activityIndicatorView stopAnimating];
		
		id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo numberOfObjects];
		
		
	}
	else {
		return 0;
	}
	
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
	
	return [[self.fetchedResultsController sections] count];
	
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	PicsCollectionViewCell *cell = (PicsCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
	
}

#pragma mark -
#pragma mark CollectionView Helper

- (void) cacheData:(PicsCollectionViewCell *)cell forKey:(NSString *)key {
	
	// Check whether the image has already been cached
	UIImage *image = [cache objectForKey:key];
	if (image) {
		[[cell imageView] setImage:image];
		
	}
	else {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			
			NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:key]];
			UIImage *image = [UIImage imageWithData:imageData];
			
			// Set to Cache Memory
			[cache setObject:image forKey:key];
			
			// Display the image once download is complete
			dispatch_async(dispatch_get_main_queue(), ^{
				[[cell imageView] setImage:image];
				
			});
			
		});
	}
	
}

- (void)configureCell:(PicsCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *picInfo = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	// Check for cache
	if (cache == nil) {
		cache = [[NSCache alloc] init];
	}
	
	// Retrieve from Internet if there's connectivity
	if ([Connectivity checkConnectivity])
		[self cacheData:cell forKey:picInfo[@"thumbnailURL"]];
	else
		[self displayWarning];
	
}



#pragma mark -
#pragma mark Core Data

- (void)fetchData
{
	[self.fetchedResultsController performFetch:nil];
	
}

#pragma mark - Fetched Results Controller
- (NSFetchedResultsController *)fetchedResultsController {
	
	if (_fetchedResultsController) {
		return _fetchedResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoEntity" inManagedObjectContext:self.moc];
	[fetchRequest setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"photoID" ascending:NO];
	[fetchRequest setSortDescriptors:@[ sortDescriptor ]];
	
	[fetchRequest setFetchBatchSize:16];
	
	// Return distinct
	[fetchRequest setReturnsDistinctResults:YES];
	[fetchRequest setResultType:NSDictionaryResultType];
	
	NSFetchedResultsController *frc;
	frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
											  managedObjectContext:self.moc
												sectionNameKeyPath:nil
														 cacheName:@"frc.root"];
	self.fetchedResultsController = frc;
	
	return _fetchedResultsController;
	
}

#pragma mark -
#pragma mark Flicker Request

- (void)updateData {
	
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	self.urlSession = [NSURLSession sessionWithConfiguration:config];
	
	NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&text=%@&has_geo=1&per_page=%ld&format=json&nojsoncallback=1", kFlickrKey, kSearchWord, kTotalItems];
	NSURL *url = [NSURL URLWithString:urlString];
	
	self.dataTask = [self.urlSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		
		if (data.length > 0) {
			
			NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
			NSArray *photoList = dictionary[@"photos"][@"photo"];
			
			for (id element in photoList) {
				//[photoEntity.farm longValue], [photoEntity.server longValue], [photoEntity.photoID longLongValue]
				
				PhotoEntity *photoEntity = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoEntity" inManagedObjectContext:self.moc];
				photoEntity.farm = [NSNumber numberWithInteger:[element[@"farm"] integerValue]];
				photoEntity.server = [NSNumber numberWithInteger:[element[@"server"] integerValue]];
				photoEntity.secret = element[@"secret"];
				photoEntity.photoID = [NSNumber numberWithLong:[element[@"id"] longLongValue]];
				photoEntity.title = element[@"title"];
				photoEntity.thumbnailURL = [NSString stringWithFormat:@"http://farm%ld.staticflickr.com/%ld/%lld_%@_%@.jpg", [element[@"farm"] integerValue], [element[@"server"] integerValue], [element[@"id"] longLongValue], photoEntity.secret, @"m"];
				photoEntity.fullImageURL = [NSString stringWithFormat:@"http://farm%ld.staticflickr.com/%ld/%lld_%@_%@.jpg", [element[@"farm"] integerValue], [element[@"server"] integerValue], [element[@"id"] longLongValue], photoEntity.secret, @"b"];
				photoEntity.location = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.geo.getLocation&api_key=%@&photo_id=%lld&format=json", kFlickrKey, [element[@"id"] longLongValue]];
				
				// Save to photo core data
				[self.moc save:nil];

			}
			
			// Load and Display data
			[self loadAndDisplay];
			
		}
		
	}];
	
	[self.dataTask resume];
}

#pragma mark -
#pragma mark Connectivity

- (void) reachabilityChanged:(NSNotification *)note {
	
	if (![Connectivity reachabilityChanged:note])
		[self displayWarning];
	
}

- (void) displayWarning {
	
	// Only display warning one time
	if (!hasShownAlert) {
		
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection Failed!", @"Connection Failed") message:NSLocalizedString(@"Unable to connect to the Internet.  Please check whether Airport mode is turned on or move to area where there is better connectivity", @"localize WIFI error") preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
		
		[alertController addAction:alertAction];
		
		[self presentViewController:alertController animated:true completion:nil];
		
	}
	
	hasShownAlert = true;
	
}


@end
