#import "RotaterView.h"

@implementation RotaterView

//######################################################################################//

// Feel free to use bits of this this code for what it is worth
// Hey I am just learning this stuff so give me a break :-)

// Craig Kloeden 13 March 2002 <craig@kloeden.net>

// TO DO
// constant velocity grab and spin
// Figure a way around the triple buffering
//    - anyone know how to get directly to the bitmap of the backing store for the window?
// Remove duplicated variables in the horror rotation code
// Do rendered points
// Fix the damn memory leaks
// Have aqua drawing option for display
// Help
// Set a monospaced font programatically in the text display - seems impossible
// Stereo viewing options
// FPS Reading

//######################################################################################//

- (void)drawRect:(NSRect)rect {
  long i, aCom, j, k, C, /*pos, */x, y;
  long XX, XXold=0, YY, YYold=0, DD, DDold=0;
  NSPoint zero;
  double X, Y, Z, X3, Y3, Z3, /*X32, Y32, Z32, */wzoom, T;
  double  mWidth, mHeight;
  NSRect viewBounds = [self bounds];
  double tempPerspec;
  float colDepth;
  Byte R, G, B;
  Byte *zBuffer;
  NSInteger rotRowBytes = viewBounds.size.width * 3; //////////
  long wWidth = viewBounds.size.width;
  long wHeight = viewBounds.size.height;
  NSBitmapImageRep *rotBitMap;
  //unsigned char *rotBitMapData;
  NSImage *rotImage;
  double Xr2, Yr2, Zr2;
  double CZ2, SZ2, CY2, SY2, CX2, SX2;
  double AM2, BM2, CM2, DM2, EM2, FM2, GM2, HM2, IM2;
	NSSize asize;
	asize.width = viewBounds.size.width;
	asize.height = viewBounds.size.height;
	//NSPoint start, end;
	NSUInteger bing[3];
	
  long zBuffSize = wWidth*wHeight;
  if (zBuffSize < 132000) zBuffSize = 132000; // so it is clear - go figure
  zBuffer = (Byte *) NSZoneCalloc(nil, zBuffSize, 1);

	
	rotBitMap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
    pixelsWide:viewBounds.size.width
    pixelsHigh:viewBounds.size.height
    bitsPerSample:8
    samplesPerPixel:3
    hasAlpha:NO
    isPlanar:NO
    colorSpaceName:NSDeviceRGBColorSpace
    bytesPerRow:rotRowBytes //rotRowBytes
    bitsPerPixel:24];
	
	
  //rotBitMapData = [rotBitMap bitmapData];
	
	rotImage = [[NSImage alloc] initWithSize:viewBounds.size];
	
	
	[[NSColor blackColor] set];
	
	//NSRectFill([self bounds]);
	
	
  [rotImage addRepresentation:rotBitMap]; // FAILS #########################
  
	//mWidth = 10;
	//mWidth = 10;
	
	mWidth  = NSMidX (viewBounds);
	mHeight = NSMidY (viewBounds);
  XXold = mWidth; YYold = mHeight; DDold = 128;
  
  wzoom = mWidth; if (mHeight < mWidth) wzoom = mHeight;
  tempPerspec = (11.2 - (double)rotPerspective);

if (rotStereoType == 0) {
  for (aCom=0;aCom<numPoints;aCom++) {
    X = thePoints[aCom].x;
    Y = thePoints[aCom].y;
    Z = thePoints[aCom].z;
    C = thePoints[aCom].c;
    
    if (rotCenter) {
      X = (X - midX) / midZoom;
      Y = (Y - midY) / midZoom;
      Z = (Z - midZ) / midZoom;
    }
    
    if (rotUpDirection == 1) { T=Y; Y=Z; Z=T; }
    if (rotUpDirection == 2) { T=X; X=Z; Z=T; }
    if (rotChirality) Y = -Y; // chirality set here
    if (rotInvert) { Z = -Z; Y = -Y; }

    
    X3 = AN * X + BN * Y + CN * Z;
    Y3 = DN * X + EN * Y + FN * Z;
    Z3 = GN * X + HN * Y + IN * Z;
    
    colDepth = (Y3+1)/2.0*0.8+0.2;
    DD = (Y3 + 1)/2*255;
    
    if (rotPerspective > 0.01) {
      Y3 = 1 / sqrt(X3*X3 + (Y3-tempPerspec)*(Y3-tempPerspec) + Z3*Z3) * tempPerspec;
      X3 *= Y3;
      Z3 *= Y3;
    }

    XX = mWidth  + X3*zoom*wzoom;
    YY = mHeight - Z3*zoom*wzoom;
    
    switch (abs(C)) { // Set Basic Color
      case 1: R=255; G=0; B=0; break; //red
      case 2: R=0; G=255; B=0; break; //green
      case 3: R=0; G=0; B=255; break; //blue
      case 4: R=255; G=255; B=0; break; //yellow
      case 5: R=255; G=0; B=255; break; //purple
      case 6: R=0; G=255; B=255; break;  //cyan
      case 7:
      default: R=255; G=255; B=255; break; //white
    }

    if (C > 0) { // Draw Line - there be dragons in this code
      long xi, yi, ui;
      long LWwidth=wWidth, LWheight=wHeight;
      long ughy=0,ddx,ddy,line=rotLineWidth,halfline=(line>>1);
      int r, dx, dy;
      Byte *cplane;
      Byte *plane, RR, GG, BB;
      long x1, y1, ughx, ugh1x;
      
      x = XX; y = YY; x1 = XXold; y1 = YYold; ughx = DD; ugh1x = DDold;
      plane = zBuffer;
      if (x > x1) {
        xi = x1; x1 = x; x = xi;
        yi = y1; y1 = y; y = yi;
        ui = ughx; ughx = ugh1x; ugh1x = ui-ugh1x;
      }
      else ugh1x -= ughx;
      
      ddx=x1-x; ddy=y1-y;
      dx = ddx*2; dy = ddy*2; // << 1

      if (dy >= 0) { //positive line
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x) {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for(cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
            } // end if
            if (r >= 0) { y++; r -= dx; }
            else r += dy;
          } // end for
        } // end if
        else { // y longer
          if(y1>=LWheight-1) y1=LWheight-1;
          r = dx - ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=0;y<=y1;y++,yi+=ugh1x) {
            if (y >= 0) {
              i = x - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:i y:y];
					
					
					
					
                  //*(base+Lrb*y + i) = bytecol;
                }
              }
            if (r >= 0) { x++; r -= dy; }
            else r += dx;
          } // end for
        } // end else
      }
      else { //negative line
        dy=-dy;
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x)
            {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for (cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
              } // end if
            if (r >= 0) { y--; r -= dx; }
            else r += dy;
            } // end for
          } // end if
        else // y longer
          {
          if(y>=LWheight-1) y=LWheight-1;
          r = dx + ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=ddy*ugh1x;y1<=y;y1++,yi+=ugh1x)
            {
            if (y1 >= 0)
              {
              i = x1 - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y1;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y1*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:i y:y1];
					
					
					
                  //*(base + i + Lrb*y1) = bytecol;
                }
              } // end if
            if (r >= 0) { x1--; r -= dy; }
            else r += dx;
            } // end for
          }
      }
    }
    
    if (C < 0) { // Draw Point
      long z;
      x = XX - (rotDotWidth >> 1);
      y = YY - (rotDotWidth >> 1);
      R *= colDepth; G *= colDepth; B *= colDepth;
      for (j=0;j<rotDotWidth;j++,y++) 
        if(y < wHeight && y >= 0)
          for (z=wWidth*y+x,i=0;i<rotDotWidth;i++)
            if (x+i < wWidth && x+i >= 0 && DD >= zBuffer[z+i]) {
              zBuffer[z+i] = DD;
              //pos = (x+i)*3 + y*rotRowBytes;
              //rotBitMapData[pos] = R;
              //rotBitMapData[pos+1] = G;
              //rotBitMapData[pos+2] = B;
				
				//start.x = x-0.5;
				//start.y = y-0.5;
				//end.x = x+0.5;
				//end.y = y+0.5;
				//[[NSColor redColor] set];
				
				//[[NSColor colorWithDeviceRed:R/256.0 green:G/256.0 blue:B/256.0 alpha:1.0] set];
				
				
				//[NSBezierPath strokeLineFromPoint:start toPoint:end];
				
				//NSBezierPath *oval = [NSBezierPath bezierPath];
				//[oval appendBezierPathWithOvalInRect:NSMakeRect(x, y, 30, 30)];
				//[oval fill];
				
				//[NSBezierPath strokeOvalFromRect:ttrect];
				bing[0] = R;
				bing[1] = G;
				bing[2] = B;
				[rotBitMap setPixel:bing atX:x+i y:y];
				
				
            }
    }
    XXold = XX;
    YYold = YY;
    DDold = DD;
  }
}
  
