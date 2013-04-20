//
//  DHSphere.m
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


#import "DHSphere.h"

@implementation DHSphere

@synthesize radius = _radius;

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    //    NSLog(@"input  vector: %lf %lf %lf", vector.x, vector.y, vector.z);
    SCNVector3 outputvector = SCNVector3Make(vector.x * 2.0 * _radius, vector.y * 2.0 * _radius, vector.z * 2.0 * _radius);
    //    NSLog(@"output vector: %lf %lf %lf", outputvector.x, outputvector.y, outputvector.z);
    return outputvector;
}

// this function is to be overridden
-(BOOL) generateGeometry
{
    SCNGeometry *geom = [SCNSphere sphereWithRadius:_radius];
    [self setGeometry:geom];
    return YES;
}


-(id) initWithRadius:(CGFloat)radius
{
    self = [super init];
    if (self) {
        _radius = radius;
        [self generate];
    }
    return self;
}


+(id) sphereWithRadius:(CGFloat)radius
{
    id ret = [[DHSphere alloc] initWithRadius:radius];
    return ret;
}

@end
