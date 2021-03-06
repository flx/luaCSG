//
//  DHCylinder.m
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


#import "DHCylinder.h"

@implementation DHCylinder

@synthesize radius = _radius;
@synthesize height = _height;

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    SCNVector3 outputvector = SCNVector3Make(vector.x * 2.0 * _radius, vector.y * _height, vector.z * 2.0 * _radius);
    return outputvector;
}

// this function is to be overridden
-(void) generateSurface
{
    SCNGeometry *geom = [SCNCylinder cylinderWithRadius:_radius height:_height];
    [self setGeneratedGeometry:geom];
}


-(id) initWithRadius:(CGFloat)radius height:(CGFloat)height
{
    self = [super init];
    if (self) {
        _dirty    = NO;
        _radius = radius;
        _height = height;
        [super setGeometry:self.generatedGeometry]; // triggers the generation of all the stuff ...
    }
    return self;
}


+(id) cylinderWithRadius:(CGFloat)radius height:(CGFloat)height
{
    id ret = [[DHCylinder alloc] initWithRadius:radius height:height];
    return ret;
}

@end
