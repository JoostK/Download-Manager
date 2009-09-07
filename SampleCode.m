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

- (void)awakeFromNib {
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
	JKDownload *twitterObject = [JKDownload downloadWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:TWITTER_URL_STRING]]
														   context:[NSValue valueWithPointer:@selector(handleTwitterDownload:error:)]];
	
	// Perform downloads
	[googleDownload performWithDelegate:self];
	[twitterDownload performWithDelegate:self];
	
	// Performing download may be done like this, this is an alias for the above one:
	// [[JKDownloadManager sharedManager] performDownload:googleDownload withDelegate:self];
	// [[JKDownloadManager sharedManager] performDownload:twitterDownload withDelegate:self];
	
	// ------------------
	// MULTIPLE DOWNLOADS
	// ------------------
	
	// Setup multiple downloads array
	NSArray *downloads = [NSArray arrayWithObjects:
						  [JKDownload downloadWithURLString:GOOGLE_URL_STRING context:[NSValue valueWithPointer:@selector(handleGoogleDownload:error:)]],
						  [JKDownload downloadWithURLString:TWITTER_URL_STRING context:[NSValue valueWithPointer:@selector(handleGoogleDownload:error:)]]
						 ];
	
	// Perform the downloads all at once
	// The stackId must be an NSString object which is being used to store the downloads array in. Passing
	// nil as stackId will throw an NSInvalidArgumentException. You can use this stackId to cancel all the downloads
	// at once. The stack will be deleted from the sharedManager once all downloads have finished downloading.
	// You will then receive -[JKDownloadManagerDelegate downloadManager:didFinishLoadingDownloadsInStack:] to let
	// the delegate know it has finished downloading all the download objects. That method is never being called when
	// -[JKDownloadManager cancelDownloadsInStackWithId:] has been called before all downloads have finished.
	[[JKDownloadManager sharedManager] performDownloads:downloads withDelegate:self stackId:@"SampleDownloads"];
}

#pragma mark -
#pragma mark Handlers

- (void)handleGoogleDownload:(JKDownload *)download error:(NSError *)error {
	// Handle error
	if(error != nil){
		[NSException raise:JKFailedLoadingException format:@"Failed downloading Google data"];
		return;
	}
	
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
	
	// Parse data
	[self parseTwitterData:download.data];
	
	// Twitter specific stuff
}

#pragma mark -
#pragma mark Parser

- (void)parseGoogleData:(NSData *)data {
	// Parsing code
	NSLog(@"Parsing Google data: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
}

- (void)parseTwitterData:(NSData *)data {
	// Parsing code
	NSLog(@"Parsing Twitter data: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
}

#pragma mark -
#pragma mark JKDownloadManagerDelegate methods

- (void)downloadDidFinishLoading:(JKDownload *)download {
	SEL handler = [download.context pointerValue];
	
	// Call the handler with a nil error
	[self performSelector:handler withObject:download withObject:nil];
}

- (void)download:(JKDownload *)download didFailWithError:(NSError *)error {
	SEL handler = [download.context pointerValue];
	
	// Call the handler with the error object
	[self performSelector:handler withObject:download withObject:error];
}

- (void)downloadManager:(JKDownloadManager *)downloadManager didFinishLoadingDownloadsInStack:(NSArray *)downloads {
	// All downloads have finished downloading
	NSLog(@"That's amazing. When you see this message you know all of these downloads have finished:\n\n%@", downloads);
}

@end;