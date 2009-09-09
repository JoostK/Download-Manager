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
#import <Foundation/Foundation.h>

extern NSString *const JKDownloadManagerDuplicateStackException;

@class JKDownloadManager, JKDownload;


@protocol JKDownloadManagerDelegate <NSObject>

@optional

/**
 * Called when a download object did finish loading succesfully
 * 
 * @param	id		Download object which did finish loading
 */
- (void)downloadDidFinishLoading:(JKDownload *)download;

/**
 * Called when a download object failed to load
 * 
 * @param	id		Download object which did fail loading
 * @param	id		Error object. Created by the connection object
 */
- (void)download:(JKDownload *)download didFailWithError:(NSError *)error;

/**
 * Called when all downloads in a stack have finished loading.
 * This method will always be sent, even when some downloads did
 * fail loading
 * 
 * @param	id		Shared download manager object
 * @param	id		The name of the stack that did finish downloading
 */
- (void)downloadManager:(JKDownloadManager *)downloadManager didFinishLoadingDownloadsInStack:(NSString *)stackName;

@end


/**
 * The download class interface.
 *
 * @protocol NSCopying	Only the request object is copied. The context pointer stays untouched
 */
@interface JKDownload : NSObject <NSCopying> {
	NSURLRequest *_request;
	NSURLConnection *_connection;
	NSMutableData *_data;
	NSError *_error;
	NSInteger _statusCode;
	id _context;
	
	NSString *_stackName;
	id <JKDownloadManagerDelegate> _delegate; // Weak reference
	BOOL _finished;
}
/**
 * The URL request object which is being performed
 */
@property(nonatomic, readonly) NSURLRequest *request;

/**
 * The connection object performs the request.
 * Do not mess with it's delegate! Pointer will
 * be zeroud out when downloading did finish
 */
@property(nonatomic, readonly) NSURLConnection *connection;

/**
 * The data object which contains the response data
 * This should only be read when the download did finish loading
 */
@property(nonatomic, readonly) NSMutableData *data;

/**
 * An error object which will only been set when an error occured
 */
@property(nonatomic, readonly) NSError *error;

/**
 * The status code of the request. Default of -1
 */
@property(nonatomic, readonly) NSInteger statusCode;

/**
 * A context object which you can use to identify the download
 * or just as a reference pointer to some object
 */
@property(nonatomic, retain) id context;

/**
 * The name of the stack this download is performed in.
 * Will be nil when download is individual
 */
@property(nonatomic, readonly) NSString *stackName;

/**
 * The download's delegate. See the JKDownloadManagerDelegate
 * protocol for all the protocol methods. Weak reference!
 */
@property(nonatomic, readonly) id <JKDownloadManagerDelegate> delegate;

/**
 * A boolean which indicates whether we have finished loading.
 * Will be set to YES even when you cancel the connection using -cancel
 */
@property(nonatomic, readonly, getter=isFinished) BOOL finished;

/**
 * Plain string initializers
 *
 * @param	id		The url string to be downloaded
 * @param	id		Context object to be used for your own reference
 * @return	id		Newly initialized download object
 */
- (JKDownload *)initWithURLString:(NSString *)URLString;
- (JKDownload *)initWithURLString:(NSString *)URLString context:(id)context;

/**
 * Plain URL initializers
 *
 * @param	id		The url object to be downloaded
 * @param	id		Context object to be used for your own reference
 * @return	id		Newly initialized download object
 */
- (JKDownload *)initWithURL:(NSURL *)URL;
- (JKDownload *)initWithURL:(NSURL *)URL context:(id)context;

/**
 * Advanced initializers
 *
 * @param	id		The url request object to be used
 * @param	id		Context object to be used for your own reference
 * @return	id		Newly initialized download object
 */
- (JKDownload *)initWithURLRequest:(NSURLRequest *)request;
- (JKDownload *)initWithURLRequest:(NSURLRequest *)request context:(id)context;

/**
 * Autoreleased class methods
 *
 * @return	id		An autoreleased download object
 */
