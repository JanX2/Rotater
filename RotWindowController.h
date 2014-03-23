#import <AppKit/AppKit.h>
#import "RotaterView.h"
#import "MyDocument.h"

@class RotaterView;

@interface RotWindowController : NSWindowController {
  id IBOutlet textView;
  id IBOutlet rotView;
  id IBOutlet mainWindow;
  id IBOutlet prefDrawer;
  id IBOutlet stereoDrawer;
  id IBOutlet textDrawer;
  id IBOutlet conLineWidth;
  id IBOutlet conPointWidth;
  id IBOutlet conStereoAngle;
  id IBOutlet conPerspective;
  id IBOutlet conUpDirection;
  id IBOutlet conUpDirectionX;
  id IBOutlet conUpDirectionY;
  id IBOutlet conUpDirectionZ;
  id IBOutlet conStereoType;
  id IBOutlet conInvert;
  id IBOutlet conChirality;
  id IBOutlet conCenter;
  id IBOutlet conTrackball;
  id IBOutlet conFPS;
  id thedoc;
  long curLineWidth, curPointWidth;
  double curStereoAngle;
  double curPerspective;
  int curUpDirection;
  int curStereoType;
  BOOL curInvert, curChirality, curCenter, curTrackball, curFPS;
}

- (RotaterView *) getrotView;
- (NSScrollView *) gettextView;

- (IBAction)togglePrefs:(id)sender;
- (IBAction)toggleText:(id)sender;
- (IBAction)toggleStereo:(id)sender;


@end
