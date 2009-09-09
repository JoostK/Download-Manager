// 
// SampleCode.h
// 
#import <Foundation/Foundation.h>
#import "JKDownloadManager.h"

extern NSString *const JKFailedLoadingException;

// Predefined URLs
#define GOOGLE_URL_STRING @"http://www.google.com"
#define TWITTER_URL_STRING @"http://www.twitter.com"

// Exception handler
#define BEGIN_EXCEPTION_HANDLING @try {
#define END_EXCEPTION_HANDLING } @catch(NSException *exception){ [self appendToLog:[NSString stringWithFormat:@"NSException raised: %@", exception.reason]]; }

@interface SampleCode : NSObject <JKDownloadManagerDelegate> {
	// GUI elements
	NSWindow *_window;
	NSTextView *_textView;
	NSButton *_clearButton;
	
	// I told you it would be without the hassle of NSURLConnection,
	// so no instance variable for the downloads are needed!
}
@property(assign) IBOutlet NSWindow *window;
@property(assign) IBOutlet NSTextView *textView;
@property(assign) IBOutlet NSButton *clearButton;

- (IBAction)performDownloads:(id)sender;

// Handlers
- (void)handleDownload:(JKDownload *)download error:(NSError *)error;
- (void)handleGoogleDownload:(JKDownload *)download error:(NSError *)error;
- (void)handleTwitterDownload:(JKDownload *)download error:(NSError *)error;

// Parsers
- (void)parseGoogleData:(NSData *)data;
- (void)parseTwitterData:(NSData *)data;

// GUI
- (IBAction)clearLog:(id)sender;
- (void)appendToLog:(NSString *)string;

@end;