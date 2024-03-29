#import <Cocoa/Cocoa.h>
#import "RotaterView.h"
#import "RotWindowController.h"

#define	RotBlockSize  100

@class RotWindowController;

@interface MyDocument : NSDocument {
  NSString *fileContents;
  struct pointArray  *thePoints; // see definition in RotaterView.h
  long numPoints;
  unsigned int maxPoints;
  id textView;
  id rotView;
  RotWindowController *rotController;
}

- (void)scanText:(NSString *)string;

- (IBAction)updatepoints:(id)sender;

@end
