
#import "KConnectionKitURLHandler.h"
#import "KFileTreeNodeData.h"

#import <Connection/Connection.h>

@implementation KConnectionKitURLHandler


#pragma mark -
#pragma mark Reading

- (BOOL)canReadURL:(NSURL*)url {
	return [[url scheme] caseInsensitiveCompare:@"sftp"] == NSOrderedSame || [[url scheme] caseInsensitiveCompare:@"ftp"] == NSOrderedSame;
}

- (void)connection:(id <CKConnection>)con didConnectToHost:(NSString *)host
{
	NSLog(@"Connected to %@", host);
	
}

- (void)connection:(id <CKConnection>)con didDisconnectFromHost:(NSString *)host
{
	NSLog(@"Disconnected from %@", host);

}

- (void)connection:(id <CKConnection>)con didReceiveError:(NSError *)error
{
	
	if (error == nil || [[error userInfo] objectForKey:ConnectionDirectoryExistsKey]) 
	{
		return;
	}
	NSLog(@"%@", error);
	NSAlert *a = [NSAlert alertWithError:error];
	[a runModal];
}

/*- (void)connection:(id <CKConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
	
	NSLog(@"Got auth Challange %@",challenge);
	NSWindowController *pController = [[NSWindowController alloc] 
									   initWithWindowNibName:@"AuthenticationDialog"];
	NSWindow *window = [pController window];
	[NSApp runModalForWindow:window];
	NSLog(@"After show window");
	[[challenge sender] useCredential:[NSURLCredential credentialWithUser:@"" password:@"" persistence:NSURLCredentialPersistenceNone] forAuthenticationChallenge:challenge];
}*/

