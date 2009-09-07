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
#import "AppController.h"


@interface JKDownload (Internal)

- (void)_setStackId:(NSString *)stackId;
- (void)_openConnection;
- (void)_resetConnection;

@end



@interface JKDownloadManager (Internal)

- (void)_downloadDidFinish:(JKDownload *)download;

@end





@implementation JKDownload

@synthesize request = _request, context = _context, connection = _connection, data = _data, error = _error,
			statusCode = _statusCode, stackId = _stackId, delegate = _delegate, finished = _finished;

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
	// Done with this connection
	[self _resetConnection];
	
	// Store error
	[_error release];
	_error = [error retain];
	
	// Call delegate
	if([_delegate respondsToSelector:@selector(download:didFailWithError:)]){
		[_delegate download:self didFailWithError:_error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// Done with this connection
	[self _resetConnection];
	
	// Call delegate
	if([_delegate respondsToSelector:@selector(downloadDidFinishLoading:)]){
		[_delegate downloadDidFinishLoading:self];
	}
}

#pragma mark -

- (void)dealloc {
	[self cancel];
	
	[_request release], _request = nil;
	[_connection release], _connection = nil;
	[_data release], _data = nil;
	[_error release], _error = nil;
	[_context release], _context = nil;
	[_stackId release], _stackId = nil;
	
	[super dealloc];
}

@end


#pragma mark -
#pragma mark Internal


@implementation JKDownload (Internal)

- (void)_setStackId:(NSString *)stackId {
	if(stackId != _stackId){
		[_stackId release];
		_stackId = [stackId retain];
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
	[[AppController sharedController] incrementNumberOfConnections];
}

- (void)_resetConnection {
	if(_connection != nil){
		// Mark as finished
		_finished = YES;
		[[JKDownloadManager sharedManager] _downloadDidFinish:self];
		
		// Release connection
		[_connection cancel];
		[_connection release], _connection = nil;
		[[AppController sharedController] decrementNumberOfConnections];
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

- (void)performDownloads:(NSArray *)downloads withDelegate:(id <JKDownloadManagerDelegate>)delegate stackId:(NSString *)stackId {
	// Stack id must not be nil
	if(stackId == nil){
		[NSException raise:NSInvalidArgumentException format:@"%s: stackId must not be nil.", __PRETTY_FUNCTION__];
	}
	
	// Create stack object
	if(_stack == nil){
		_stack = [[NSMutableDictionary alloc] init];
	}
	
	// Add objects to stack
	[_stack setObject:downloads forKey:stackId];
	
	// Cycle through downloads
	for(JKDownload *download in downloads){
		[download _setStackId:stackId];
		[download performWithDelegate:delegate];
	}
}

- (void)cancelDownloadsInStackWithId:(NSString *)stackId {
	// Get stack array
	NSArray *stack = [_stack objectForKey:stackId];
	
	// Remove stack from stacks array, so that we will
	// ignore the fact that the download did finish
	[[stack retain] autorelease];
	[_stack removeObjectForKey:stackId];
	
	// Cancel all downloads
	for(JKDownload *download in stack){
		[download cancel];
	}
}

#pragma mark -

- (void)dealloc {
	[_stack release], _stack = nil;
	
	[super dealloc];
}

@end

#pragma mark -
#pragma mark Internal

@implementation JKDownloadManager (Internal)

- (void)_downloadDidFinish:(JKDownload *)download {
	// When the download was not performed within a stack,
	// Ignore the fact that it did finish. The download
	// will call it's delegate itself.
	if(download.stackId == nil) return;
	
	// Get stack array. We have to check whether it is nil,
	// because when all downloads in a stack are being cancelled,
	// we don't want to call our delegate
	NSArray *stack = [_stack objectForKey:download.stackId];
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
			// Remove from stack
			[[stack retain] autorelease];
			[_stack removeObjectForKey:download.stackId];
			
			// Call delegate
			if([download.delegate respondsToSelector:@selector(downloadManager:didFinishLoadingDownloadsInStack:)]){
				[download.delegate downloadManager:self didFinishLoadingDownloadsInStack:stack];
			}
		}
	}
}

@end
