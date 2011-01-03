#import "common.h"
#import "KKodURLHandler.h"
#import "KFileURLHandler.h"
#import "KLangMap.h"
#import "kconf.h"
#import "kod_version.h"
#import "KDocumentController.h"
#import "KFileTreeNodeData.h"

@interface NSURL (kod_uri)
- (NSString*)kodURICommand;
@end
@implementation NSURL (kod_uri)

- (NSString*)kodURICommand {
  return [[self relativeString] substringFromIndex:4]; // "kod:"...
}

@end



@implementation KKodURLHandler


- (id)init {
  if (!(self = [super init])) return nil;

  commandToFileResource_ = [[NSDictionary alloc] initWithObjectsAndKeys:
      @"about.md", @"about",
      @"changelog", @"changelog",
      nil];

  return self;
}


- (BOOL)canReadURL:(NSURL*)url {
  if ([[url scheme] caseInsensitiveCompare:@"kod"] == NSOrderedSame) {
    // supported commands
    NSString *cmd = [[url kodURICommand] lowercaseString];
    return [commandToFileResource_ objectForKey:cmd] != nil;
  }
  return NO;
}


- (void)readURL:(NSURL*)url ofType:(NSString*)typeName inTab:(KDocument*)tab{
  NSString *cmd = [[url kodURICommand] lowercaseString];
  NSString *fileResourceRelPath = [commandToFileResource_ objectForKey:cmd];
  kassert(fileResourceRelPath != nil);

  NSURL *fileURL = kconf_res_url(fileResourceRelPath);
  KDocumentController *documentController = [KDocumentController kodController];
  KFileURLHandler *fileURLHandler =
      (KFileURLHandler*)[documentController urlHandlerForURL:fileURL];
  kassert(fileURLHandler != nil);
  tab.isEditable = NO;

  // guess langId
  tab.langId = [[KLangMap sharedLangMap] langIdForSourceURL:fileURL
                                                    withUTI:nil
                                       consideringFirstLine:nil];

  // delegate reading to the file url handler
  [fileURLHandler readURL:fileURL
                   ofType:nil
                    inTab:tab
          successCallback:^{
    // substitute placeholders
    NSString *str = [tab.textView string];
    str = [str stringByReplacingOccurrencesOfString:@"$VERSION"
                                         withString:@K_VERSION_STR];
    [tab.textView setString:str];

    // set cursor to 0,0 (has the side-effect of hiding it)
    [tab.textView setSelectedRange:NSMakeRange(0, 0)];

    // Clear change count
    [tab updateChangeCount:NSChangeCleared];

    // set the icon to the app icon
    tab.icon = [NSImage imageNamed:@"kod.icns"];
  }];
}

- (BOOL)canBrowseURL:(NSURL*)url {
	return [url isFileURL];
}

- (BOOL)isDirectoryURL:(NSURL*)url {
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL directory = NO;
	return [url isFileURL] && [fm fileExistsAtPath:[url path] isDirectory:&directory] && directory;
}

-(void)loadContentsOfURL:(NSURL *)absoluteURL 
				  inTree:(KFileTreeController *) tree
{
	NSTreeNode *root = [self treeNodeFromDirectoryAtPath:[absoluteURL path] error:nil];
	[tree setRootTreeNode:root];
}

- (NSTreeNode*)treeNodeFromDirectoryAtPath:(NSString*)path
                                     error:(NSError**)error {
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if (![fm fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
		NSString *msg = [NSString stringWithFormat:@"Not a directory: %@", path];
		*error = [NSError errorWithDomain:NSStringFromClass([isa class])
									 code:0
								 userInfo:[NSDictionary dictionaryWithObject:msg
																	  forKey:NSLocalizedDescriptionKey]];
		return nil;
	}
	
	static NSArray *metaKeys = nil;
	if (!metaKeys) {
		metaKeys = [[NSArray alloc] initWithObjects:
					//NSURLIsRegularFileKey,
					NSURLIsDirectoryKey,
					NSURLIsSymbolicLinkKey,
					//NSURLContentModificationDateKey, NSURLTypeIdentifierKey,
					//NSURLLabelNumberKey, NSURLLabelColorKey,
					NSURLEffectiveIconKey,
					nil];
	}
	
	NSURL *dirurl = [NSURL fileURLWithPath:path isDirectory:YES];
	NSArray *urls = [fm contentsOfDirectoryAtURL:dirurl
					  includingPropertiesForKeys:metaKeys
										 options:NSDirectoryEnumerationSkipsHiddenFiles
										   error:error];
	if (!urls) return nil;
	
	KFileTreeNodeData *nodeData =
	[KFileTreeNodeData fileTreeNodeDataWithPath:[[NSURL fileURLWithPath:path] absoluteString]];
	nodeData.container = YES;
	NSTreeNode *root = [NSTreeNode treeNodeWithRepresentedObject:nodeData];
	NSMutableArray *childNodes = [root mutableChildNodes];
	
	for (NSURL *url in urls) {
		NSDictionary *meta = [url resourceValuesForKeys:metaKeys error:nil];
		if (!meta) continue;
		NSTreeNode *node;
		if ([[meta objectForKey:NSURLIsDirectoryKey] boolValue]) {
			node = [self treeNodeFromDirectoryAtPath:url.path error:error];
			// don't abort on error, but let |error| be assigned and continue with
			// next entry.
			if (node) {
				nodeData = [node representedObject];
			}
		} else {
			nodeData = [KFileTreeNodeData fileTreeNodeDataWithPath:[url absoluteString]];
			node = [NSTreeNode treeNodeWithRepresentedObject:nodeData];
			nodeData.container = NO;
		}
		if (node && nodeData) {
			nodeData.image = [meta objectForKey:NSURLEffectiveIconKey];
			[childNodes addObject:node];
		}
	}
	
	return root;
}
@end
