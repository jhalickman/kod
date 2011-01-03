#import "common.h"
#import "KURLHandler.h"

@implementation KURLHandler


+ (KURLHandler*)handler {
  return [[self new] autorelease];
}


- (BOOL)canReadURL:(NSURL*)url { return NO; }
- (BOOL)canWriteURL:(NSURL*)url { return NO; }
- (BOOL)canBrowseURL:(NSURL*)url { return NO; }

- (void)readURL:(NSURL*)url ofType:(NSString*)typeName inTab:(KDocument*)tab{
  NOTIMPLEMENTED();
}


- (void)writeData:(NSData*)data
           ofType:(NSString*)typeName
            toURL:(NSURL*)url
            inTab:(KDocument*)tab
 forSaveOperation:(NSSaveOperationType)saveOperation
      originalURL:(NSURL*)absoluteOriginalContentsURL
         callback:(void(^)(NSError *err, NSDate *mtime))callback {
  NOTIMPLEMENTED();
}


- (BOOL)isDirectoryURL:(NSURL*)url {
	NOTIMPLEMENTED();
}

-(void)loadContentsOfURL:(NSURL *)absoluteURL 
				  inTree:(KFileTreeController *) tree
{
	NOTIMPLEMENTED();
}
@end
