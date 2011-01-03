#import "KFileURLHandler.h"
#import "KFileTreeController.h"

@interface KConnectionKitURLHandler : KFileURLHandler {
	KDocument	*myTab;
	NSString	*myType;
	KFileTreeController *myTree;
	NSURL		*myURL;
}

@end