- (void)transfer:(CKTransferRecord *)transfer receivedError:(NSError *)error {
	NSLog(@"%@", error);
	NSAlert *a = [NSAlert alertWithError:error];
	[a runModal];
}
- (void)transferDidFinish:(CKTransferRecord *)transfer error:(NSError *)error{
	NSLog(@"%@", error);	
	NSString*path = [transfer localPath];
	[super _readURL:[NSURL URLWithString:path] ofType:myType inTab:myTab successCallback:nil];
	myTab.title = [NSString stringWithFormat:@"%@", [[transfer remotePath] lastPathComponent]];
	[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	[[transfer connection] disconnect];
	[myTab release];
	[myType release];
}


- (void)_readURL:(NSURL*)absoluteURL
          ofType:(NSString*)typeName
           inTab:(KDocument*)tab {

	CKHost *myHost = [[CKHost alloc] init];
	[myHost setURL:absoluteURL];
	CKSFTPConnection *conn = [[myHost connection] retain];
	[conn setDelegate:self];
	[conn connect];
	NSString *path = NSTemporaryDirectory();
	CKTransferRecord *record = [conn downloadFile:[myHost initialPath] toDirectory:path overwrite:YES delegate:self];
	NSLog(@"Path: %@",path);				  
	myTab = [tab retain];
	myType = [typeName retain];
}


- (void)readURL:(NSURL*)absoluteURL
         ofType:(NSString*)typeName
          inTab:(KDocument*)tab {
  if ([NSThread isMainThread]) {
    // file I/O is blocking an thus we always read files on a background thread
    K_DISPATCH_BG_ASYNC({
      [self _readURL:absoluteURL ofType:typeName inTab:tab];
    });
  } else {
    // already called on a background thread
    [self _readURL:absoluteURL ofType:typeName inTab:tab];
  }
}


#pragma mark -
#pragma mark Writing


- (BOOL)canWriteURL:(NSURL*)url {
	return [[url scheme] caseInsensitiveCompare:@"sftp"] == NSOrderedSame || [[url scheme] caseInsensitiveCompare:@"ftp"] == NSOrderedSame;
}


- (void)writeData:(NSData*)data
           ofType:(NSString*)typeName
            toURL:(NSURL*)absoluteURL
            inTab:(KDocument*)tab
 forSaveOperation:(NSSaveOperationType)saveOperation
      originalURL:(NSURL*)absoluteOriginalContentsURL
		 callback:(void(^)(NSError *err, NSDate *mtime))callback {
	
	if ([NSThread isMainThread]) {
		// file I/O is blocking an thus we always read files on a background thread
		K_DISPATCH_BG_ASYNC({
			[self _writeData:data ofType:typeName toURL:absoluteURL inTab:tab forSaveOperation:saveOperation originalURL:absoluteOriginalContentsURL];// callback:callback]; 
		});
	} else {
		// already called on a background thread
		[self _writeData:data ofType:typeName toURL:absoluteURL inTab:tab forSaveOperation:saveOperation originalURL:absoluteOriginalContentsURL];// callback:callback]; 
	}
}

- (void)_writeData:(NSData*)data
           ofType:(NSString*)typeName
            toURL:(NSURL*)absoluteURL
            inTab:(KDocument*)tab
 forSaveOperation:(NSSaveOperationType)saveOperation
      originalURL:(NSURL*)absoluteOriginalContentsURL {
        // callback:(void(^)(NSError *err, NSDate *mtime))callback {
  
  
	CKHost *myHost = [[CKHost alloc] init];
	[myHost setURL:absoluteURL];
	CKSFTPConnection *conn = [[myHost connection] retain];
	[conn setDelegate:self];
	[conn connect];
	CKTransferRecord *record = [conn uploadFromData:data toFile:[absoluteURL path] checkRemoteExistence:YES delegate:self];
}

- (BOOL)canBrowseURL:(NSURL*)url {
	return [[url scheme] caseInsensitiveCompare:@"sftp"] == NSOrderedSame || [[url scheme] caseInsensitiveCompare:@"ftp"] == NSOrderedSame;
}

- (BOOL)isDirectoryURL:(NSURL*)url {
	return ![[url path] containsSubstring:@"."];
}

-(void)loadContentsOfURL:(NSURL *)absoluteURL 
				  inTree:(KFileTreeController *) tree
{
	
	CKHost *myHost = [[CKHost alloc] init];
	[myHost setURL:absoluteURL];
	CKSFTPConnection *conn = [[myHost connection] retain];
	[conn setDelegate:self];
	[conn connect];
	[conn contentsOfDirectory:[absoluteURL path]];
	myURL = [absoluteURL retain];
	myTree = [tree retain];
}

- (void)connection:(CKConnectionClient*)connection 
didReceiveContents:(NSArray *)contents 
	   ofDirectory:(NSString *)dirPath 
			 error:(NSError *)error {
	
	if (!contents || [contents count] == 0) return ;
	
	KFileTreeNodeData *nodeData =
	[KFileTreeNodeData fileTreeNodeDataWithPath:dirPath];
	nodeData.container = YES;
	NSTreeNode *root = [NSTreeNode treeNodeWithRepresentedObject:nodeData];
	NSMutableArray *childNodes = [root mutableChildNodes];
	
	for (CKDirectoryListingItem *item in contents) {
		NSTreeNode *node;
		NSString *path = [NSString stringWithFormat:@"%@/%@",[myURL absoluteString], [item filename]];//[NSString pathWithComponents:[NSArray arrayWithObjects:[myURL absoluteString], [item filename], nil]];
		if ([item isDirectory]) {
			//node = [self treeNodeFromDirectoryAtPath:path error:error];
			nodeData = [KFileTreeNodeData fileTreeNodeDataWithPath:path];
			node = [NSTreeNode treeNodeWithRepresentedObject:nodeData];
			nodeData.container = YES;
			// don't abort on error, but let |error| be assigned and continue with
			// next entry.
			//if (node) {
			//	nodeData = [node representedObject];
			//}
		} else {
			nodeData = [KFileTreeNodeData fileTreeNodeDataWithPath:path];
			node = [NSTreeNode treeNodeWithRepresentedObject:nodeData];
			nodeData.container = NO;
		}
		if (node && nodeData) {
			//nodeData.image = [meta objectForKey:NSURLEffectiveIconKey];
			[childNodes addObject:node];
		}
	}
	[myTree setRootTreeNode:root];
	[myTree release];
	[myURL release];
	[connection disconnect];
}

@end
