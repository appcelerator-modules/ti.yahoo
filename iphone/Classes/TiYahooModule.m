/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2017 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#ifdef TI_YAHOO

#import "TiYahooModule.h"
#include <CommonCrypto/CommonHMAC.h>
#include "Base64Transcoder.h"
#import "SBJSON.h"
#import "TiApp.h"

#ifdef YQL_OAUTH
const NSString *apiEndpoint = @"http://query.yahooapis.com/v1/yql?format=json";
#else
const NSString *apiEndpoint = @"http://query.yahooapis.com/v1/public/"
                              @"yql?format=json&env=http%3A%2F%2Fdatatables.org%2Falltables.env";
#endif

@implementation TiYahooModule

#pragma mark Internal

- (id)moduleGUID {
  return @"cc72dfef-6e0d-4fe0-95df-14a11b408675";
}

- (NSString *)moduleId {
  return @"ti.yahoo";
}

- (NSString *)encode:(NSString *)str {
  return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

#ifdef YQL_OAUTH
- (NSString *)timestamp {
  return [NSString stringWithFormat:@"%ld", time(NULL)];
}

- (NSString *)hmac:(NSString *)key_ data:(NSString *)data_ {
  const char *secretData = [key_ cStringUsingEncoding:NSASCIIStringEncoding];
  const char *clearTextData = [data_ cStringUsingEncoding:NSASCIIStringEncoding];

  unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];

  CCHmac(kCCHmacAlgSHA256, secretData, strlen(secretData), clearTextData, strlen(clearTextData),
         cHMAC);

  return [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)]
                               encoding:NSUTF8StringEncoding];
}
#endif

- (void)setOAuthParameters:(id)args {
#ifdef YQL_OAUTH
  key = [TiUtils stringValue:[args objectAtIndex:0]];
  secret = [TiUtils stringValue:[args objectAtIndex:1]];
#endif
}

- (void)yql:(id)args {
#ifndef __clang_analyzer__
  ENSURE_ARG_COUNT(args, 2);

  NSString *apiQuery = [args objectAtIndex:0];
  KrollCallback *callback = [args objectAtIndex:1];

  ENSURE_TYPE(callback, KrollCallback);

#ifdef YQL_OAUTH
  NSUInteger location = [apiEndpoint rangeOfString:@"?"].location;
  NSString *url = [apiEndpoint substringToIndex:location];
  NSString *theHeader = [apiEndpoint substringFromIndex:location + 1];

  NSMutableString *theBody = [[NSMutableString alloc] init];
  [theBody appendFormat:@"&oauth_consumer_key=%@", key];
  [theBody appendFormat:@"&oauth_nonce=%@", [[NSUUID UUID] UUIDString]];
  [theBody appendString:@"&oauth_signature_method=HMAC-SHA1"];
  [theBody appendFormat:@"&oauth_timestamp=%@", [self timestamp]];
  [theBody appendString:@"&oauth_version=1.0"];
  [theBody appendFormat:@"&q=%@", [self encode:apiQuery]];

  NSString *theData = [NSString stringWithFormat:@"GET&%@&%@%@", [self encode:url],
                                                 [self encode:theHeader], [self encode:theBody]];
  NSString *theSig = [self hmac:[NSString stringWithFormat:@"%@&", secret] data:theData];
  NSString *theurl = [NSString
      stringWithFormat:@"%@%@&oauth_signature=%@", apiEndpoint, theBody, [self encode:theSig]];
#else
  NSString *theurl = [NSString stringWithFormat:@"%@&q=%@", apiEndpoint, [self encode:apiQuery]];
#endif

  TiYQLCallback *job = [[TiYQLCallback alloc] initWithCallback:callback module:self];
  APSHTTPRequest *req = [[APSHTTPRequest alloc] init];
  [req setMethod:@"GET"];
  [req setUrl:[NSURL URLWithString:theurl]];
  [req addRequestHeader:@"User-Agent" value:[[TiApp app] userAgent]];
  [[TiApp app] startNetwork];
  [req setDelegate:job];
  TiThreadPerformOnMainThread(
      ^{
        [req send];
      },
      NO);
#endif
}

@end

@implementation TiYQLCallback

- (id)initWithCallback:(KrollCallback *)callback_ module:(TiYahooModule *)module_ {
  // Ignore analyzer warning here. Delegate will call autorelease onLoad or onError.
  if (self = [super init]) {
    callback = callback_;
    module = module_;
  }
  return self;
}

#pragma mark Delegates

- (void)request:(APSHTTPRequest *)request onLoad:(APSHTTPResponse *)response {
  [[TiApp app] stopNetwork];

  NSString *responseString = [response responseString];
  NSError *error = nil;
  id result = [TiUtils jsonParse:responseString error:&error];
  NSMutableDictionary *event;

  if (error == nil) {
    NSDictionary *errorDict = [result objectForKey:@"error"];
    int code = (errorDict != nil) ? -1 : 0;
    NSString *message = [errorDict objectForKey:@"description"];
    event = [TiUtils dictionaryWithCode:code message:message];

    if (errorDict != nil) {
      [event setObject:message forKey:@"message"];
    } else {
      [event setObject:[[result objectForKey:@"query"] objectForKey:@"results"] forKey:@"data"];
    }
  } else {
    NSString *message = [TiUtils messageFromError:error];
    event = [TiUtils dictionaryWithCode:[error code] message:message];
    [event setObject:message forKey:@"message"];
  }

  [module _fireEventToListener:@"yql" withObject:event listener:callback thisObject:nil];
}

- (void)request:(APSHTTPRequest *)request onError:(APSHTTPResponse *)response {
  [[TiApp app] stopNetwork];

  NSError *error = [response error];
  NSMutableDictionary *event =
      [TiUtils dictionaryWithCode:[error code] message:[TiUtils messageFromError:error]];
  [module _fireEventToListener:@"yql" withObject:event listener:callback thisObject:nil];
}

@end

#endif
