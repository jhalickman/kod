// http://icu.sourceforge.net/apiref/icu4c/uregex_8h.html

#import "ICUPattern.h"
#import "ICUMatcher.h"
#import "NSStringICUAdditions.h"

struct URegularExpression;
/**
* Structure represeting a compiled regular rexpression, plus the results
 *    of a match operation.
 * @draft ICU 3.0
 */
typedef struct URegularExpression URegularExpression;

#define U_HIDE_DRAFT_API 1
#define U_DISABLE_RENAMING 1

#import <unicode/uregex.h>
#import <unicode/ustring.h>

unsigned const ICUCaseInsensitiveMatching = UREGEX_CASE_INSENSITIVE;
unsigned const ICUComments = UREGEX_COMMENTS;
unsigned const ICUDotMatchesAll = UREGEX_DOTALL;
unsigned const ICUMultiline = UREGEX_MULTILINE;
unsigned const ICUUnicodeWordBoundaries = UREGEX_UWORD;

NSString * const ICUPatternException = @"ICUPatternException";

@interface ICUPattern (Private)
-(void)setRe:(URegularExpression *)p;
-(unsigned)flags;
-(UChar *)textToSearch;

@end

@implementation ICUPattern

+(ICUPattern *)patternWithString:(NSString *)aPattern flags:(unsigned)flags {
  return [[self alloc] initWithString:aPattern flags:flags];
}

+(ICUPattern *)patternWithString:(NSString *)aPattern {
  return [[self alloc] initWithString:aPattern flags:0];
}

-(id)initWithString:(NSString *)aPattern flags:(unsigned)f {

  if(![super init])
    return nil;

  textToSearch = NULL;
  flags = f;

  UParseError err;
  UErrorCode status = 0;
  UChar *regexStr = [aPattern UTF16String];
  // uregex_open copies regexStr
  URegularExpression *e = uregex_open(regexStr, -1, flags, &err, &status);

  if(U_FAILURE(status)) {
    [NSException raise:ICUPatternException
          format:@"Could not compile pattern: %s", u_errorName(status)];
  }

  [self setRe:e];

  return self;
}

-(id)initWithString:(NSString *)aPattern {
  return [self initWithString:aPattern flags:0];
}

-(void)finalize {

//  if(re != NULL)
//    NSZoneFree([self zone], re);

  if(textToSearch != NULL)
    free(textToSearch);

  [super finalize];
}

-(NSString *)stringToSearch {
  return [NSString stringWithICUString:[self textToSearch]];
}

-(void)setStringToSearch:(NSString *)aStringToSearchOver {
  NSParameterAssert(aStringToSearchOver);
  UErrorCode status = 0;
  unichar *utf16String = NULL;

  utf16String = [aStringToSearchOver copyUTF16String];
  uregex_setText([self re], utf16String, aStringToSearchOver.length, &status);

  [self reset];

  if(U_FAILURE(status)) {
    if (utf16String) free(utf16String);
    [NSException raise:ICUPatternException
                format:@"Could not set text to match against: %s",
                       u_errorName(status)];
  }

  if(textToSearch)
    free(textToSearch);
  textToSearch = utf16String;
}

-(UChar *)textToSearch {
  return (UChar *)textToSearch;
}

- (id)copyWithZone:(NSZone *)zone {

  ICUPattern *p = [[[self class] allocWithZone:zone] initWithString:[self description] flags:[self flags]];

  UErrorCode status = 0;
  URegularExpression *r = uregex_clone([self re], &status);
  if(U_FAILURE(status))
    [NSException raise:ICUPatternException
          format:@"Could not copy pattern: %s", u_errorName(status)];

  [p setRe:r];

  return p;
}

-(void)reset {
  UErrorCode status = 0;
  uregex_reset([self re], 0, &status);

  if(U_FAILURE(status)) {
    [NSException raise:ICUPatternException
          format:@"Could not reset pattern: %s", u_errorName(status)];
  }
}

-(unsigned)flags {
  return flags;
}

-(NSString *)pattern {
  return [self description];
}

-(void)setRe:(URegularExpression *)p {
  if(re != NULL)
    NSZoneFree([self zone], re);

  re = p;
}

-(void *)re {
  return re;
}

-(NSString *)description {

  if (re != NULL) {
    UChar *p = NULL;
    UErrorCode status = 0;
    int32_t len = 0;
    p = (UChar *)uregex_pattern(re, &len, &status);

    if(U_FAILURE(status)) {
      [NSException raise:ICUPatternException
                  format:@"Could not get pattern text from pattern."];
    }

    // nasty bug in libicu where len is not properly set
    if (len == -1) {
      // the string is null terminated, so fast-forward until null
      len = 0;
      unichar *ptr = p;
      for (; *ptr++; );
      len = (ptr-1)-p;
    }

    return [NSString stringWithCharacters:p length:len];
  }

  return nil;
}

-(NSArray *)componentsSplitFromString:(NSString *)stringToSplit
{
  [self setStringToSearch:stringToSplit];
  BOOL isDone = NO;
  UErrorCode status = 0;

  NSMutableArray *results = [NSMutableArray array];
  int destFieldsCapacity = 16;
  size_t destCapacity = u_strlen([self textToSearch]);

  while(!isDone) {
    UChar *destBuf = (UChar *)NSZoneCalloc([self zone], destCapacity, sizeof(UChar));
    int requiredCapacity = 0;
    UChar *destFields[destFieldsCapacity];
    int numberOfComponents = uregex_split([self re],
                        destBuf,
                        destCapacity,
                        &requiredCapacity,
                        destFields,
                        destFieldsCapacity,
                        &status);

    if(status == U_BUFFER_OVERFLOW_ERROR) { // buffer was too small, grow it
      NSZoneFree([self zone], destBuf);
      NSAssert(destCapacity * 2 < INT_MAX, @"Overflow occurred splitting string.");
      destCapacity = (destCapacity < requiredCapacity) ? requiredCapacity : destCapacity * 2;
      status = 0;
    } else if(destFieldsCapacity == numberOfComponents) {
      destFieldsCapacity *= 2;
      NSAssert(destFieldsCapacity *2 < INT_MAX, @"Overflow occurred splitting string.");
      NSZoneFree([self zone], destBuf);
      status = 0;
    } else if(U_FAILURE(status)) {
      NSZoneFree([self zone], destBuf);
      isDone = YES;
    } else {
      int i;

      for(i=0; i<numberOfComponents; i++) {
        NSAssert(i < destFieldsCapacity, @"Unexpected number of components found in split.");
        UChar *offsetStart = destFields[i];
        [results addObject:[NSString stringWithICUString:offsetStart]];
      }
      isDone = YES;
    }
  }

  if(U_FAILURE(status))
    [NSException raise:ICUPatternException
          format:@"Unable to split string: %@", u_errorName(status)];

  return [NSArray arrayWithArray:results];
}

-(BOOL)matchesString:(NSString *)stringToMatchAgainst {
  ICUMatcher *m = [ICUMatcher matcherWithPattern:self overString:stringToMatchAgainst];
  return [m matches];
}

@end
