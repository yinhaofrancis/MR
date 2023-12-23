//
//  Export.h
//  MRRender
//
//  Created by wenyang on 2023/12/17.
//

#ifndef Export_h
#define Export_h

#include <stdio.h>


void beginRender(void * drawable);

void renderBitmap(void * drawable,int width,int height,int bytePerRow,const void * buffer);

void closeRender(void);

void beginMesh(const char * url);

void drawMesh(void * drawable);

#endif /* Export_h */
