#import <Cocoa/Cocoa.h>

#define	DEGTORAD  0.01745329252

@interface RotaterView : NSView {
  long numPoints;
  struct pointArray { double x, y, z; int c; }  *thePoints;
  double aM, bM, cM, dM, eM, fM, gM, hM, iM; // main rotation matrix
  NSPoint refPoint;
  long time, time1;
  double rZ, rX;
  double backX, backY, backZ;
  BOOL backrotateme;
  NSTimer *myTimer;
  NSBezierPath *thePath;
  double zoom;
  long rotLineWidth, rotDotWidth;
  long zoomfactor;
  double rotStereoAngle;
  double rotPerspective;
  char lastKeyWas;
  BOOL rotChirality, rotCenter, rotInvert, rotTrackball, rotFPS;
  int rotUpDirection;
  int rotStereoType;
  double AN, BN, CN, DN, EN, FN, GN, HN, IN;
  double AN2, BN2, CN2, DN2, EN2, FN2, GN2, HN2, IN2;
  double currentX, currentZ;
  double midX, midY, midZ, midZoom;
  long spinCount, fps;
  double spinTime[10], spinX[10], spinZ[10];
  NSDate *backDate;
  double backTimer;
  double backTime;
  double fpstimer;
  id IBOutlet fixFPS;
  id IBOutlet fixLineWidth;
}

// so we can use keydowns to rotate image
- (BOOL)acceptsFirstResponder;

// send RotaterView the number of points and a pointer to the data array
- (void)updateRotaterView:(id)sender numPoints:(long)N thePoints:(struct pointArray *)P;

// send RotaterView info needed for centering the object
- (void)updateRotaterViewMidX:(double)mX midY:(double)mY midZ:(double)mZ midZoom:(double)mZoom;

// must tell RotaterView that we are about to close its window so it can stop rotation first
- (void)preparetoclose;

// change things about the image displayed
- (IBAction)resetObject:(id)sender; // should really go to RotWindowController
- (void)LineWidth:(int)thing;
- (void)PointWidth:(int)thing;
- (void)StereoAngle:(double)thing;
- (void)Perspective:(double)thing;
- (void)UpDirection:(int)thing;
- (void)StereoType:(int)thing;
- (void)Invert:(BOOL)thing;
- (void)Chirality:(BOOL)thing;
- (void)Center:(BOOL)thing;
- (void)Trackball:(BOOL)thing;
- (void)FPS:(BOOL)thing;


@end
