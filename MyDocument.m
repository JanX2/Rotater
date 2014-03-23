#import "MyDocument.h"

@implementation MyDocument

//######################################################################################//

- (IBAction)updatepoints:(id)sender; { // read text and put in array
  NSString *rawText;
  rawText = [textView string];
  [self scanText:rawText];
  [rotView updateRotaterView:self numPoints:numPoints thePoints:thePoints];
}

//######################################################################################//

- (void)scanText:(NSString *)string {
  NSCharacterSet *endoflineSet/*, *skipSet*/;
  NSScanner *theScanner, *lineScanner;
  NSString *aLine = @"nuffin";
  double X = 0, Y, Z;
  int C=0;
  long i;
  double max = 0, minX, maxX, minY, maxY, minZ, maxZ, midX, midY, midZ, midZoom;
  double maybe;
  
  numPoints = 0;
  endoflineSet = [NSCharacterSet newlineCharacterSet];
  //skipSet = [NSCharacterSet newlineCharacterSet];
  theScanner = [NSScanner scannerWithString:string];
  //[theScanner setCharactersToBeSkipped:skipSet];
  while ([theScanner isAtEnd] == NO) {
    if ([theScanner scanUpToCharactersFromSet:endoflineSet intoString:&aLine]) {
      if ([aLine characterAtIndex:0] != '#') {
        lineScanner = [NSScanner scannerWithString:aLine];
        if ([lineScanner scanDouble:&X] && [lineScanner scanDouble:&Y] &&
            [lineScanner scanDouble:&Z]) {
          if (![lineScanner scanInt:&C]) C = -7;
          if (numPoints == maxPoints) {
            maxPoints += RotBlockSize;
            thePoints = NSZoneRealloc(nil, thePoints, sizeof(struct pointArray)*maxPoints);
          }
          thePoints[numPoints].x = X;
          thePoints[numPoints].y = Y;
          thePoints[numPoints].z = Z;
          thePoints[numPoints].c = C;
          numPoints++;
        }
      }
    }
  }
  minX = 0; maxX = 0; minY = 0; maxY = 0; minZ = 0; maxZ = 0; max = 0;
  for (i=0;i<numPoints;i++) {
    maybe = sqrt(thePoints[i].x * thePoints[i].x + thePoints[i].y * thePoints[i].y +
            thePoints[i].z * thePoints[i].z);
    if (maybe > max) max = maybe;
    if (i == 0) {
      minX = thePoints[i].x;
      maxX = thePoints[i].x;
      minY = thePoints[i].y;
      maxY = thePoints[i].y;
      minZ = thePoints[i].z;
      maxZ = thePoints[i].z;
    }
    if (thePoints[i].x < minX) minX = thePoints[i].x;
    if (thePoints[i].x > maxX) maxX = thePoints[i].x;
    if (thePoints[i].y < minY) minY = thePoints[i].y;
    if (thePoints[i].y > maxY) maxY = thePoints[i].y;
    if (thePoints[i].z < minZ) minZ = thePoints[i].z;
    if (thePoints[i].z > maxZ) maxZ = thePoints[i].z;
  }
  midX = (minX + maxX) / 2;
  midY = (minY + maxY) / 2;
  midZ = (minZ + maxZ) / 2;
  midZoom = 1;
  if (max != 0) { // cannot scale points at origin
    midX /= max; midY /= max; midZ /= max;
    midZoom = 0;
    for (i=0;i<numPoints;i++) {
      thePoints[i].x = (thePoints[i].x / max);
      thePoints[i].y = (thePoints[i].y / max);
      thePoints[i].z = (thePoints[i].z / max);
      maybe = sqrt((thePoints[i].x-midX) * (thePoints[i].x-midX) +
        (thePoints[i].y-midY) * (thePoints[i].y-midY) +
        (thePoints[i].z-midZ) * (thePoints[i].z-midZ));
      if (maybe > midZoom) midZoom = maybe;
    }
  }
  //else  max = 1;
  if (midZoom == 0) midZoom = 1;
  [rotView updateRotaterViewMidX:midX midY:midY midZ:midZ midZoom:midZoom];
}

