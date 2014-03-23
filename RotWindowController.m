#import "RotWindowController.h"

@implementation RotWindowController



- (IBAction)togglePrefs:(id)sender {
  NSDrawerState state = [prefDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) [prefDrawer close];
  else [prefDrawer openOnEdge:NSMinXEdge];
}

- (IBAction)toggleStereo:(id)sender {
  NSDrawerState state = [stereoDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) [stereoDrawer close];
  else [stereoDrawer openOnEdge:NSMinYEdge];
}

- (IBAction)toggleText:(id)sender {
  NSDrawerState state = [textDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) [textDrawer close];
  else [textDrawer openOnEdge:NSMaxXEdge];
}



//- (void)windowDidResize:(NSNotification *)notification {
//  NSSize frameSize = [mainWindow frame].size;
//  [prefDrawer setLeadingOffset:0];
//  [prefDrawer setTrailingOffset:frameSize.height - 300];
  //NSBeep();
//}


- (id)init {
    self = [super initWithWindowNibName:@"MyDocument"];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [thedoc windowControllerDidLoadNib:self];
    //[textView setfont];
    //(void)setTypingAttributes:(NSDictionary *)attributes
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL check; int theval;
    
    theval = [defaults integerForKey:@"LineWidth"];
    if (theval < 1 || theval > 15) theval = 1;
    [rotView LineWidth:theval];
    [conLineWidth setIntValue:theval];
    curLineWidth = theval;
    
    theval = [defaults integerForKey:@"PointWidth"];
    if (theval < 1 || theval > 15) theval = 1;
    [rotView PointWidth:theval];
    [conPointWidth setIntValue:theval];
    curPointWidth = theval;

    theval = [defaults floatForKey:@"StereoAngle"];
    if (theval < -10 || theval > 10) theval = 0;
    [rotView StereoAngle:theval];
    [conStereoAngle setFloatValue:theval];
    curStereoAngle = theval;

    theval = [defaults floatForKey:@"Perspective"];
    if (theval < -10 || theval > 10) theval = 0;
    [rotView Perspective:theval];
    [conPerspective setFloatValue:theval];
    curPerspective = theval;

    theval = [defaults integerForKey:@"UpDirection"];
    if (theval < 0 || theval > 2) theval = 0;
    [rotView UpDirection:theval];
    if (theval == 0) [conUpDirectionZ setIntValue:YES]; else [conUpDirectionZ setIntValue:NO];
    if (theval == 1) [conUpDirectionY setIntValue:YES]; else [conUpDirectionY setIntValue:NO];
    if (theval == 2) [conUpDirectionX setIntValue:YES]; else [conUpDirectionX setIntValue:NO];
    curUpDirection = theval;
    
    theval = [defaults integerForKey:@"StereoType"];
    if (theval < 0 || theval > 3) theval = 0;
    [rotView StereoType:theval];
    [conStereoType selectItemWithTag:theval];
    curStereoType = theval;
    
    check = [defaults boolForKey:@"Invert"];
    [rotView Invert:check];
    [conInvert setIntValue:check];
    curInvert = check;
    
    check = [defaults boolForKey:@"Chirality"];
    [rotView Chirality:check];
    [conChirality setIntValue:check];
    curChirality = check;
    
    check = [defaults boolForKey:@"Center"];
    [rotView Center:check];
    [conCenter setIntValue:check];
    curCenter = check;
    
    check = [defaults boolForKey:@"Trackball"];
    [rotView Trackball:check];
    [conTrackball setIntValue:check];
    curTrackball = check;
    
    check = [defaults boolForKey:@"FPS"];
    [rotView FPS:check];
    [conFPS setIntValue:check];
    curFPS = check;
}

- (void)setDocument:(NSDocument *)document {
    [super setDocument:document];
    thedoc = document;
}

- (RotaterView *)getrotView {
    return rotView;
}

- (NSScrollView *)gettextView {
    return textView;
}

- (void)windowWillClose:(NSNotification *)aNotification {
  [rotView preparetoclose];
}

//######################################################################################//

- (void)setLineWidth:(id)sender {
    curLineWidth = [sender intValue];
    [rotView LineWidth:curLineWidth];
}

//######################################################################################//

- (void)setPointWidth:(id)sender {
    curPointWidth = [sender intValue];
    [rotView PointWidth:curPointWidth];
}

//######################################################################################//

- (void)setStereoAngle:(id)sender {
    curStereoAngle = [sender floatValue];
    [rotView StereoAngle:curStereoAngle];
}

//######################################################################################//

- (void)setPerspective:(id)sender {
    curPerspective = [sender floatValue];
    [rotView Perspective:curPerspective];
}

//######################################################################################//

- (void)setUpDirection:(id)sender {
    curUpDirection = [[sender selectedCell] tag];
    [rotView UpDirection:curUpDirection];
}

//######################################################################################//

- (void)setStereoType:(id)sender {
    curStereoType = [[sender selectedCell] tag];
    [rotView StereoType:curStereoType];
}

//######################################################################################//

- (void)setInvert:(id)sender {
    curInvert = [sender state];
    [rotView Invert:curInvert];
}

//######################################################################################//

- (void)setChirality:(id)sender {
    curChirality = [sender state];
    [rotView Chirality:curChirality];
}

//######################################################################################//

- (void)setCenter:(id)sender {
    curCenter = [sender state];
    [rotView Center:curCenter];
}

//######################################################################################//

- (void)setTrackball:(id)sender {
    curTrackball = [sender state];
    [rotView Trackball:curTrackball];
}

//######################################################################################//

- (void)setFPS:(id)sender {
    curFPS = [sender state];
    [rotView FPS:curFPS];
}

//######################################################################################//

- (void)setDefaults:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:curLineWidth forKey:@"LineWidth"];
    [defaults setInteger:curPointWidth forKey:@"PointWidth"];
    [defaults setFloat:curStereoAngle forKey:@"StereoAngle"];
    [defaults setFloat:curStereoAngle forKey:@"StereoAngle"];
    [defaults setFloat:curPerspective forKey:@"Perspective"];
    [defaults setInteger:curUpDirection forKey:@"UpDirection"];
    [defaults setInteger:curStereoType forKey:@"StereoType"];
    [defaults setBool:curInvert forKey:@"Invert"];
    [defaults setBool:curChirality forKey:@"Chirality"];
    [defaults setBool:curCenter forKey:@"Center"];
    [defaults setBool:curTrackball forKey:@"Trackball"];
    [defaults setBool:curFPS forKey:@"FPS"];
}

//######################################################################################//

@end