+ (JKDownload *)downloadWithURLString:(NSString *)URLString;
+ (JKDownload *)downloadWithURLString:(NSString *)URLString context:(id)context;
+ (JKDownload *)downloadWithURL:(NSURL *)URL;
+ (JKDownload *)downloadWithURL:(NSURL *)URL context:(id)context;
+ (JKDownload *)downloadWithURLRequest:(NSURLRequest *)request;
+ (JKDownload *)downloadWithURLRequest:(NSURLRequest *)request context:(id)context;

/**
 * Tell the download object to begin downloading.
 *
 * @param	id		Delegate object, must conform to the JKDownloadManagerDelegate protocol
 * @return	void
 */
- (void)performWithDelegate:(id <JKDownloadManagerDelegate>)delegate;

/**
 * Cancel downloading process. This will set the finished flag to YES.
 * You cannot use the download object again, you have to copy it
 *
 * @return	void
 */
- (void)cancel;

@end


@interface JKDownloadManager : NSObject {
	NSMutableDictionary *_stack;
	NSMutableDictionary *_queue;
#if TARGET_OS_IPHONE
	NSInteger _numberOfDownloads;
#endif
}

/**
 * The shared download manager handles multiple downloads at once
 *
 * @return	id		Shared download manager
 */
+ (JKDownloadManager *)sharedManager;

/**
 * Same as calling -[JKDownload performWithDelegate:]
 *
 * @param	id		The download object to be performed
 * @param	id		The delegate of the download object
 * @return	void
 */
- (void)performDownload:(JKDownload *)download withDelegate:(id <JKDownloadManagerDelegate>)delegate;

/**
 * Perform multiple downloads at once
 *
 * @param	id		Array of download objects to be performed at one time. Will be copied, array will become immutable
 * @param	id		Delegate of the download objects
 * @param	id		The name of the stack. Can be used to cancel all downloads in a stack at once
 * @return	void
 */
- (void)performDownloads:(NSArray *)downloads withDelegate:(id <JKDownloadManagerDelegate>)delegate inStack:(NSString *)stackName;

/**
 * Add a download object to a queue without starting the downloading process immediately
 * You may want to use this if you had a loop to parse different URLs, so you can hold
 * them in the manager instead of managing them yourself in an NSMutableArray. You can
 * add a download to a queue which has already begun downloading, but it will not be
 * performed in the same loop.
 * 
 * @param	id		Download object to be added to the stack
 * @param	id		The name of the queue the object should be added to
 * @return	void
 */
- (void)addDownload:(JKDownload *)download toQueue:(NSString *)queue;

/**
 * Start downloading all the downloads in a queue. This will empty the queue so you
 * are able to add new downloads to the same queue, but you will not be able to perform
 * that queue until all the previous downloads in the queue have finished downloads.
 * This method calls -[JKDownloadManager performDownloads:withDelegate:inStack:] with
 * stackName set to the name of the queue, so you can read the stackName property
 * to be able to identify your downloads
 * 
 * @param	id		The name of the queue which should begin downloading
 * @param	id		Delegate of the download objects
 * @return	void
 */
- (void)performDownloadsInQueue:(NSString *)queue withDelegate:(id <JKDownloadManagerDelegate>)delegate;

/**
 * Cancel all the downloads in a stack at once. This will NOT call the delegate
 * that it has finished downloading all the downloads in the stack.
 *
 * @param	id		The name of the stack of which all downloads should be cancelled
 * @return	void
 */
- (void)cancelDownloadsWithinStack:(NSString *)stackName;

/**
 * Get the array of download objects in the given stack
 *
 * @param	id		The name of the stack
 * @return	id		Array which contains all the download objects
 */
- (NSArray *)downloadsInStack:(NSString *)stackName;

/**
 * Get the array of download objects in the given queue
 *
 * @param	id		The name of the queue
 * @return	id		Array which contains all the download objects
 */
- (NSArray *)downloadsInQueue:(NSString *)queue;

@end
