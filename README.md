# Titanium Yahoo Module

Use the Yahoo API in Appcelerator Titanium. This module was moved out of the Titanium 
core-namespace "Ti.Yahoo" into an own module.

## Features

### `yql(yqlQuery: String, callback: Function)`

Invoke a new Yahoo YQL query.

## Example

```js
import Yahoo from 'ti.yahoo';

const query = 'SELECT * FROM xml WHERE url="http://news.yahoo.com/rss/topstories"';

Yahoo.yql(query, (event) => {
  console.log(event);
});
```

## Support

Use [JIRA](http://jira.appcelerator.org) to report issues or ask our [TiSlack community](http://tislack.org) for help! :rocket:

## Contributors

* Please see https://github.com/appcelerator-modules/ti.yahoo/graphs/contributors
* Interested in contributing? Read the [contributors/committer's](https://wiki.appcelerator.org/display/community/Home) guide.

## Legal

This module is Copyright (c) 2010-Present by Appcelerator, Inc. All Rights Reserved. Usage of this module is subject to 
the Terms of Service agreement with Appcelerator, Inc.  
