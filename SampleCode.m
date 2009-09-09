// 
// SampleCode.m
// 
// Sample code to get started with the class. Shows the
// basic usage of the classes as well as a mechanism which
// you can use to handle your downloads with no extra effort
// 
#import "SampleCode.h"

NSString *const JKFailedLoadingException = @"JKFailedLoadingException";

@implementation SampleCode

@synthesize window = _window, textView = _textView, clearButton = _clearButton;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[self performDownloads:nil];
}

- (IBAction)performDownloads:(id)sender {
	// Setup Google download object
	// There are more initializers available for further setting of the request, see JKDownloadManager.h for details
	// The context being given is a selector value. When the download finishes, we can read the context value and perform the selector
	// so we can write different blocks of code very easily using just one delegate. Context variable is optional but this gives you a
	// very easy way of handling multiple downloads, you will not have to change your delegate methods to adjust your routing mechanism,
	// you will get it all for free, which is always nice I'd think. The error pointer will be nil when downloading went successfully,
	// otherwise it will contain the NSError object.
	JKDownload *googleDownload = [JKDownload downloadWithURLString:GOOGLE_URL_STRING
														   context:[NSValue valueWithPointer:@selector(handleGoogleDownload:error:)]];
	
	// Setup Twitter download object
	// Simplest NSURLRequest being used, but you may ofcourse use any NSURLRequest object. This implementation does not differ from
	// calling +[JKDownload downloadWithURLString:context:] bacause all the 'default' objects are being used.
	JKDownload *twitterDownload = [JKDownload downloadWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:TWITTER_URL_STRING]]
															 context:[NSValue valueWithPointer:@selector(handleTwitterDownload:error:)]];
	
	// Perform downloads
	[googleDownload performWithDelegate:self];
	[twitterDownload performWithDelegate:self];
	
	// Performing download may be done like this, this is an alias for the above (preferred) one:
	// [[JKDownloadManager sharedManager] performDownload:googleDownload withDelegate:self];
	// [[JKDownloadManager sharedManager] performDownload:twitterDownload withDelegate:self];
	
	// ------------------
	// MULTIPLE DOWNLOADS
	// ------------------
	
	// Setup multiple downloads array
	NSArray *downloads = [NSArray arrayWithObjects:
						  [JKDownload downloadWithURLString:GOOGLE_URL_STRING context:[NSValue valueWithPointer:@selector(handleGoogleDownload:error:)]],
						  [JKDownload downloadWithURLString:TWITTER_URL_STRING context:[NSValue valueWithPointer:@selector(handleTwitterDownload:error:)]],
						 nil];
	
	// Perform the downloads all at once
	// The stack name must be an NSString object which is being used to store the downloads array in. Passing
	// nil as stack name will throw an NSInvalidArgumentException. You can use this name to cancel all the downloads
	// at once. The stack will be deleted from the sharedManager once all downloads have finished downloading.
	// You will then receive -[JKDownloadManagerDelegate downloadManager:didFinishLoadingDownloadsInStack:] to let
	// the delegate know it has finished downloading all the download objects. That method is never being called when
	// -[JKDownloadManager cancelDownloadsInStackWithId:] has been called before all downloads have finished.
	BEGIN_EXCEPTION_HANDLING
	
	[[JKDownloadManager sharedManager] performDownloads:downloads withDelegate:self inStack:@"SampleDownloads"];
	
	// This will throw a JKDownloadManagerDuplicateStackException exception because we perform a new stack of
	// downloads using an in use stack name.
	[[JKDownloadManager sharedManager] performDownloads:downloads withDelegate:self inStack:@"SampleDownloads"];
	
	END_EXCEPTION_HANDLING
	
	// -----------------------
	// MULTIPLE DOWNLOADS LOOP
	// -----------------------
	
	// Setup array of URLs to load
	NSArray *URLs = [NSArray arrayWithObjects:GOOGLE_URL_STRING, TWITTER_URL_STRING, nil];
	
	// Create a download object for each URL
	for(NSString *URL in URLs){
		[[JKDownloadManager sharedManager] addDownload:[JKDownload downloadWithURLString:URL
																				 context:[NSValue valueWithPointer:@selector(handleDownload:error:)]]
											   toQueue:@"SampleLoop"];
	}
	
	BEGIN_EXCEPTION_HANDLING
	
	// Perform downloads
	[[JKDownloadManager sharedManager] performDownloadsInQueue:@"SampleLoop" withDelegate:self];
	
	// Performing the downloads in the same queue again will have no result, because
	// the above call will have removed all the download objects from the queue.
	// You can access the downloads using -[JKDownloadManager downloadsInStack:]
	// as long as all the downloads have not finished downloading
	[[JKDownloadManager sharedManager] performDownloadsInQueue:@"SampleLoop" withDelegate:self];
	
	END_EXCEPTION_HANDLING
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