//######################################################################################//

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError
{
  // Read text as UTF-8.
  fileContents = [[NSString alloc] initWithData:data
                                       encoding:NSUTF8StringEncoding];
  
  if (fileContents != nil) {
    // Fall back to MacRoman.
    fileContents = [[NSString alloc] initWithData:data
                                         encoding:NSMacOSRomanStringEncoding];
  }
  
  if (fileContents != nil) {
    return YES;
  }
  else {
    *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSFileReadCorruptFileError
                                userInfo:nil];
    return NO;
  }
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController { // load text
  [super windowControllerDidLoadNib:aController];
  rotView = [rotController getrotView];
  textView = [rotController gettextView];
  if ( fileContents != nil ) {
    [textView setString:fileContents];
    [self updatepoints:self];
  }
}

//######################################################################################//

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError **)outError;
{
  // Save to text.
  NSData *data = [[textView string] dataUsingEncoding:NSUTF8StringEncoding];
  return data;
}

//######################################################################################//

- (id)init {
  if (!(self = [super init]))  return nil;
  numPoints = 0;
  //thePoints = (struct pointArray *) malloc(10000000); // Fix Me
  maxPoints = RotBlockSize;
  thePoints = (struct pointArray *) NSZoneMalloc(nil, sizeof(struct pointArray)*maxPoints);
  return self;
}

//######################################################################################//

- (void)dealloc {
  NSZoneFree(nil, thePoints);
}

- (NSString *)windowNibName {
  return @"MyDocument";
}

//######################################################################################//

- (void)makeWindowControllers {
  rotController = [[RotWindowController alloc] init];
  [self addWindowController:rotController];
  [rotController setDocument:self];
}

//######################################################################################//
// Straight from the Docs
- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath
    ofType:(NSString *)documentTypeName
    saveOperation:(NSSaveOperationType)saveOperationType
{
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *creatorCodeString;
    NSArray *documentTypes;
    NSNumber *typeCode, *creatorCode;
    NSMutableDictionary *newAttributes;
    
    typeCode = creatorCode = nil;
    
    // First, set creatorCode to the HFS creator code for the application,
    // if it exists.
    creatorCodeString = [infoPlist objectForKey:@"CFBundleSignature"];
    if(creatorCodeString)
    {
        creatorCode = [NSNumber
            numberWithUnsignedLong:NSHFSTypeCodeFromFileType([NSString
            stringWithFormat:@"'%@'",creatorCodeString])];
    }
    
    // Then, find the matching Info.plist dictionary entry for this type.
    // Use the first associated HFS type code, if any exist.
    documentTypes = [infoPlist objectForKey:@"CFBundleDocumentTypes"];
    if(documentTypes)
    {
        int i, count = [documentTypes count];
        
        for(i = 0; i < count; i++)
        {
            NSString *type = [[documentTypes objectAtIndex:i]
                objectForKey:@"CFBundleTypeName"];
            if(type && [type isEqualToString:documentTypeName])
            {
                NSArray *typeCodeStrings = [[documentTypes objectAtIndex:i]
                    objectForKey:@"CFBundleTypeOSTypes"];
                if(typeCodeStrings)
                {
                    NSString *firstTypeCodeString = [typeCodeStrings
                        objectAtIndex:0];
                    if (firstTypeCodeString)
                    {
                        typeCode = [NSNumber numberWithUnsignedLong:
                           NSHFSTypeCodeFromFileType([NSString
                           stringWithFormat:@"'%@'",firstTypeCodeString])];
                    }
                }
                break;
            }
        }
    }

    // If neither type nor creator code exist, use the default implementation.
    if(!(typeCode || creatorCode))
    {
        return [super fileAttributesToWriteToFile:fullDocumentPath
            ofType:documentTypeName saveOperation:saveOperationType];
    }
    
    // Otherwise, add the type and/or creator to the dictionary.
    newAttributes = [NSMutableDictionary dictionaryWithDictionary:[super
        fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName
        saveOperation:saveOperationType]];
    if(typeCode)
        [newAttributes setObject:typeCode forKey:NSFileHFSTypeCode];
    if(creatorCode)
        [newAttributes setObject:creatorCode forKey:NSFileHFSCreatorCode];
    return newAttributes;
}

//######################################################################################//

@end
