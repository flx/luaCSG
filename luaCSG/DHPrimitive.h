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


#include <CGAL/Simple_cartesian.h>
#include <CGAL/Polyhedron_3.h>
#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>


typedef CGAL::Simple_cartesian<double>     Kernel;
typedef Kernel::Point_3                    Point_3;
typedef CGAL::Polyhedron_3<Kernel>         Polyhedron;
typedef Polyhedron::Vertex_iterator        Vertex_iterator;

enum {
    DHUnion = 1,        // Union of self and all childnodes
    DHDifference = 2,   // Difference of self - (union of all childnodes)
    DHIntersection = 3  // Intersection of self and all childnodes
};

@interface DHPrimitive : SCNNode {
    BOOL         _dirty;
    Polyhedron   _surface;
}

-(Polyhedron) surface;
-(void) generate;
-(void) generateSurface;
-(void) generateGeometry;
-(void) safeToSTLFileAtPath:(NSString*) path;

-(void) applyLocalTransform;
-(void) applyBooleanTransformationsInScene:(SCNScene *)scene;

@property (readwrite, nonatomic) SCNGeometry* generatedGeometry;
@property (readwrite, nonatomic) SCNMaterial* generatedMaterial;
@property (readwrite, nonatomic) double      delta;
@property (readwrite, nonatomic) uint         type; // e.g. DHUnion

@end