#pragma mark -
#pragma mark Handlers

- (void)handleDownload:(JKDownload *)download error:(NSError *)error {
	// Handle error
	if(error != nil){
		[NSException raise:JKFailedLoadingException format:@"Failed downloading data"];
		return;
	}
	
	// Log
	[self appendToLog:[NSString stringWithFormat:@"Download performed: %@ within stack: %@", download, download.stackName]];
}

- (void)handleGoogleDownload:(JKDownload *)download error:(NSError *)error {
	// Handle error
	if(error != nil){
		[NSException raise:JKFailedLoadingException format:@"Failed downloading Google data"];
		return;
	}
	
	// Log
	[self appendToLog:[NSString stringWithFormat:@"Google download performed: %@ within stack: %@", download, download.stackName]];
	
	// Parse data
	[self parseGoogleData:download.data];
	
	// Google specific stuff
}

- (void)handleTwitterDownload:(JKDownload *)download error:(NSError *)error {
	// Handle error
	if(error != nil){
		[NSException raise:JKFailedLoadingException format:@"Failed downloading Twitter data"];
		return;
	}
	
	// Log
	[self appendToLog:[NSString stringWithFormat:@"Twitter download performed: %@ within stack: %@", download, download.stackName]];
	
	// Parse data
	[self parseTwitterData:download.data];
	
	// Twitter specific stuff
}

#pragma mark -
#pragma mark Parser

- (void)parseGoogleData:(NSData *)data {
	// Parsing code
}

- (void)parseTwitterData:(NSData *)data {
	// Parsing code
}

#pragma mark -
#pragma mark JKDownloadManagerDelegate methods

- (void)downloadDidFinishLoading:(JKDownload *)download {
	BEGIN_EXCEPTION_HANDLING
	
	SEL handler = [download.context pointerValue];
	
	// Call the handler with a nil error
	[self performSelector:handler withObject:download withObject:nil];
	
	END_EXCEPTION_HANDLING
}

- (void)download:(JKDownload *)download didFailWithError:(NSError *)error {
	BEGIN_EXCEPTION_HANDLING
	
	SEL handler = [download.context pointerValue];
	
	// Call the handler with the error object
	[self performSelector:handler withObject:download withObject:error];
	
	END_EXCEPTION_HANDLING
}

- (void)downloadManager:(JKDownloadManager *)downloadManager didFinishLoadingDownloadsInStack:(NSString *)stackName {
	// All downloads have finished downloading
	[self appendToLog:[NSString stringWithFormat:@"All the downloads in the %@ stack have finished:\n\n%@", stackName, [downloadManager downloadsInStack:stackName]]];
}

#pragma mark -
#pragma mark GUI methods

- (IBAction)clearLog:(id)sender {
	_textView.string = @"";
}

- (void)appendToLog:(NSString *)string {
	if(_textView.string == nil || [_textView.string isEqualToString:@""]){
		_textView.string = [NSString stringWithFormat:@"%@:\n\n%@", [NSDate date], string];
	} else {
		_textView.string = [_textView.string stringByAppendingFormat:@"\n-------------------\n%@:\n\n%@", [NSDate date], string];
	}
}

@end;