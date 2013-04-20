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

#include <CGAL/IO/Polyhedron_iostream.h>
#include <CGAL/IO/Polyhedron_VRML_1_ostream.h>
#include <CGAL/Gmpq.h>
#include <CGAL/Simple_cartesian.h>
#include <CGAL/Polyhedron_3.h>
#include <CGAL/Nef_polyhedron_3.h>
#include <CGAL/Polyhedron_incremental_builder_3.h>

// this is the only Kernel that didn't through compiler errors in conjunction with the nef polyhedrons ... 
typedef CGAL::Cartesian<CGAL::Gmpq>    Kernel;
typedef CGAL::Polyhedron_3<Kernel>     Polyhedron;
typedef CGAL::Nef_polyhedron_3<Kernel> Nef_polyhedron;
typedef Kernel::Vector_3               Vector_3;
typedef Kernel::Point_3                Point_3;
typedef Kernel::Aff_transformation_3   AffTransform;

typedef Polyhedron::Vertex_iterator    Vertex_iterator;
typedef Polyhedron::HalfedgeDS         HalfedgeDS;
typedef Polyhedron::Facet_iterator     Facet_iterator;
typedef Polyhedron::Halfedge_around_facet_circulator Halfedge_facet_circulator;

enum {
    DHOpNotSet     = 0, // for nodes that are not children in a boolean operation
    DHUnion        = 1, // Union of self and all childnodes
    DHDifference   = 2, // Difference of self - (union of all childnodes)
    DHIntersection = 3  // Intersection of self and all childnodes
};

@interface DHPrimitive : SCNNode {
    BOOL           _dirty_polyhedron;
    BOOL           _dirty_nef_polyhedron;
    BOOL           _dirty_transform;
    Polyhedron     _polyhedron;
    Nef_polyhedron _nef_polyhedron;
}

// accessors for polyhedra - never to be written to
-(Polyhedron)     polyhedron;
-(Nef_polyhedron) nef_polyhedron;

-(void) generate;
-(BOOL) generatePolyhedron;
-(BOOL) generateGeometry;
-(void) geometryFromPolyhedron;
-(void) safeToSTLFileAtPath:(NSString*) path;

-(void) applyWorldTransform;
-(void) applyTransform: (CATransform3D) t;
-(void) applyBooleanOperationsInScene:(SCNScene *)scene;

// @property (readwrite, nonatomic) SCNGeometry* generatedGeometry;
@property (readwrite, nonatomic) SCNMaterial* generatedMaterial;
@property (readwrite, nonatomic) double       delta;
@property (readwrite, nonatomic) uint         type; // e.g. DHUnion

@end
