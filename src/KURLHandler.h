#import "KDocument.h"
#import "KFileTreeController.h"
/*!
 * Lives in the shared KDocumentController instance's urlHandlers_ dict,
 * where URI schemes are mapped to KURLHandler objects.
 */
@interface KURLHandler : NSObject {
}

+ (KURLHandler*)handler;

- (BOOL)canReadURL:(NSURL*)url;
- (BOOL)canWriteURL:(NSURL*)url;
- (BOOL)canBrowseURL:(NSURL*)url;

- (void)readURL:(NSURL*)absoluteURL
         ofType:(NSString*)typeName
          inTab:(KDocument*)tab;

- (void)writeData:(NSData*)data
           ofType:(NSString*)typeName
            toURL:(NSURL*)url
            inTab:(KDocument*)tab
 forSaveOperation:(NSSaveOperationType)saveOperation
      originalURL:(NSURL*)absoluteOriginalContentsURL
         callback:(void(^)(NSError *err, NSDate *mtime))callback;

- (BOOL)isDirectoryURL:(NSURL*)url;
- (void)loadContentsOfURL:(NSURL *)absoluteURL 
				   inTree:(KFileTreeController *) tree;
@end
