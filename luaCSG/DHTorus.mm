//
//  DHTorus.m
//  luaCSG
//
//  Created by Felix on 01/01/2013.
//  Copyright (c) 2013 Felix Matschke.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


#import "DHTorus.h"

@implementation DHTorus

@synthesize ringRadius = _ringRadius;
@synthesize pipeRadius = _pipeRadius;

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    CGFloat _outerRadius = _ringRadius + _pipeRadius;
    CGFloat _innerRadius = _ringRadius - _pipeRadius;
    CGFloat distance = sqrt(vector.x * vector.x + vector.z * vector.z);
    CGFloat hfactor = _innerRadius / 0.25 + (distance - 0.25) * 2.0 * (_outerRadius / 0.75 - _innerRadius / 0.25);
    CGFloat vfactor = _pipeRadius / 0.25;
//    NSLog(@"distance: %lf, hfactor: %lf, vfactor: %lf", distance, hfactor, vfactor);
    SCNVector3 outputvector = SCNVector3Make(vector.x * hfactor, vector.y * vfactor, vector.z * hfactor);
    return outputvector;
}

// this function is to be overridden
-(void) generateSurface
{
    SCNGeometry *geom = [SCNTorus torusWithRingRadius:_ringRadius pipeRadius:_pipeRadius];
    [self setGeneratedGeometry:geom];
}


-(id) initWithRingRadius:(CGFloat)ringRadius pipeRadius:(CGFloat)pipeRadius
{
    self = [super init];
    if (self) {
        _dirty    = NO;
        _ringRadius = ringRadius;
        _pipeRadius = pipeRadius;
        [super setGeometry:self.generatedGeometry]; // triggers the generation of all the stuff ...
    }
    return self;
}


+(id) torusWithRingRadius:(CGFloat)ringRadius pipeRadius:(CGFloat)pipeRadius
{
    id ret = [[DHTorus alloc] initWithRingRadius:ringRadius pipeRadius:pipeRadius];
    return ret;
}

@end
