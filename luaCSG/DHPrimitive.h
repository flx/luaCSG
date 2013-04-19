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
#import <SceneKit/SceneKit.h>

#include <CGAL/Simple_cartesian.h>
#include <CGAL/Polyhedron_3.h>
#include <CGAL/Nef_polyhedron_3.h>
#include <CGAL/Simple_cartesian.h>
#include <CGAL/Polyhedron_incremental_builder_3.h>


typedef CGAL::Simple_cartesian<double>     Kernel;
typedef Kernel::Point_3                    Point_3;
typedef CGAL::Polyhedron_3<Kernel>         Polyhedron;
typedef CGAL::Nef_polyhedron_3<Kernel>     Nef_polyhedron;

typedef Polyhedron::Vertex_iterator        Vertex_iterator;
typedef Polyhedron::HalfedgeDS             HalfedgeDS;

typedef CGAL::Aff_transformation_3<Kernel> AffTransform;

enum {
    DHOpNotSet     = 0, // for nodes that are not children in a boolean operation
    DHUnion        = 1, // Union of self and all childnodes
    DHDifference   = 2, // Difference of self - (union of all childnodes)
    DHIntersection = 3  // Intersection of self and all childnodes
};

@interface DHPrimitive : SCNNode {
    BOOL           _dirty;
    Polyhedron     _surface;
    Nef_polyhedron _nef_surface;
}

-(Polyhedron) surface;
-(Nef_polyhedron) nef_surface;

-(void) generate;
-(void) generateSurface;
-(void) generateGeometry;
-(void) safeToSTLFileAtPath:(NSString*) path;

-(void) applyLocalTransform;
-(void) applyWorldTransform;
-(void) applyTransform: (CATransform3D) t;
-(void) applyBooleanOperationsInScene:(SCNScene *)scene;

@property (readwrite, nonatomic) SCNGeometry* generatedGeometry;
@property (readwrite, nonatomic) SCNMaterial* generatedMaterial;
@property (readwrite, nonatomic) double       delta;
@property (readwrite, nonatomic) uint         type; // e.g. DHUnion

@end
