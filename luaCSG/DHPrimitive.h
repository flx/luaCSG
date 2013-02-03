//
//  DHPrimitive.h
//  luaCSG
//
//  Created by Felix on 29/12/2012.
//  Copyright (c) 2012 Felix Matschke.
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


#import <Foundation/Foundation.h>
#import <gts.h>
#import <SceneKit/SceneKit.h>

enum {
    DHUnion = 1,        // Union of self and all childnodes
    DHDifference = 2,   // Difference of self - (union of all childnodes)
    DHIntersection = 3  // Intersection of self and all childnodes
};

@interface DHPrimitive : SCNNode {
    BOOL         _dirty;
    GtsSurface*  _surface;
    GtsFace*     _face; // necessary to destroy _surface (for the traverse)
}

-(GtsSurface *) surface;
-(void) generate;
-(void) generateSurface;
-(void) generateGeometry;
-(void) safeToSTLFileAtPath:(NSString*) path;

-(void) applyLocalTransform;
-(void) applyBooleanTransformationsInScene:(SCNScene *)scene;

@property (readwrite, nonatomic) SCNGeometry* generatedGeometry;
@property (readwrite, nonatomic) SCNMaterial* generatedMaterial;
@property (readwrite, nonatomic) gdouble      delta;
@property (readwrite, nonatomic) uint         type; // e.g. DHUnion

@end