//########################## Dual Image Stereo ################################################################
if (rotStereoType == 1) {
  Xr2 = DEGTORAD * 0;
  Yr2 = DEGTORAD * 0;
  Zr2 = DEGTORAD * rotStereoAngle;

  CX2 = cos(Xr2);
  SX2 = sin(Xr2);
  CY2 = cos(Yr2);
  SY2 = sin(Yr2);
  CZ2 = cos(Zr2);
  SZ2 = sin(Zr2);

  // rotation matrix for x[y[z[rot]]] second view
  AM2 =  CY2*CZ2;
  BM2 =  CY2*SZ2;
  CM2 =  -SY2;
  DM2 =  SX2*SY2*CZ2-CX2*SZ2;
  EM2 =  SX2*SY2*SZ2+CX2*CZ2;
  FM2 =  SX2*CY2;
  GM2 =  CX2*SY2*CZ2+SX2*SZ2;
  HM2 =  CX2*SY2*SZ2-SX2*CZ2;
  IM2 =  CX2*CY2;


  // rotate matrix for second view
  AN2 = AM2*AN + BM2*DN + CM2*GN;
  BN2 = AM2*BN + BM2*EN + CM2*HN;
  CN2 = AM2*CN + BM2*FN + CM2*IN;
  DN2 = DM2*AN + EM2*DN + FM2*GN;
  EN2 = DM2*BN + EM2*EN + FM2*HN;
  FN2 = DM2*CN + EM2*FN + FM2*IN;
  GN2 = GM2*AN + HM2*DN + IM2*GN;
  HN2 = GM2*BN + HM2*EN + IM2*HN;
  IN2 = GM2*CN + HM2*FN + IM2*IN;



  for (aCom=0;aCom<numPoints;aCom++) {
    X = thePoints[aCom].x;
    Y = thePoints[aCom].y;
    Z = thePoints[aCom].z;
    C = thePoints[aCom].c;
    
    if (rotCenter) {
      X = (X - midX) / midZoom;
      Y = (Y - midY) / midZoom;
      Z = (Z - midZ) / midZoom;
    }
    
    if (rotUpDirection == 1) { T=Y; Y=Z; Z=T; }
    if (rotUpDirection == 2) { T=X; X=Z; Z=T; }
    if (rotChirality) Y = -Y; // chirality set here
    if (rotInvert) { Z = -Z; Y = -Y; }

    
    X3 = AN * X + BN * Y + CN * Z;
    Y3 = DN * X + EN * Y + FN * Z;
    Z3 = GN * X + HN * Y + IN * Z;
    
    colDepth = (Y3+1)/2.0*0.8+0.2;
    DD = (Y3 + 1)/2*255;
    
    if (rotPerspective > 0.01) {
      Y3 = 1 / sqrt(X3*X3 + (Y3-tempPerspec)*(Y3-tempPerspec) + Z3*Z3) * tempPerspec;
      X3 *= Y3;
      Z3 *= Y3;
    }

    XX = mWidth/2  + X3*zoom*wzoom/2;
    YY = mHeight - Z3*zoom*wzoom/2;
    
    switch (abs(C)) { // Set Basic Color
      case 1: R=255; G=0; B=0; break; //red
      case 2: R=0; G=255; B=0; break; //green
      case 3: R=0; G=0; B=255; break; //blue
      case 4: R=255; G=255; B=0; break; //yellow
      case 5: R=255; G=0; B=255; break; //purple
      case 6: R=0; G=255; B=255; break;  //cyan
      case 7:
      default: R=255; G=255; B=255; break; //white
    }

    if (C > 0) { // Draw Line - there be dragons in this code
      long xi, yi, ui;
      long LWwidth=wWidth, LWheight=wHeight;
      long ughy=0,ddx,ddy,line=rotLineWidth,halfline=(line>>1);
      int r, dx, dy;
      Byte *cplane;
      Byte *plane, RR, GG, BB;
      long x1, y1, ughx, ugh1x;
      
      x = XX; y = YY; x1 = XXold; y1 = YYold; ughx = DD; ugh1x = DDold;
      plane = zBuffer;
      if (x > x1) {
        xi = x1; x1 = x; x = xi;
        yi = y1; y1 = y; y = yi;
        ui = ughx; ughx = ugh1x; ugh1x = ui-ugh1x;
      }
      else ugh1x -= ughx;
      
      ddx=x1-x; ddy=y1-y;
      dx = ddx*2; dy = ddy*2; // << 1

      if (dy >= 0) { //positive line
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x) {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for(cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
            } // end if
            if (r >= 0) { y++; r -= dx; }
            else r += dy;
          } // end for
        } // end if
        else { // y longer
          if(y1>=LWheight-1) y1=LWheight-1;
          r = dx - ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=0;y<=y1;y++,yi+=ugh1x) {
            if (y >= 0) {
              i = x - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:i y:y];
					
					
					
                  //*(base+Lrb*y + i) = bytecol;
                }
              }
            if (r >= 0) { x++; r -= dy; }
            else r += dx;
          } // end for
        } // end else
      }
      else { //negative line
        dy=-dy;
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x)
            {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for (cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
              } // end if
            if (r >= 0) { y--; r -= dx; }
            else r += dy;
            } // end for
          } // end if
        else // y longer
          {
          if(y>=LWheight-1) y=LWheight-1;
          r = dx + ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=ddy*ugh1x;y1<=y;y1++,yi+=ugh1x)
            {
            if (y1 >= 0)
              {
              i = x1 - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y1;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y1*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:i y:y1];
					
					
					
                  //*(base + i + Lrb*y1) = bytecol;
                }
              } // end if
            if (r >= 0) { x1--; r -= dy; }
            else r += dx;
            } // end for
          }
      }
    }
    
    if (C < 0) { // Draw Point
      long z;
      x = XX - (rotDotWidth >> 1);
      y = YY - (rotDotWidth >> 1);
      R *= colDepth; G *= colDepth; B *= colDepth;
      for (j=0;j<rotDotWidth;j++,y++) 
        if(y < wHeight && y >= 0)
          for (z=wWidth*y+x,i=0;i<rotDotWidth;i++)
            if (x+i < wWidth && x+i >= 0 && DD >= zBuffer[z+i]) {
              zBuffer[z+i] = DD;
              //pos = (x+i)*3 + y*rotRowBytes;
              //rotBitMapData[pos] = R;
              //rotBitMapData[pos+1] = G;
              //rotBitMapData[pos+2] = B;
				
				bing[0] = R;
				bing[1] = G;
				bing[2] = B;
				[rotBitMap setPixel:bing atX:x+i y:y];
				
				
				
				
				
            }
    }
    XXold = XX;
    YYold = YY;
    DDold = DD;
  }



