#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "Sign-In-Small---Default" asset catalog image resource.
static NSString * const ACImageNameSignInSmallDefault AC_SWIFT_PRIVATE = @"Sign-In-Small---Default";

/// The "Twitter-Gray-Sign-In" asset catalog image resource.
static NSString * const ACImageNameTwitterGraySignIn AC_SWIFT_PRIVATE = @"Twitter-Gray-Sign-In";

#undef AC_SWIFT_PRIVATE
