#import <Cocoa/Cocoa.h>

/*
// Node CFRunLoop source
class NodeCFRunLoopSource {
  int refcount_;
  #if EV_MULTIPLICITY
  struct ev_loop *evloop_;
  #endif

 public:
  NodeCFRunLoopSource(EV_P) : refcount_(0) {
    #if EV_MULTIPLICITY
    this->evloop_ = loop;
    #endif
  }
  ~NodeCFRunLoopSource() {}
  
  NodeCFRunLoopSource *retain() {
    refcount_++;
    return this;
  }
  
  NodeCFRunLoopSource *release() {
    if ( (--refcount_) == 0 ) {
      delete this;
      return NULL;
    }
    return this;
  }
  
  static const void *cfRetain(const void *_this) {
    if (_this) ((NodeCFRunLoopSource*)_this)->retain();
    DLOG("node: <NodeCFRunLoopSource@%p>: retain", _this);
    return _this;
  }
  
  static void cfRelease(const void *_this) {
    if (_this) ((NodeCFRunLoopSource*)_this)->release();
    DLOG("node: <NodeCFRunLoopSource@%p>: release", _this);
  }
  
  static CFStringRef cfDescription(const void *_this) {
    return CFStringCreateWithFormat(kCFAllocatorDefault, NULL,
                                    CFSTR("<NodeCFRunLoopSource@%p>"), _this);
  }
  
  // invoked when a version 0 CFRunLoopSource object is added to a run loop mode
  static void onSchedule(void *_this, CFRunLoopRef rl, CFStringRef mode) {
    DLOG("node: <NodeCFRunLoopSource@%p>: onSchedule", _this);
  }
  
  // invoked when a version 0 CFRunLoopSource object is removed from a run loop mode
  static void onCancel(void *_this, CFRunLoopRef rl, CFStringRef mode) {
    DLOG("node: <NodeCFRunLoopSource@%p>: onCancel", _this);
  }
  
  // invoked when a message is received on a version 0 CFRunLoopSource object
  static void onPerform(void *_this) {
    DLOG("node: <NodeCFRunLoopSource@%p>: onPerform", _this);
  }
  
  void addToCFRunLoop(CFRunLoopRef rl) {
    CFRunLoopSourceContext rlsrccontext = {
      version:  0, // CFIndex
      info:     this,
      retain:   &this->cfRetain,
      release:   &this->cfRelease,
      copyDescription: &this->cfDescription,
      equal: NULL, //CFRunLoopEqualCallBack
      hash: NULL, //CFRunLoopHashCallBack
      schedule: &this->onSchedule,
      cancel: &this->onCancel,
      perform: &this->onPerform
    };
    CFRunLoopSourceRef source =
        CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &rlsrccontext);
    CFRunLoopAddSource(rl, source, kCFRunLoopCommonModes);
  }
  
  static NodeCFRunLoopSource* createInRunLoop(EV_P_ CFRunLoopRef rl) {
    NodeCFRunLoopSource *_this = new NodeCFRunLoopSource(EV_A);
    _this->addToCFRunLoop(rl);
    return _this->release();  // release our local reference
  }
};

void node_OnStartLoop(EV_P) {
  DLOG("node: Registering in main runloop");
  
  // Get current runloop
  CFRunLoopRef rl = CFRunLoopGetCurrent();
  
  // Create a runloop source
  NodeCFRunLoopSource *rlsrc =
      NodeCFRunLoopSource::createInRunLoop(EV_A_ rl);
}*/

#import "NodeThread.h"

int main(int argc, char *argv[]) {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  // Start node.js thread
  [NodeThread detachNewNodeThreadRunningScript:@"main.js"];
  
  // Start main thread
  return NSApplicationMain(argc,  (const char **) argv);
  
  [pool drain];
}