//####### Dual inage second inage #######

  for (aCom=0;aCom<numPoints;aCom++) {
    X = thePoints[aCom].x;
    Y = thePoints[aCom].y;
    Z = thePoints[aCom].z;
    C = thePoints[aCom].c;
    
    if (rotCenter) {
      X = (X - midX) / midZoom;
      Y = (Y - midY) / midZoom;
      Z = (Z - midZ) / midZoom;
    }
    
    if (rotUpDirection == 1) { T=Y; Y=Z; Z=T; }
    if (rotUpDirection == 2) { T=X; X=Z; Z=T; }
    if (rotChirality) Y = -Y; // chirality set here
    if (rotInvert) { Z = -Z; Y = -Y; }

    
    X3 = AN2 * X + BN2 * Y + CN2 * Z;
    Y3 = DN2 * X + EN2 * Y + FN2 * Z;
    Z3 = GN2 * X + HN2 * Y + IN2 * Z;
    
    colDepth = (Y3+1)/2.0*0.8+0.2;
    DD = (Y3 + 1)/2*255;
    
    if (rotPerspective > 0.01) {
      Y3 = 1 / sqrt(X3*X3 + (Y3-tempPerspec)*(Y3-tempPerspec) + Z3*Z3) * tempPerspec;
      X3 *= Y3;
      Z3 *= Y3;
    }

    XX = mWidth*3/2  + X3*zoom*wzoom/2;
    YY = mHeight - Z3*zoom*wzoom/2;
    
    switch (abs(C)) { // Set Basic Color
      case 1: R=255; G=0; B=0; break; //red
      case 2: R=0; G=255; B=0; break; //green
      case 3: R=0; G=0; B=255; break; //blue
      case 4: R=255; G=255; B=0; break; //yellow
      case 5: R=255; G=0; B=255; break; //purple
      case 6: R=0; G=255; B=255; break;  //cyan
      case 7:
      default: R=255; G=255; B=255; break; //white
    }

    if (C > 0) { // Draw Line - there be dragons in this code
      long xi, yi, ui;
      long LWwidth=wWidth, LWheight=wHeight;
      long ughy=0,ddx,ddy,line=rotLineWidth,halfline=(line>>1);
      int r, dx, dy;
      Byte *cplane;
      Byte *plane, RR, GG, BB;
      long x1, y1, ughx, ugh1x;
      
      x = XX; y = YY; x1 = XXold; y1 = YYold; ughx = DD; ugh1x = DDold;
      plane = zBuffer;
      if (x > x1) {
        xi = x1; x1 = x; x = xi;
        yi = y1; y1 = y; y = yi;
        ui = ughx; ughx = ugh1x; ugh1x = ui-ugh1x;
      }
      else ugh1x -= ughx;
      
      ddx=x1-x; ddy=y1-y;
      dx = ddx*2; dy = ddy*2; // << 1

      if (dy >= 0) { //positive line
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x) {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for(cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
            } // end if
            if (r >= 0) { y++; r -= dx; }
            else r += dy;
          } // end for
        } // end if
        else { // y longer
          if(y1>=LWheight-1) y1=LWheight-1;
          r = dx - ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=0;y<=y1;y++,yi+=ugh1x) {
            if (y >= 0) {
              i = x - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:i y:y];
					
					
					
					
                  //*(base+Lrb*y + i) = bytecol;
                }
              }
            if (r >= 0) { x++; r -= dy; }
            else r += dx;
          } // end for
        } // end else
      }
      else { //negative line
        dy=-dy;
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x)
            {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for (cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
              } // end if
            if (r >= 0) { y--; r -= dx; }
            else r += dy;
            } // end for
          } // end if
        else // y longer
          {
          if(y>=LWheight-1) y=LWheight-1;
          r = dx + ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=ddy*ugh1x;y1<=y;y1++,yi+=ugh1x)
            {
            if (y1 >= 0)
              {
              i = x1 - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y1;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y1*rotRowBytes;
                  //rotBitMapData[pos] = RR;
                  //rotBitMapData[pos+1] = GG;
                  //rotBitMapData[pos+2] = BB;
					
					
					bing[0] = RR;
					bing[1] = GG;
					bing[2] = BB;
					[rotBitMap setPixel:bing atX:i y:y1];
					
					
					
					
                  //*(base + i + Lrb*y1) = bytecol;
                }
              } // end if
            if (r >= 0) { x1--; r -= dy; }
            else r += dx;
            } // end for
          }
      }
    }
    
    if (C < 0) { // Draw Point
      long z;
      x = XX - (rotDotWidth >> 1);
      y = YY - (rotDotWidth >> 1);
      R *= colDepth; G *= colDepth; B *= colDepth;
      for (j=0;j<rotDotWidth;j++,y++) 
        if(y < wHeight && y >= 0)
          for (z=wWidth*y+x,i=0;i<rotDotWidth;i++)
            if (x+i < wWidth && x+i >= 0 && DD >= zBuffer[z+i]) {
              zBuffer[z+i] = DD;
              //pos = (x+i)*3 + y*rotRowBytes;
              //rotBitMapData[pos] = R;
              //rotBitMapData[pos+1] = G;
              //rotBitMapData[pos+2] = B;
				
				bing[0] = R;
				bing[1] = G;
				bing[2] = B;
				[rotBitMap setPixel:bing atX:x+i y:y];
				
				
				
            }
    }
    XXold = XX;
    YYold = YY;
    DDold = DD;
  }
}
  
