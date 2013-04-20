//
//  DHCapsule.m
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


#import "DHCapsule.h"

@implementation DHCapsule

@synthesize capRadius = _capRadius;
@synthesize height = _height;

CGFloat fabs(CGFloat f) {return f < 0.0 ? -f : f;}

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    CGFloat distance = vector.y;
    CGFloat factor = 1.0 + (fabs(distance) - 0.5) * 2.0 * (_height / 2.0 - 1.0);
    //    NSLog(@"distance: %lf, factor: %lf", distance, factor);
    SCNVector3 outputvector = SCNVector3Make(vector.x * 2.0 * _capRadius, vector.y * factor, vector.z * 2.0 * _capRadius);
    return outputvector;
}

// this function is to be overridden
-(void) generateSurface
{
    SCNGeometry *geom = [SCNCapsule capsuleWithCapRadius:_capRadius height:_height];
    [self setGeneratedGeometry:geom];
}


-(id) initWithCapRadius:(CGFloat)capRadius height:(CGFloat)height
{
    self = [super init];
    if (self) {
        _capRadius = capRadius;
        _height = height;
        [super setGeometry:self.generatedGeometry]; // triggers the generation of all the stuff ...
    }
    return self;
}


+(id) capsuleWithCapRadius:(CGFloat)capRadius height:(CGFloat)height
{
    id ret = [[DHCapsule alloc] initWithCapRadius:capRadius height:height];
    return ret;
}

@end
