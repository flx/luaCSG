//
//  DHTube.m
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


#import "DHTube.h"

@implementation DHTube

@synthesize innerRadius = _innerRadius;
@synthesize outerRadius = _outerRadius;
@synthesize height = _height;

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    CGFloat distance = sqrt(vector.x * vector.x + vector.z * vector.z);
    CGFloat factor = _innerRadius/0.25 + (distance - 0.25) * 4.0* (_outerRadius / 0.5 - _innerRadius/0.25);
//    NSLog(@"distance: %lf, factor: %lf", distance, factor);
    SCNVector3 outputvector = SCNVector3Make(vector.x * factor, vector.y * _height, vector.z * factor);
    return outputvector;
}

// this function is to be overridden
-(BOOL) generateGeometry
{
    SCNGeometry *geom = [SCNTube tubeWithInnerRadius:_innerRadius outerRadius:_outerRadius height:_height];
    [self setGeometry:geom];
    return YES;
}


-(id) initWithInnerRadius:(CGFloat)innerRadius outerRadius:(CGFloat)outerRadius height:(CGFloat)height
{
    self = [super init];
    if (self) {
        _innerRadius = innerRadius;
        _outerRadius = outerRadius;
        _height   = height;
        [self generate];
    }
    return self;
}


+(id) tubeWithInnerRadius:(CGFloat)innerRadius outerRadius:(CGFloat)outerRadius height:(CGFloat)height
{
    id ret = [[DHTube alloc] initWithInnerRadius:innerRadius outerRadius:outerRadius height:height];
    return ret;
}


@end
