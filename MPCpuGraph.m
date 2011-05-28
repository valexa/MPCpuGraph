//
//  MPCpuGraph.m
//  MPCpuGraph
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign.
//
//	This program is free software; you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation; either version 2 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#import "MPCpuGraph.h"

#define GRAPH_SIZE	128

static NSBundle* pluginBundle = nil;

@implementation MPCpuGraph

+ (BOOL)initializeClass:(NSBundle*)theBundle {
	if (pluginBundle) {
		return NO;
	}
	pluginBundle = [theBundle retain];
	return YES;
}

+ (void)terminateClass {
	if (pluginBundle) {
		[pluginBundle release];
		pluginBundle = nil;
	}
}

- (id)init{
    self = [super init];
    if(self != nil) {		
        
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here (everything below is optional if you do not have settings nor define events)	
        
        cpuInfo = [[CPUInfo alloc] initWithCapacity:GRAPH_SIZE];
        if (cpuInfo == nil) {
            NSLog(@"ERROR creating CPUInfo object!");            
        }else{
            [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(refreshGraph) userInfo:nil repeats:YES];       
            displayImage = [[NSImage alloc] initWithSize:NSMakeSize(GRAPH_SIZE, GRAPH_SIZE)];
            graphImage = [[NSImage alloc] initWithSize:NSMakeSize(GRAPH_SIZE, GRAPH_SIZE)];                   
        }
					
    }
    return self;
}

- (void)dealloc {
	[super dealloc]; 
    [displayImage release];
    [graphImage release];    
}

- (void)refreshGraph
// get a new sample and refresh the graph
{
	[cpuInfo refresh];
	[self drawDelta];
    NSString *path = [NSString stringWithFormat:@"%@MPCpuGraph.png",NSTemporaryDirectory()];
	NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[graphImage TIFFRepresentation]];		
	NSData *imgdata = [rep representationUsingType:NSPNGFileType properties:nil];    
	[imgdata writeToFile:path atomically:YES];   
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"showDockImage",@"what",path,@"path",nil]];    
}

- (void)drawDelta
// update graphImage (based on previous graphImage), put graph into displayImage
{
    
	CPUData			cpudata, cpudata0;
	unsigned 		cpu, numCPUs = [cpuInfo numCPUs];
	float			graphSpacer = 0.0;
	float			height = ( GRAPH_SIZE - (graphSpacer * (numCPUs - 1) ) ) / numCPUs; // returns just GRAPH_SIZE on single-core machines.
	float			width = GRAPH_SIZE;
	float			y = 0.0, ybottom = 0.0;
	int             barWidth = 4;
	
	[graphImage lockFocus];
    
	// offset the old graph image
	[graphImage compositeToPoint:NSMakePoint(-barWidth, 0) operation:NSCompositeCopy];
    
	for (cpu = 0; cpu < numCPUs; cpu++ ) {
		float yBase = cpu * (height + graphSpacer);
		ybottom = yBase;
		
		if (cpu != 0)
		{
			[[NSColor clearColor] set];
			NSRectFill (NSMakeRect(width - (float)barWidth, ybottom - graphSpacer, (float)barWidth, graphSpacer));
		}
		
		[cpuInfo getLast:&cpudata0 forCPU:cpu];
		[cpuInfo getCurrent:&cpudata forCPU:cpu];
		
		// draw chronological graph into graph image		
		y = cpudata.sys * height;
		[[NSColor redColor] set];
		NSRectFill (NSMakeRect(width - (float)barWidth, ybottom, (float)barWidth, y));
		ybottom += y;		
		
		y = cpudata.user * height;
		[[NSColor greenColor] set];
		NSRectFill (NSMakeRect(width - (float)barWidth, ybottom, (float)barWidth, y));
		ybottom += y;		
		
		y = cpudata.idle * height;
		[[NSColor clearColor] set];
		NSRectFill (NSMakeRect(width - (float)barWidth, ybottom, (float)barWidth, y));
	}
    
	// transfer graph image to icon image
	[graphImage unlockFocus];
	[displayImage lockFocus];
	[graphImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];    
	[displayImage unlockFocus];
}



@end
