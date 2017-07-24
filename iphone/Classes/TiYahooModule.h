/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2017 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#ifdef TI_YAHOO

#import <APSHTTPClient/APSHTTPClient.h>
#import "KrollCallback.h"
#import "TiModule.h"

#define YQL_OAUTH

@interface TiYahooModule : TiModule {
#ifdef YQL_OAUTH
  NSString *key;
  NSString *secret;
#endif
}
@end

@interface TiYQLCallback : NSObject<APSHTTPRequestDelegate> {
 @private
  TiYahooModule *module;
  KrollCallback *callback;
}

- (id)initWithCallback:(KrollCallback *)callback module:(TiYahooModule *)module;

@end

#endif
