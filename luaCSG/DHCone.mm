//
//  DHCone.m
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


#import "DHCone.h"

@implementation DHCone

//@synthesize topRadius = _topRadius;
@synthesize bottomRadius = _bottomRadius;
@synthesize height = _height;

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    //    NSLog(@"input  vector: %lf %lf %lf", vector.x, vector.y, vector.z);
    SCNVector3 outputvector = SCNVector3Make(vector.x * 2.0 * _bottomRadius, vector.y * _height, vector.z * 2.0 * _bottomRadius);
    //    NSLog(@"output vector: %lf %lf %lf", outputvector.x, outputvector.y, outputvector.z);
    return outputvector;
}

// this function is to be overridden
-(void) generateSurface
{
    SCNGeometry *geom = [SCNCone coneWithTopRadius:0.0 bottomRadius:_bottomRadius height:_height];
    
    [self setGeneratedGeometry:geom];
}


-(id) initWithBottomRadius:(CGFloat)bottomRadius height:(CGFloat)height
{
    self = [super init];
    if (self) {
//        _topRadius = topRadius;
        _bottomRadius = bottomRadius;
        _height   = height;
        [super setGeometry:self.generatedGeometry]; // triggers the generation of all the stuff ...
    }
    return self;
}


+(id) coneWithBottomRadius:(CGFloat)bottomRadius height:(CGFloat)height
{
    id ret = [[DHCone alloc] initWithBottomRadius:bottomRadius height:height];
    return ret;
}

@end