//##########################################################################################



if (rotStereoType == 2 || rotStereoType == 3) {


  Xr2 = DEGTORAD * 0;
  Yr2 = DEGTORAD * 0;
  Zr2 = DEGTORAD * rotStereoAngle;

  CX2 = cos(Xr2);
  SX2 = sin(Xr2);
  CY2 = cos(Yr2);
  SY2 = sin(Yr2);
  CZ2 = cos(Zr2);
  SZ2 = sin(Zr2);

  // rotation matrix for x[y[z[rot]]] second view
  AM2 =  CY2*CZ2;
  BM2 =  CY2*SZ2;
  CM2 =  -SY2;
  DM2 =  SX2*SY2*CZ2-CX2*SZ2;
  EM2 =  SX2*SY2*SZ2+CX2*CZ2;
  FM2 =  SX2*CY2;
  GM2 =  CX2*SY2*CZ2+SX2*SZ2;
  HM2 =  CX2*SY2*SZ2-SX2*CZ2;
  IM2 =  CX2*CY2;


  // rotate matrix for second view
  AN2 = AM2*AN + BM2*DN + CM2*GN;
  BN2 = AM2*BN + BM2*EN + CM2*HN;
  CN2 = AM2*CN + BM2*FN + CM2*IN;
  DN2 = DM2*AN + EM2*DN + FM2*GN;
  EN2 = DM2*BN + EM2*EN + FM2*HN;
  FN2 = DM2*CN + EM2*FN + FM2*IN;
  GN2 = GM2*AN + HM2*DN + IM2*GN;
  HN2 = GM2*BN + HM2*EN + IM2*HN;
  IN2 = GM2*CN + HM2*FN + IM2*IN;





  for (aCom=0;aCom<numPoints;aCom++) {
    X = thePoints[aCom].x;
    Y = thePoints[aCom].y;
    Z = thePoints[aCom].z;
    C = thePoints[aCom].c;
    
    if (rotCenter) {
      X = (X - midX) / midZoom;
      Y = (Y - midY) / midZoom;
      Z = (Z - midZ) / midZoom;
    }
    
    if (rotUpDirection == 1) { T=Y; Y=Z; Z=T; }
    if (rotUpDirection == 2) { T=X; X=Z; Z=T; }
    if (rotChirality) Y = -Y; // chirality set here
    if (rotInvert) { Z = -Z; Y = -Y; }

    X3 = AN * X + BN * Y + CN * Z;
    Y3 = DN * X + EN * Y + FN * Z;
    Z3 = GN * X + HN * Y + IN * Z;
    
    //X32 = AN2 * X + BN2 * Y + CN2 * Z;
    //Y32 = DN2 * X + EN2 * Y + FN2 * Z;
    //Z32 = GN2 * X + HN2 * Y + IN2 * Z;
    
    colDepth = (Y3+1)/2.0*0.8+0.2;
    DD = (Y3 + 1)/2*255;
    
    if (rotPerspective > 0.01) {
      Y3 = 1 / sqrt(X3*X3 + (Y3-tempPerspec)*(Y3-tempPerspec) + Z3*Z3) * tempPerspec;
      X3 *= Y3;
      Z3 *= Y3;
    }

    XX = mWidth  + X3*zoom*wzoom;
    YY = mHeight - Z3*zoom*wzoom;
    
#if 0
    switch (abs(C)) { // Set Basic Color
      case 1: R=255; G=0; B=0; break; //red
      case 2: R=0; G=255; B=0; break; //green
      case 3: R=0; G=0; B=255; break; //blue
      case 4: R=255; G=255; B=0; break; //yellow
      case 5: R=255; G=0; B=255; break; //purple
      case 6: R=0; G=255; B=255; break;  //cyan
      case 7:
      default: R=255; G=255; B=255; break; //white
    }
#endif

    if (C > 0) { // Draw Line - there be dragons in this code
      long xi, yi, ui;
      long LWwidth=wWidth, LWheight=wHeight;
      long ughy=0,ddx,ddy,line=rotLineWidth,halfline=(line>>1);
      int r, dx, dy;
      Byte *cplane;
      Byte *plane/*, RR, GG, BB*/;
      long x1, y1, ughx, ugh1x;
      
      x = XX; y = YY; x1 = XXold; y1 = YYold; ughx = DD; ugh1x = DDold;
      plane = zBuffer;
      if (x > x1) {
        xi = x1; x1 = x; x = xi;
        yi = y1; y1 = y; y = yi;
        ui = ughx; ughx = ugh1x; ugh1x = ui-ugh1x;
      }
      else ugh1x -= ughx;
      
      ddx=x1-x; ddy=y1-y;
      dx = ddx*2; dy = ddy*2; // << 1

      if (dy >= 0) { //positive line
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x) {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for(cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = 255*colDepth;
                  //rotBitMapData[pos+1] = 0;
                  //rotBitMapData[pos+2] = 0;
					
					bing[0] = 255*colDepth;
					bing[1] = 0;
					bing[2] = 0;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
            } // end if
            if (r >= 0) { y++; r -= dx; }
            else r += dy;
          } // end for
        } // end if
        else { // y longer
          if(y1>=LWheight-1) y1=LWheight-1;
          r = dx - ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=0;y<=y1;y++,yi+=ugh1x) {
            if (y >= 0) {
              i = x - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y*rotRowBytes;
                  //rotBitMapData[pos] = 255*colDepth;
                  //rotBitMapData[pos+1] = 0;
                  //rotBitMapData[pos+2] = 0;
					
					
					bing[0] = 255*colDepth;
					bing[1] = 0;
					bing[2] = 0;
					[rotBitMap setPixel:bing atX:i y:y];
					
					
					
                  //*(base+Lrb*y + i) = bytecol;
                }
              }
            if (r >= 0) { x++; r -= dy; }
            else r += dx;
          } // end for
        } // end else
      }
      else { //negative line
        dy=-dy;
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x)
            {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for (cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
                  //rotBitMapData[pos] = 255*colDepth;
                  //rotBitMapData[pos+1] = 0;
                  //rotBitMapData[pos+2] = 0;
					
					bing[0] = 255*colDepth;
					bing[1] = 0;
					bing[2] = 0;
					[rotBitMap setPixel:bing atX:x y:i];
					
					
					
					
                  //*(base + x+Lrb*i) = bytecol;
                }
              } // end if
            if (r >= 0) { y--; r -= dx; }
            else r += dy;
            } // end for
          } // end if
        else // y longer
          {
          if(y>=LWheight-1) y=LWheight-1;
          r = dx + ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=ddy*ugh1x;y1<=y;y1++,yi+=ugh1x)
            {
            if (y1 >= 0)
              {
              i = x1 - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y1;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y1*rotRowBytes;
                  //rotBitMapData[pos] = 255*colDepth;
                  //rotBitMapData[pos+1] = 0;
                  //rotBitMapData[pos+2] = 0;
					
					
					bing[0] = 255*colDepth;
					bing[1] = 0;
					bing[2] = 0;
					[rotBitMap setPixel:bing atX:i y:y1];
					
					
					
                  //*(base + i + Lrb*y1) = bytecol;
                }
              } // end if
            if (r >= 0) { x1--; r -= dy; }
            else r += dx;
            } // end for
          }
      }
    }
    
    if (C < 0) { // Draw Point
      long z;
      x = XX - (rotDotWidth >> 1);
      y = YY - (rotDotWidth >> 1);
      /*R *= colDepth; G *= colDepth; B *= colDepth;*/
      for (j=0;j<rotDotWidth;j++,y++) 
        if(y < wHeight && y >= 0)
          for (z=wWidth*y+x,i=0;i<rotDotWidth;i++)
            if (x+i < wWidth && x+i >= 0 && DD >= zBuffer[z+i]) {
              zBuffer[z+i] = DD;
              //pos = (x+i)*3 + y*rotRowBytes;
			  //rotBitMapData[pos] = 255*colDepth;
			  //rotBitMapData[pos+1] = 0;
			  //rotBitMapData[pos+2] = 0;
				
				bing[0] = 255*colDepth;
				bing[1] = 0;
				bing[2] = 0;
				[rotBitMap setPixel:bing atX:x+i y:y];
				
				
				
				
            }
    }
    XXold = XX;
    YYold = YY;
    DDold = DD;
  }
  //######################## SECOND COLOR ##############################
  NSZoneFree(nil, zBuffer);
  zBuffer = (Byte *) NSZoneCalloc(nil, zBuffSize, 1);

  for (aCom=0;aCom<numPoints;aCom++) {
    X = thePoints[aCom].x;
    Y = thePoints[aCom].y;
    Z = thePoints[aCom].z;
    C = thePoints[aCom].c;
    
    if (rotCenter) {
      X = (X - midX) / midZoom;
      Y = (Y - midY) / midZoom;
      Z = (Z - midZ) / midZoom;
    }
    
    if (rotUpDirection == 1) { T=Y; Y=Z; Z=T; }
    if (rotUpDirection == 2) { T=X; X=Z; Z=T; }
    if (rotChirality) Y = -Y; // chirality set here
    if (rotInvert) { Z = -Z; Y = -Y; }

    X3 = AN2 * X + BN2 * Y + CN2 * Z;
    Y3 = DN2 * X + EN2 * Y + FN2 * Z;
    Z3 = GN2 * X + HN2 * Y + IN2 * Z;
    
    colDepth = (Y3+1)/2.0*0.8+0.2;
    DD = (Y3 + 1)/2*255;
    
    if (rotPerspective > 0.01) {
      Y3 = 1 / sqrt(X3*X3 + (Y3-tempPerspec)*(Y3-tempPerspec) + Z3*Z3) * tempPerspec;
      X3 *= Y3;
      Z3 *= Y3;
    }

    XX = mWidth  + X3*zoom*wzoom;
    YY = mHeight - Z3*zoom*wzoom;
    
#if 0
    switch (abs(C)) { // Set Basic Color
      case 1: R=255; G=0; B=0; break; //red
      case 2: R=0; G=255; B=0; break; //green
      case 3: R=0; G=0; B=255; break; //blue
      case 4: R=255; G=255; B=0; break; //yellow
      case 5: R=255; G=0; B=255; break; //purple
      case 6: R=0; G=255; B=255; break;  //cyan
      case 7:
      default: R=255; G=255; B=255; break; //white
    }
#endif
    
    if (C > 0) { // Draw Line - there be dragons in this code
      long xi, yi, ui;
      long LWwidth=wWidth, LWheight=wHeight;
      long ughy=0,ddx,ddy,line=rotLineWidth,halfline=(line>>1);
      int r, dx, dy;
      Byte *cplane;
      Byte *plane/*, RR, GG, BB*/;
      long x1, y1, ughx, ugh1x;
      
      x = XX; y = YY; x1 = XXold; y1 = YYold; ughx = DD; ugh1x = DDold;
      plane = zBuffer;
      if (x > x1) {
        xi = x1; x1 = x; x = xi;
        yi = y1; y1 = y; y = yi;
        ui = ughx; ughx = ugh1x; ugh1x = ui-ugh1x;
      }
      else ugh1x -= ughx;
      
      ddx=x1-x; ddy=y1-y;
      dx = ddx*2; dy = ddy*2; // << 1

      if (dy >= 0) { //positive line
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x) {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for(cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
				  //////if (rotStereoType == 2) rotBitMapData[pos+1] = 255*colDepth;
				  //////else rotBitMapData[pos+2] = 255*colDepth;
                   //*(base + x+Lrb*i) = bytecol;
					
					[rotBitMap getPixel:bing atX:x y:i];
					if (rotStereoType == 2) bing[1] = 255*colDepth;
					else bing[2] = 255*colDepth;
					[rotBitMap setPixel:bing atX:x y:i];
					
                }
            } // end if
            if (r >= 0) { y++; r -= dx; }
            else r += dy;
          } // end for
        } // end if
        else { // y longer
          if(y1>=LWheight-1) y1=LWheight-1;
          r = dx - ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=0;y<=y1;y++,yi+=ugh1x) {
            if (y >= 0) {
              i = x - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y*rotRowBytes;
				  //////if (rotStereoType == 2) rotBitMapData[pos+1] = 255*colDepth;
				  //////else rotBitMapData[pos+2] = 255*colDepth;
                  //*(base+Lrb*y + i) = bytecol;
					
					
					[rotBitMap getPixel:bing atX:i y:y];
					if (rotStereoType == 2) bing[1] = 255*colDepth;
					else bing[2] = 255*colDepth;
					[rotBitMap setPixel:bing atX:i y:y];
					
				}
              }
            if (r >= 0) { x++; r -= dy; }
            else r += dx;
          } // end for
        } // end else
      }
      else { //negative line
        dy=-dy;
        if (dx > dy) { // x longer
          if(x1>=LWwidth-1) x1=LWwidth-1;
          r = dy - ddx; dx -= dy; if (!ddx) ughy = ughx;
          for (xi=0;x<=x1;x++,xi+=ugh1x)
            {
            if (x >= 0) {
              i = y - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWheight) k=LWheight;
              if (ddx) ughy = xi/ddx + ughx;
              for (cplane=plane+x+LWwidth*i;i<k;i++,cplane+=LWwidth)
                if(ughy>=*cplane) {
                  *cplane = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = x*3 + i*rotRowBytes;
				  //////if (rotStereoType == 2) rotBitMapData[pos+1] = 255*colDepth;
				  //////else rotBitMapData[pos+2] = 255*colDepth;
                  //*(base + x+Lrb*i) = bytecol;
					
					[rotBitMap getPixel:bing atX:x y:i];
					if (rotStereoType == 2) bing[1] = 255*colDepth;
					else bing[2] = 255*colDepth;
					[rotBitMap setPixel:bing atX:x y:i];
					
                }
              } // end if
            if (r >= 0) { y--; r -= dx; }
            else r += dy;
            } // end for
          } // end if
        else // y longer
          {
          if(y>=LWheight-1) y=LWheight-1;
          r = dx + ddy; dy -= dx; if (!ddy) ughy = ughx;
          for (yi=ddy*ugh1x;y1<=y;y1++,yi+=ugh1x)
            {
            if (y1 >= 0)
              {
              i = x1 - halfline; k = i + line;
              if(i<0) i=0;
              if(k>LWwidth) k=LWwidth;
              if (ddy) ughy = yi/ddy + ughx;
              for(cplane=plane+LWwidth*y1;i<k;i++)
                if(ughy>=cplane[i]) {
                  cplane[i] = ughy;
                  colDepth = ((ughy-128)/128.0/10.0*9.0+1.1)/2+0.2;
                  if (colDepth > 1) colDepth = 1;
                  //RR = R*colDepth; GG = G*colDepth; BB = B*colDepth;
                  //pos = i*3 + y1*rotRowBytes;
				  //////if (rotStereoType == 2) rotBitMapData[pos+1] = 255*colDepth;
				  //////else rotBitMapData[pos+2] = 255*colDepth;
                  //*(base + i + Lrb*y1) = bytecol;
					
					[rotBitMap getPixel:bing atX:i y:y1];
					if (rotStereoType == 2) bing[1] = 255*colDepth;
					else bing[2] = 255*colDepth;
					[rotBitMap setPixel:bing atX:i y:y1];
					
                }
              } // end if
            if (r >= 0) { x1--; r -= dy; }
            else r += dx;
            } // end for
          }
      }
    }
    
    if (C < 0) { // Draw Point
      long z;
      x = XX - (rotDotWidth >> 1);
      y = YY - (rotDotWidth >> 1);
      //R *= colDepth; G *= colDepth; B *= colDepth;
      for (j=0;j<rotDotWidth;j++,y++) 
        if(y < wHeight && y >= 0)
          for (z=wWidth*y+x,i=0;i<rotDotWidth;i++)
            if (x+i < wWidth && x+i >= 0 && DD >= zBuffer[z+i]) {
              zBuffer[z+i] = DD;
              //pos = (x+i)*3 + y*rotRowBytes;
			  //////if (rotStereoType == 2) rotBitMapData[pos+1] = 255*colDepth;
			  //////else rotBitMapData[pos+2] = 255*colDepth;
				
				[rotBitMap getPixel:bing atX:(x+i) y:y];
				if (rotStereoType == 2) bing[1] = 255*colDepth;
				else bing[2] = 255*colDepth;
				[rotBitMap setPixel:bing atX:(x+i) y:y];
				
            }
    }
    XXold = XX;
    YYold = YY;
    DDold = DD;
  }
}
  
  
  
  
  
  
  zero.x = 0; zero.y = 0;
	//[rotImage compositeToPoint:zero fromRect:viewBounds operation:NSCompositeCopy];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[rotImage drawAtPoint:zero fromRect:viewBounds operation:NSCompositeCopy fraction:1];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
  NSZoneFree(nil, zBuffer);
  
  if (rotFPS) {
    [[NSColor whiteColor] set];
    NSRect trect;
    trect.origin.x = 2;
    trect.origin.y = 2;
    trect.size.width = 40;
    trect.size.height = 14;
    [NSBezierPath fillRect:trect];
    
    NSPoint p1;
    p1.x=4;p1.y=2;
    NSNumber *nnn;
    nnn = [NSNumber numberWithLong:fps];
    [[nnn stringValue] drawAtPoint:p1 withAttributes:NULL];
  }
}

