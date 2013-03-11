//
//  DHBox.m
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


#import "DHBox.h"

@implementation DHBox

@synthesize width = _width;
@synthesize height = _height;
@synthesize length = _length;


// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
//    NSLog(@"input  vector: %lf %lf %lf", vector.x, vector.y, vector.z);
    SCNVector3 outputvector = SCNVector3Make(vector.x * _width, vector.y * _height, vector.z * _length);
//    NSLog(@"output vector: %lf %lf %lf", outputvector.x, outputvector.y, outputvector.z);
    return outputvector;
}

// this function is to be overridden
-(void) generateSurface
{
    SCNGeometry *geom = [SCNBox boxWithWidth:_width height:_height length:_length chamferRadius:0.0];
    
    [self setGeneratedGeometry:geom];
}


-(id) initWithWidth:(CGFloat)width height:(CGFloat)height length:(CGFloat)length
{
    self = [super init];
    if (self) {
        _dirty    = NO;
        _height   = height;
        _length   = length;
        _width    = width;
        [super setGeometry:self.generatedGeometry]; // triggers the generation of all the stuff ...
    }
    return self;
}


+(id) boxWithWidth:(CGFloat)width height:(CGFloat)height length:(CGFloat)length
{
    id ret = [[DHBox alloc] initWithWidth:width height:height length:length];
    return ret;
}

@end


