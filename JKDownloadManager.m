/**
 * JKDownloadManager.m
 * 
 * Copyright (c) 2009 Joost Koehoorn
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
#import "JKDownloadManager.h"

NSString *const JKDownloadManagerDuplicateStackException = @"JKDownloadManagerDuplicateStackException";

@interface JKDownload (Internal)

- (void)_setStackName:(NSString *)stackName;
- (void)_openConnection;
- (void)_resetConnection;

@end



@interface JKDownloadManager (Internal)

- (void)_downloadDidFinish:(JKDownload *)download;
- (void)_incrementNumberOfDownloads;
- (void)_decrementNumberOfDownloads;

@end





@implementation JKDownload

@synthesize request = _request, context = _context, connection = _connection, data = _data, error = _error,
			statusCode = _statusCode, stackName = _stackName, delegate = _delegate, finished = _finished;

#pragma mark -
#pragma mark Initialization

- (id)init {
	[self release];
	return nil;
}

- (JKDownload *)initWithURLString:(NSString *)URLString {
	return [self initWithURLString:URLString context:nil];
}

- (JKDownload *)initWithURLString:(NSString *)URLString context:(id)context {
	return [self initWithURL:[NSURL URLWithString:URLString] context:context];
}

- (JKDownload *)initWithURL:(NSURL *)URL {
	return [self initWithURL:URL context:nil];
}

- (JKDownload *)initWithURL:(NSURL *)URL context:(id)context {
	return [self initWithURLRequest:[NSURLRequest requestWithURL:URL] context:context];
}

- (JKDownload *)initWithURLRequest:(NSURLRequest *)request {
	return [self initWithURLRequest:request context:nil];
}

- (JKDownload *)initWithURLRequest:(NSURLRequest *)request context:(id)context {
	if(self = [super init]){
		_request = [request retain];
		_context = [context retain];
		_statusCode = -1;
	}
	
	return self;
}

+ (JKDownload *)downloadWithURLString:(NSString *)URLString {
	return [[[JKDownload alloc] initWithURLString:URLString] autorelease];
}

+ (JKDownload *)downloadWithURLString:(NSString *)URLString context:(id)context {
	return [[[JKDownload alloc] initWithURLString:URLString context:context] autorelease];
}

+ (JKDownload *)downloadWithURL:(NSURL *)URL {
	return [[[JKDownload alloc] initWithURL:URL] autorelease];
}

+ (JKDownload *)downloadWithURL:(NSURL *)URL context:(id)context {
	return [[[JKDownload alloc] initWithURL:URL context:context] autorelease];
}

+ (JKDownload *)downloadWithURLRequest:(NSURLRequest *)request {
	return [[[JKDownload alloc] initWithURLRequest:request] autorelease];
}

+ (JKDownload *)downloadWithURLRequest:(NSURLRequest *)request context:(id)context {
	return [[[JKDownload alloc] initWithURLRequest:request context:context] autorelease];
}

#pragma mark -
#pragma mark NSCopying protocol methods

- (id)copyWithZone:(NSZone *)zone {
	JKDownload *copy = [[[self class] allocWithZone:zone] initWithURLRequest:[_request copy] context:_context];
	
	return copy;
}

#pragma mark -
#pragma mark Implementation

- (void)performWithDelegate:(id <JKDownloadManagerDelegate>)delegate {
	_delegate = delegate;
	[self _openConnection];
}

- (void)cancel {
	[self _resetConnection];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// Set status code when available
	if([response isKindOfClass:[NSHTTPURLResponse class]]){
		_statusCode = [(NSHTTPURLResponse *)response statusCode];
	}
	
	[_data setLength:0];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)received {
	[_data appendData:received];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	// Store error
	[_error release];
	_error = [error retain];
	
	// Call delegate
	if([_delegate respondsToSelector:@selector(download:didFailWithError:)]){
		[_delegate download:self didFailWithError:_error];
	}
	
	// Done with this connection
	[self _resetConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// Call delegate
	if([_delegate respondsToSelector:@selector(downloadDidFinishLoading:)]){
		[_delegate downloadDidFinishLoading:self];
	}
	
	// Done with this connection
	[self _resetConnection];
}

#pragma mark -

- (void)dealloc {
	[self cancel];
	
	[_request release], _request = nil;
	[_connection release], _connection = nil;
	[_data release], _data = nil;
	[_error release], _error = nil;
	[_context release], _context = nil;
	[_stackName release], _stackName = nil;
	
	[super dealloc];
}

@end


#pragma mark -
#pragma mark Internal


@implementation JKDownload (Internal)

- (void)_setStackName:(NSString *)stackName {
	if(stackName != _stackName){
		[_stackName release];
		_stackName = [stackName retain];
	}
}

- (void)_openConnection {
	// Perform only when not finished yet
	if(_finished || _connection != nil) return;
	
	// Create data object
	if(_data == nil){
		_data = [[NSMutableData alloc] init];
	}
	
	// Create connection
	_connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
	[[JKDownloadManager sharedManager] _incrementNumberOfDownloads];
}

- (void)_resetConnection {
	if(_connection != nil){
		// Mark as finished
		_finished = YES;
		
		// Let manager know the download has finished so that it can
		// track the downloads to see whether they all have finished
		[[JKDownloadManager sharedManager] _downloadDidFinish:self];
		
		// Release connection
		[_connection cancel];
		[_connection release], _connection = nil;
		[[JKDownloadManager sharedManager] _decrementNumberOfDownloads];
	}
}

@end


#pragma mark -
#pragma mark JKDownloadManager
#pragma mark -

@implementation JKDownloadManager

static JKDownloadManager *sharedDownloadManagerInstance = nil;

#pragma mark -
#pragma mark Singleton implementation

+ (JKDownloadManager *)sharedManager {
    @synchronized(self){
        if(sharedDownloadManagerInstance == nil){
            [[self alloc] init];
        }
    }
    return sharedDownloadManagerInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self){
        if(sharedDownloadManagerInstance == nil){
            sharedDownloadManagerInstance = [super allocWithZone:zone];
            return sharedDownloadManagerInstance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)release {
    // Ignore, singleton instance
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Implementation

- (void)performDownload:(JKDownload *)download withDelegate:(id <JKDownloadManagerDelegate>)delegate {
	[download performWithDelegate:delegate];
}

- (void)performDownloads:(NSArray *)downloads withDelegate:(id <JKDownloadManagerDelegate>)delegate inStack:(NSString *)stackName {
	// Stack id must not be nil
	if(stackName == nil){
		[NSException raise:NSInvalidArgumentException format:@"%s: stackName must not be nil.", __PRETTY_FUNCTION__];
		return;
	}
	
	// Check whether this stackId is already being used
	if(nil != [_stack objectForKey:stackName]){
		[NSException raise:JKDownloadManagerDuplicateStackException format:@"%s: stack name (%@) already being used.", __PRETTY_FUNCTION__, stackName];
		return;
	}
	
	// Create stack object
	if(_stack == nil){
		_stack = [[NSMutableDictionary alloc] init];
	}
	
	// Add objects to stack. Copy contents to an
	// inmutable array so you cannot add another
	// download when the downloading process has begun
	[_stack setObject:[NSArray arrayWithArray:downloads] forKey:stackName];
	
	// Cycle through downloads
	for(JKDownload *download in downloads){
		[download _setStackName:stackName];
		[download performWithDelegate:delegate];
	}
}

- (void)addDownload:(JKDownload *)download toQueue:(NSString *)queue {
	// Create queue object
	if(_queue == nil){
		_queue = [[NSMutableDictionary alloc] init];
	}
	
	// Get the downloads
	NSMutableArray *downloads = [_queue objectForKey:queue];
	
	// Create the stack when it does not yet exist
	if(downloads == nil){
		downloads = [NSMutableArray array];
		[_queue setObject:downloads forKey:queue];
	}
	
	// Add the download object
	[downloads addObject:download];
}

- (void)performDownloadsInQueue:(NSString *)queue withDelegate:(id <JKDownloadManagerDelegate>)delegate {
	// Get the stack contents
	NSArray *downloads = [_queue objectForKey:queue];
	
	// Perform all the downloads
	if(downloads != nil){
		[self performDownloads:downloads withDelegate:delegate inStack:queue];
	}
	
	// Remove the downloads from the queue
	[_queue removeObjectForKey:queue];
}

- (void)cancelDownloadsWithinStack:(NSString *)stackName {
	// Get stack array
	NSArray *stack = [_stack objectForKey:stackName];
	
	// Remove stack from stacks array, so that we will
	// ignore the fact that the download did finish
	[[stack retain] autorelease];
	[_stack removeObjectForKey:stackName];
	
	// Cancel all downloads
	for(JKDownload *download in stack){
		[download cancel];
	}
}

- (NSArray *)downloadsInStack:(NSString *)stackName {
	return [_stack objectForKey:stackName];
}

- (NSArray *)downloadsInQueue:(NSString *)queue {
	return [_queue objectForKey:queue];
}

#pragma mark -

- (void)dealloc {
	[_stack release], _stack = nil;
	[_queue release], _queue = nil;
	
	[super dealloc];
}

@end

#pragma mark -
#pragma mark Internal

@implementation JKDownloadManager (Internal)

- (void)_downloadDidFinish:(JKDownload *)download {
	// When the download was not performed within a stack,
	// ignore the fact that it did finish. The download
	// itself will call it's delegate.
	if(download.stackName == nil) return;
	
	// Get stack array. We have to check whether it is nil,
	// because when all downloads in a stack are being cancelled,
	// we don't want to call our delegate
	NSArray *stack = [_stack objectForKey:download.stackName];
	if(stack != nil){
		// See whether we have finished all the dowloads in the stack
		BOOL finished = YES;
		for(JKDownload *_download in stack){
			if(_download.finished == NO){
				finished = NO;
				break;
			}
		}
		
		// When finished all downloads
		if(finished){
			// Call delegate
			if([download.delegate respondsToSelector:@selector(downloadManager:didFinishLoadingDownloadsInStack:)]){
				[download.delegate downloadManager:self didFinishLoadingDownloadsInStack:download.stackName];
			}
			
			// Remove from stack
			[_stack removeObjectForKey:download.stackName];
		}
	}
}

- (void)_incrementNumberOfDownloads {
#if TARGET_OS_IPHONE
	_numberOfDownloads++;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
}

- (void)_decrementNumberOfDownloads {
#if TARGET_OS_IPHONE
	_numberOfDownloads = MAX(_numberOfDownloads - 1, 0);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = _numberOfDownloads > 0;
#endif
}

@end