//######################################################################################//

- (void)rotateX:(double)RX Y:(double)RY Z:(double)RZ {
  double Xr, Yr, Zr, Xr2, Yr2, Zr2;
  double CZ, SZ, CY, SY, CX, SX;
  double CZ2, SZ2, CY2, SY2, CX2, SX2;
  double AM, BM, CM, DM, EM, FM, GM, HM, IM;
  double AM2, BM2, CM2, DM2, EM2, FM2, GM2, HM2, IM2;

  Xr = DEGTORAD * RX;
  Yr = DEGTORAD * RY;
  Zr = DEGTORAD * RZ;

  Xr2 = DEGTORAD * 0;
  Yr2 = DEGTORAD * 0;
  Zr2 = DEGTORAD * rotStereoAngle;

  CX = cos(Xr);
  SX = sin(Xr);
  CY = cos(Yr);
  SY = sin(Yr);
  CZ = cos(Zr);
  SZ = sin(Zr);

  CX2 = cos(Xr2);
  SX2 = sin(Xr2);
  CY2 = cos(Yr2);
  SY2 = sin(Yr2);
  CZ2 = cos(Zr2);
  SZ2 = sin(Zr2);

  // rotation matrix for x[y[z[rot]]]
  AM =  CY*CZ;
  BM =  CY*SZ;
  CM =  -SY;
  DM =  SX*SY*CZ-CX*SZ;
  EM =  SX*SY*SZ+CX*CZ;
  FM =  SX*CY;
  GM =  CX*SY*CZ+SX*SZ;
  HM =  CX*SY*SZ-SX*CZ;
  IM =  CX*CY;

  // rotation matrix for x[y[z[rot]]] second view
  AM2 =  CY2*CZ2;
  BM2 =  CY2*SZ2;
  CM2 =  -SY2;
  DM2 =  SX2*SY2*CZ2-CX2*SZ2;
  EM2 =  SX2*SY2*SZ2+CX2*CZ2;
  FM2 =  SX2*CY2;
  GM2 =  CX2*SY2*CZ2+SX2*SZ2;
  HM2 =  CX2*SY2*SZ2-SX2*CZ2;
  IM2 =  CX2*CY2;

  // rotate global matrix by new matrix
  AN = AM*aM + BM*dM + CM*gM;
  BN = AM*bM + BM*eM + CM*hM;
  CN = AM*cM + BM*fM + CM*iM;
  DN = DM*aM + EM*dM + FM*gM;
  EN = DM*bM + EM*eM + FM*hM;
  FN = DM*cM + EM*fM + FM*iM;
  GN = GM*aM + HM*dM + IM*gM;
  HN = GM*bM + HM*eM + IM*hM;
  IN = GM*cM + HM*fM + IM*iM;

  // rotate matrix for second view
  AN2 = AM2*AN + BM2*DN + CM2*GN;
  BN2 = AM2*BN + BM2*EN + CM2*HN;
  CN2 = AM2*CN + BM2*FN + CM2*IN;
  DN2 = DM2*AN + EM2*DN + FM2*GN;
  EN2 = DM2*BN + EM2*EN + FM2*HN;
  FN2 = DM2*CN + EM2*FN + FM2*IN;
  GN2 = GM2*AN + HM2*DN + IM2*GN;
  HN2 = GM2*BN + HM2*EN + IM2*HN;
  IN2 = GM2*CN + HM2*FN + IM2*IN;

  if (rotTrackball) {
    aM = AN;
    bM = BN;
    cM = CN;
    dM = DN;
    eM = EN;
    fM = FN;
    gM = GN;
    hM = HN;
    iM = IN;
  }
}

