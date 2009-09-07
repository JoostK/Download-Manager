// 
// SampleCode.h
// 
#import <Foundation/Foundation.h>
#import "JKDownloadManager.m"

extern NSString *const JKFailedLoadingException;

#define GOOGLE_URL_STRING @"http://www.google.com"
#define TWITTER_URL_STRING @"http://www.twitter.com"

@interface SampleCode : NSObject <JKDownloadManagerDelegate> {
	// I told you it would be without the hassle of NSURLConnection,
	// so no instance variable are needed!
}

// Handlers
- (void)handleGoogleDownload:(JKDownload *)download error:(NSError *)error;
- (void)handleTwitterDownload:(JKDownload *)download error:(NSError *)error;

// Parsers
- (void)parseGoogleData:(NSData *)data;
- (void)parseTwitterData:(NSData *)data;

@end;