//######################################################################################//

- (void)backrotate:(id)anObject {
  double backXX, backZZ;
  double backElapsed;
  double backTimer1;
  NSDate *zzz = [NSDate date];

  backTimer1 = [zzz timeIntervalSinceReferenceDate];
  //backTimer1 = [zzz timeIntervalSince1970];
  backElapsed = backTimer1-backTimer;
  backTimer = backTimer1;

  backXX = backX / backTime * backElapsed;
  backZZ = backZ / backTime * backElapsed;
  


  if (backTimer1 - fpstimer > 0.5) {
  fps = 1.0 / backElapsed;
  fpstimer = backTimer1;
  }
  
  
  if (rotTrackball) {
    [self rotateX:-backXX Y:0 Z:backZZ];
  }
  else {
    currentZ += backZZ;
    [self rotateX:-currentX Y:0 Z:currentZ];
  }
  [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)scrollWheel:(NSEvent *)event {
  float dx = [event deltaX];
  float dy = [event deltaY];
  //if (backrotateme) { [myTimer invalidate]; }
  //backrotateme = NO;
  if (rotTrackball) {
    [self rotateX:-dy Y:0 Z:-dx];
  }
  else {
    currentZ -= dx;
	currentX += dy;
    [self rotateX:-currentX Y:0 Z:currentZ];
  } 
  [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)mouseDown:(NSEvent *)event {
  NSPoint eventLocation = [event locationInWindow];
  NSDate *zzz = [NSDate date];
  refPoint = [self convertPoint:eventLocation fromView:nil];
  backX = 0; backZ = 0;
  if (backrotateme) { [myTimer invalidate]; }
  backrotateme = NO;
  spinCount = 0;
  spinTime[0] = [zzz timeIntervalSinceReferenceDate];
  spinX[spinCount] = 0;
  spinZ[spinCount] = 0;
}

//######################################################################################//

- (void)mouseUp:(NSEvent *)event {
  NSPoint eventLocation = [event locationInWindow];
  int i;
  NSDate *zzz = [NSDate date];
  double nowtime;
  
  nowtime = [zzz timeIntervalSinceReferenceDate];
  refPoint = [self convertPoint:eventLocation fromView:nil];
  if (numPoints && spinCount && nowtime-spinTime[0]<0.5) { // Continue Rotation
    backX = 0;
    backZ = 0;
    for (i=0;i<=spinCount;i++) {
      backX += spinX[i];
      backZ += spinZ[i];
    }
    backX /= spinCount;
    backZ /= spinCount;
    backTime = (spinTime[0] - spinTime[spinCount])/spinCount;
    backrotateme = YES;
    backTimer = [zzz timeIntervalSinceReferenceDate];
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.00001 target:self 
	      selector:@selector(backrotate:) userInfo:nil repeats:YES];
  }
}

//######################################################################################//

- (void)mouseDragged:(NSEvent *)event {
  NSPoint eventLocation = [event locationInWindow];
  NSPoint newPoint = [self convertPoint:eventLocation fromView:nil];
  int i;
  NSDate *zzz = [NSDate date];
  
  rZ = (newPoint.x - refPoint.x)/2;
  rX = (newPoint.y - refPoint.y)/2;
  if (rotTrackball) {
    [self rotateX:-rX Y:0 Z:rZ];
  }
  else {
    currentZ += rZ;
    currentX += rX; if (currentX > 90) currentX = 90;  if (currentX < -90) currentX = -90;
    [self rotateX:-currentX Y:0 Z:currentZ];
  }
  refPoint = newPoint;
  //time1 = TickCount();
  [self setNeedsDisplay:YES];
  for (i=8;i>=0;i--) {
    spinTime[i+1] = spinTime[i];
    spinX[i+1] = spinX[i];
    spinZ[i+1] = spinZ[i];
  }
  spinTime[0] = [zzz timeIntervalSinceReferenceDate];
  spinX[0] = rX;
  spinZ[0] = rZ;
  if (spinTime[0]-spinTime[1] < 0.5) { spinCount++; if (spinCount > 9) spinCount = 9; }
  else spinCount = 0;
}

//######################################################################################//

- (void)preparetoclose {
  if (backrotateme) { [myTimer invalidate]; }
  backrotateme = NO;
}

//######################################################################################//

- (void)keyDown:(NSEvent *)event {
  double x=0, y=0, z=0;
  NSString *eventKey = [event charactersIgnoringModifiers];
  if (lastKeyWas != [eventKey characterAtIndex:0])
    zoomfactor = 1; else { zoomfactor++; }
  
  switch ([eventKey characterAtIndex:0]) {
    case 'x': x=1; [self setNeedsDisplay:YES]; break;
    case 'X': x=-1; [self setNeedsDisplay:YES]; break;
    case 'y': y=1; [self setNeedsDisplay:YES]; break;
    case 'Y': y=-1; [self setNeedsDisplay:YES]; break;
    case 'z': z=1; [self setNeedsDisplay:YES]; break;
    case 'Z': z=-1; [self setNeedsDisplay:YES]; break;
    case NSDownArrowFunctionKey: x=-1; [self setNeedsDisplay:YES]; break; // down arrow
    case NSUpArrowFunctionKey: x=1; [self setNeedsDisplay:YES]; break; // up arrow
    case NSRightArrowFunctionKey: z=1; [self setNeedsDisplay:YES]; break; // right arrow
    case NSLeftArrowFunctionKey: z=-1; [self setNeedsDisplay:YES]; break; // left arrow
    case '=':
    case '+': zoom += zoomfactor/100.0; [self setNeedsDisplay:YES]; break;
    case '-': zoom -= zoomfactor/100.0; if (zoom < 0) zoom =0; [self setNeedsDisplay:YES]; break;
    default: NSBeep(); break;
  }
  lastKeyWas = [eventKey characterAtIndex:0];
  
  if (rotTrackball) {
    [self rotateX:-x Y:y Z:z];
  }
  else {
    currentZ += z;
	currentX += x;
    [self rotateX:-currentX Y:0 Z:currentZ];
  } 
}

//######################################################################################//

- (id)initWithFrame:(NSRect)frame {
  if (!(self = [super initWithFrame:frame]))  return nil;
  aM=1; bM=0; cM=0; dM=0; eM=1; fM=0; gM=0; hM=0; iM=1;
  AN=1; BN=0; CN=0; DN=0; EN=1; FN=0; GN=0; HN=0; IN=1;
  backX=0; backY=0; backZ=0;
  backrotateme = NO;
  numPoints = 0;
  zoom = 0.9; zoomfactor = 1;
  rotCenter = NO;
  rotTrackball = NO;
  midX = 0; midY = 0; midZ = 0; midZoom = 1;
  rotLineWidth = 1;
  rotDotWidth = 1;
  rotStereoAngle = 0;
  rotPerspective = 3.0;
  lastKeyWas = '@';
  rotChirality = NO;
  rotInvert = NO;
  rotFPS = NO;
  rotUpDirection = 0;
  rotStereoType = 0;
  currentX = 0; currentZ = 0;
  fps = 0;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL val = [defaults boolForKey:@"FPS"];
  rotFPS = val;
  [fixFPS setIntValue:1]; //jessa
  [fixLineWidth setDoubleValue:5.0]; //jessa
  //[self rotateX:0 Y:0 Z:0];
  [self setNeedsDisplay:YES];
  return self;
}

//######################################################################################//

- (void)updateRotaterView:(id)sender numPoints:(long)N thePoints:(struct pointArray *)P {
  numPoints = N;
  thePoints = P;
  //set mid stuff here
  [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)updateRotaterViewMidX:(double)mX midY:(double)mY midZ:(double)mZ midZoom:(double)mZoom {
  midX = mX;
  midY = mY;
  midZ = mZ;
  midZoom = mZoom;
}

//######################################################################################//

/*
- (void)dealloc {
  //backrotateme = NO; // somewhere else??
}
*/

//######################################################################################//

- (BOOL)isOpaque {
  return YES;
}

//######################################################################################//

- (BOOL)acceptsFirstResponder { 
  return YES; 
}

//######################################################################################//

- (void)LineWidth:(int)thing {
    rotLineWidth = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)PointWidth:(int)thing {
    rotDotWidth = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)StereoAngle:(double)thing {
    rotStereoAngle = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)Perspective:(double)thing {
    rotPerspective = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)UpDirection:(int)thing {
    rotUpDirection = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)StereoType:(int)thing {
    rotStereoType = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)Invert:(BOOL)thing {
    rotInvert = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)Chirality:(BOOL)thing {
    rotChirality = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)Center:(BOOL)thing {
    rotCenter = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)Trackball:(BOOL)thing {
    rotTrackball = thing;
    if (rotTrackball) {
      [self rotateX:-currentX Y:0 Z:currentZ];
    }
    else {
      currentX = 0;
      currentZ = 0;
    }
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)FPS:(BOOL)thing {
    rotFPS = thing;
    [self setNeedsDisplay:YES];
}

//######################################################################################//

- (void)resetObject:(id)sender {
  if (backrotateme) { [myTimer invalidate]; }
  backrotateme = NO;
  aM=1; bM=0; cM=0; dM=0; eM=1; fM=0; gM=0; hM=0; iM=1;
  AN=1; BN=0; CN=0; DN=0; EN=1; FN=0; GN=0; HN=0; IN=1;
  backX=0; backY=0; backZ=0;
  zoom = 0.9; zoomfactor = 1;
  lastKeyWas = '@';
  currentX = 0; currentZ = 0;
  if (backrotateme) { [myTimer invalidate]; }
  backrotateme = NO;
  [self setNeedsDisplay:YES];
  //[self rotateX:0 Y:0 Z:0];
}

//######################################################################################//

@end
