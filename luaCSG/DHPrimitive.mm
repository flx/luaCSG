//
//  DHPrimitive.m
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

#import "DHPrimitive.h"
#import <SceneKit/SceneKit.h>
#import <QuartzCore/CATransform3D.h>

// static helper functions for the glib / gts stuff *******************************************************************************************

void printTransform(CATransform3D p)
{
    NSLog(@"\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n",
          p.m11, p.m21, p.m31, p.m41,
          p.m12, p.m22, p.m32, p.m42,
          p.m13, p.m23, p.m33, p.m43,
          p.m14, p.m24, p.m34, p.m44);
}

struct _DHTriangleElement {uint v1, v2, v3; };  typedef struct _DHTriangleElement DHTriangleElement;

//static void apply_matrix (GtsPoint * p, gpointer * data)
//{
//    p->x = ((CATransform3D*)data)->m11 * p->x + ((CATransform3D*)data)->m21 * p->y + ((CATransform3D*)data)->m31 * p->z + ((CATransform3D*)data)->m41;
//    p->y = ((CATransform3D*)data)->m12 * p->x + ((CATransform3D*)data)->m22 * p->y + ((CATransform3D*)data)->m32 * p->z + ((CATransform3D*)data)->m42;
//    p->z = ((CATransform3D*)data)->m13 * p->x + ((CATransform3D*)data)->m23 * p->y + ((CATransform3D*)data)->m33 * p->z + ((CATransform3D*)data)->m43;
//}

//static void write_face (GtsTriangle * t, gpointer * data)
//{
//    *((GtsFace**)data[6]) = (GtsFace *)t; // keep a reference to a face around for traversal at destruction
//    
//    // triangle data - these are the vertex indices from the hashtable
//    GtsVertex *v1, *v2, *v3;
//    gts_triangle_vertices(t,&v1,&v2,&v3);
//
//    uint v1i = (*((uint *) data[4]));
//    uint v2i = (*((uint *) data[4]))+1;
//    uint v3i = (*((uint *) data[4]))+2;
//
//    // write vertices - every face gets its own 3 vertices as I can't know when they should have common vertices and normals *****
//    ((double*)data[0])[v1i*3]   = v1->p.x; ((double*)data[0])[v1i*3+1] = v1->p.y; ((double*)data[0])[v1i*3+2] = v1->p.z;
//    ((double*)data[0])[v2i*3]   = v2->p.x; ((double*)data[0])[v2i*3+1] = v2->p.y; ((double*)data[0])[v2i*3+2] = v2->p.z;
//    ((double*)data[0])[v3i*3]   = v3->p.x; ((double*)data[0])[v3i*3+1] = v3->p.y; ((double*)data[0])[v3i*3+2] = v3->p.z;
//
//    // write triangle data
//    ((uint*)data[3])[(*((uint *) data[7]))*3]   = v1i; // = GPOINTER_TO_UINT (g_hash_table_lookup (data[5], v1));
//    ((uint*)data[3])[(*((uint *) data[7]))*3+1] = v2i; // = GPOINTER_TO_UINT (g_hash_table_lookup (data[5], v2));
//    ((uint*)data[3])[(*((uint *) data[7]))*3+2] = v3i; // = GPOINTER_TO_UINT (g_hash_table_lookup (data[5], v3));
//    
//    // write normals *****
//    double x,y,z;
//    gts_triangle_normal(t, &x, &y, &z);
//    
//    ((double*)data[1])[v1i*3]   = x; ((double*)data[1])[v2i*3]   = x; ((double*)data[1])[v3i*3]   = x;
//    ((double*)data[1])[v1i*3+1] = y; ((double*)data[1])[v2i*3+1] = y; ((double*)data[1])[v3i*3+1] = y;
//    ((double*)data[1])[v1i*3+2] = z; ((double*)data[1])[v2i*3+2] = z; ((double*)data[1])[v3i*3+2] = z;
//    
//    (*((uint *) data[4])) += 3; // increment by 3 vertices
//    (*((uint *) data[7])) ++;   // increment by 1 face
//}
//
//static void stl_write_face (GtsTriangle * t, gpointer * data)
//{
//    double x,y,z;
//    gts_triangle_normal(t, &x, &y, &z);
//    double norm = sqrt(x*x + y*y + z*z); //NSLog(@"norm = %lf", norm);
//    GtsVertex *v1, *v2, *v3;
//    gts_triangle_vertices(t,&v1,&v2,&v3);
//    
//    fprintf (data[0], "facet normal %lf %lf %lf\nouter loop\nvertex %lf %lf %lf\nvertex %lf %lf %lf\nvertex %lf %lf %lf\nendloop\nendfacet\n",
//             x/norm,y/norm,z/norm,
//             v1->p.x,v1->p.y,v1->p.z,
//             v2->p.x,v2->p.y,v2->p.z,
//             v3->p.x,v3->p.y,v3->p.z);
//}
//
//void sphereFunc(double **a, GtsCartesianGrid g, uint i, gpointer data)
//{
//    for (uint j=0; j<g. nx;j++) {
//        for (uint k=0; k<g.ny; k++) {
//            double x = g.x + j*g.dx;
//            double y = g.y + k*g.dy;
//            double z = g.z;
//            double val = x*x + y*y + z*z - 0.25;
//            a[j][k] = val;
//        }
//    }
//}

@implementation DHPrimitive

@synthesize generatedGeometry = _generatedGeometry;

- (void)addChildNode:(SCNNode *) child
{
    // make child.transform relative to self
//    [self applyLocalTransform];
//    [(DHPrimitive*)child applyLocalTransform];
    NSLog(@"addChildNode");
//    printTransform(child.transform);
//    printTransform(CATransform3DInvert(self.transform));
//    printTransform(CATransform3DConcat(child.transform,CATransform3DInvert(self.transform)));
    child.transform = CATransform3DConcat(child.transform,CATransform3DInvert(self.transform));
//    printTransform(child.transform);
    [super addChildNode:child];
}

- (id)init {
    self = [super init];
    if (self) {
        _dirty = YES;
        _generatedGeometry = nil;
        self.type = DHUnion; // default is union ...
                             // Add the hat image
                             //    NSImage *img = [NSImage imageNamed:@"bnr_hat_only.png"];
        self.generatedMaterial = [SCNMaterial material];
        self.generatedMaterial.diffuse.contents = [NSColor redColor];
        
//        self.generatedMaterial.transparency = 0.5;
//        self.generatedMaterial.transparencyMode = SCNTransparencyModeRGBZero;
//        self.generatedMaterial.transparency = 0.5;
//        self.generatedMaterial.transparencyMode = SCNTransparencyModeAOne;
//        self.generatedMaterial.doubleSided = YES;

        
        // Configure all the material properties
        void(^configureMaterialProperty)(SCNMaterialProperty *materialProperty) = ^(SCNMaterialProperty *materialProperty) {
            // Setup a trilinear filtering
            //   this is to reduce the aliasing when minimizing / maximizing the images
            materialProperty.minificationFilter  = SCNLinearFiltering;
            materialProperty.magnificationFilter = SCNLinearFiltering;
            materialProperty.mipFilter           = SCNLinearFiltering;
            
            // Repeat the texture if necessary
            materialProperty.wrapS = SCNRepeat;
            materialProperty.wrapT = SCNRepeat;
        };
        
        configureMaterialProperty(self.generatedMaterial.ambient);
        configureMaterialProperty(self.generatedMaterial.diffuse);
        configureMaterialProperty(self.generatedMaterial.specular);
        configureMaterialProperty(self.generatedMaterial.emission);
        configureMaterialProperty(self.generatedMaterial.transparent);
        configureMaterialProperty(self.generatedMaterial.reflective);
        configureMaterialProperty(self.generatedMaterial.multiply);
        configureMaterialProperty(self.generatedMaterial.normal);
    }
    return self;
}

-(void) setTransform:(CATransform3D)transform
{
    NSLog(@"setTransform");
    printTransform(transform);
    [super setTransform:transform];
}

-(void) applyLocalTransform
{
    NSLog(@"applyLocalTransform");
    printTransform(self.transform);
    for (SCNNode *node in self.childNodes) [(DHPrimitive*) node applyLocalTransform];
    CATransform3D transform = self.transform;
//    CATransform3D transform = CATransform3DConcat(self.worldTransform, self.transform);
//    gts_surface_foreach_vertex (_surface, (GtsFunc) apply_matrix, (gpointer*) &transform);
    [self generateGeometry];
    self.transform = CATransform3DIdentity;
    printTransform(self.transform);
}

-(void) applyBooleanTransformationsInScene:(SCNScene *)scene
{
    if (self.childNodes.count > 0) {
        // Still needs CGALification
//        GNode *faces_tree1 = gts_bb_tree_surface(_surface);
//        for (DHPrimitive *p in self.childNodes) {
//            [p applyLocalTransform]; // in case the thing was moved around a bit more.
//            [p applyBooleanTransformationsInScene:scene];
//            
//            BOOL closed1 = gts_surface_is_closed(_surface);
//            BOOL orientable1 = gts_surface_is_orientable(_surface);
//            if (!(closed1 && orientable1))
//                NSLog(@"surface is %@ and %@",
//                      closed1 ? @"closed" : @"open",
//                      orientable1 ? @"orientable" : @"not orientable");
//
//            BOOL closed2 = gts_surface_is_closed([p surface]);
//            BOOL orientable2 = gts_surface_is_orientable([p surface]);
//            if (!(closed2 && orientable2))
//                NSLog(@"[p surface] is %@ and %@",
//                      closed2 ? @"closed" : @"open",
//                      orientable2 ? @"orientable" : @"not orientable");
//
//            BOOL is_open1 = gts_surface_volume (_surface) < 0. ? TRUE : FALSE;
//            BOOL is_open2 = gts_surface_volume ([p surface]) < 0. ? TRUE : FALSE;
//            
//            NSLog(@"surface is %@, [p surface] is %@",is_open1 ? @"open" : @"closed",is_open2 ? @"open" : @"closed");
//            
//            GNode *faces_tree2 = gts_bb_tree_surface([p surface]);
//            
//            GtsSurfaceInter* surfaceInter = gts_surface_inter_new(gts_surface_inter_class(), _surface, [p surface], faces_tree1, faces_tree2, NO, NO);
//            GtsSurface* tmp;
//            //        GSList* intersection = gts_surface_intersection(_surface, [p surface], faces_tree1, faces_tree2); // these are a list of edges on the intersection ... YAY!
//            switch (self.type) {
//                case DHUnion:
//                    tmp = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
//                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_1_OUT_2); // add parts of surface 1 that lie outside surface
//                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_2_OUT_1); // add parts of surface 2 that lie outside _surface
//                    delete_surface(_surface);
//                    _surface = tmp;
//                    break;
//                case DHDifference:
//                    tmp = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
//                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_2_IN_1); // add parts of surface 2 that lie outside _surface
//                    triangle_revert(tmp); // this breaks the closed and orientable condition but keeps it displayable
//                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_1_OUT_2); // add parts of surface 2 that lie outside _surface
//                    delete_surface(_surface);
//                    _surface = tmp;
//                    break;
//                case DHIntersection:
//                    tmp = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
//                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_1_IN_2); // add parts of surface 2 that lie outside _surface
//                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_2_IN_1); // add parts of surface 2 that lie outside _surface
//                    delete_surface(_surface);
//                    _surface = tmp;
//                    break;
//                default:
//                    NSLog(@"No valid boolean operation type.");
//            }
//            gts_kdtree_destroy(faces_tree2);
//            //        g_slist_free(intersection);
////            [p removeFromParentNode];
//        }
//        
//        for (DHPrimitive *p in self.childNodes) {
//            p.transform = self.worldTransform;
//            [scene.rootNode addChildNode:p];
//            p.geometry.firstMaterial.transparency = 0.9;
//            p.geometry.firstMaterial.transparencyMode = SCNTransparencyModeRGBZero;
//        }
//        
//        gts_kdtree_destroy(faces_tree1);
//        
//        edge_deduplicate(_surface);
//        triangle_cleanup(_surface);
//        edge_cleanup(_surface);
//        
//        [self generateGeometry];
//        BOOL closed1 = gts_surface_is_closed(_surface);
//        BOOL orientable1 = gts_surface_is_orientable(_surface);
//        if (!(closed1 && orientable1))
//            NSLog(@"After boolean operation %@ :surface is %@ and %@",
//                  self.type == DHUnion ? @"DHUnion" : (self.type == DHDifference ? @"DHDifference" : (self.type == DHIntersection ? @"DHIntersection" : @"unkown")),
//                  closed1 ? @"closed" : @"open",
//                  orientable1 ? @"orientable" : @"not orientable");
    }
}


-(Polyhedron) surface
{
    if (!_dirty) return _surface;
    [self generate];
    return _surface;
}

-(SCNGeometry *) generatedGeometry
{
    if (_generatedGeometry && !_dirty) return _generatedGeometry;
    [self generate];
    return _generatedGeometry;
}

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    // generically this should not transform - so just return the vector untransformed
    return vector;
}


-(SCNVector3) getVector:(uint)i fromGeometrySource: (SCNGeometrySource *) vectorSource
{
    NSInteger nbytes = [vectorSource bytesPerComponent];
    NSInteger stride = [vectorSource dataStride];
    NSInteger offset = [vectorSource dataOffset];
    
    if ([[vectorSource semantic] isEqualToString:SCNGeometrySourceSemanticNormal] ||
        [[vectorSource semantic] isEqualToString:SCNGeometrySourceSemanticVertex]) {
        if ([vectorSource bytesPerComponent] == 4) {
            float dx, dy, dz;
            [[vectorSource data] getBytes:&dx range: NSMakeRange(i*stride + offset                  , nbytes)];
            [[vectorSource data] getBytes:&dy range: NSMakeRange(i*stride + nbytes + offset         , nbytes)];
            [[vectorSource data] getBytes:&dz range: NSMakeRange(i*stride + nbytes + nbytes + offset, nbytes)];
            return [self transformVector:SCNVector3Make((CGFloat) dx, (CGFloat) dy, (CGFloat) dz)];
        } else if ([vectorSource bytesPerComponent] == 8) {
            CGFloat dx,dy,dz;
            [[vectorSource data] getBytes:&dx range: NSMakeRange(i*stride + offset                  , nbytes)];
            [[vectorSource data] getBytes:&dy range: NSMakeRange(i*stride + nbytes + offset         , nbytes)];
            [[vectorSource data] getBytes:&dz range: NSMakeRange(i*stride + nbytes + nbytes + offset, nbytes)];
            return [self transformVector:SCNVector3Make((CGFloat) dx, (CGFloat) dy, (CGFloat) dz)];
        } else
            NSLog(@"unknown float with %ld bytes per Component.", [vectorSource bytesPerComponent]);
    } else
        NSLog(@"wrong geometry source semantic: %@", [vectorSource semantic]);
    return SCNVector3Make(1.0, 0.0, 0.0);
}

-(DHTriangleElement) getElement:(uint)i fromGeometryElement: (SCNGeometryElement *) geometryElement
{
    DHTriangleElement element;
    NSInteger nbytes = [geometryElement bytesPerIndex];
    
    if ([geometryElement primitiveType] == SCNGeometryPrimitiveTypeTriangles) {
        if (nbytes == 2) {
            short v1, v2, v3;
            [[geometryElement data] getBytes:&v1 range: NSMakeRange(i*(3*nbytes)             , nbytes)];
            [[geometryElement data] getBytes:&v2 range: NSMakeRange(i*(3*nbytes) + nbytes    , nbytes)];
            [[geometryElement data] getBytes:&v3 range: NSMakeRange(i*(3*nbytes) + 2 * nbytes, nbytes)];
            element.v1 = v1; element.v2 = v2; element.v3 = v3;
            return element;
        } else if (nbytes == 4) {
            uint v1, v2, v3;
            [[geometryElement data] getBytes:&v1 range: NSMakeRange(i*(3*nbytes)             , nbytes)];
            [[geometryElement data] getBytes:&v2 range: NSMakeRange(i*(3*nbytes) + nbytes    , nbytes)];
            [[geometryElement data] getBytes:&v3 range: NSMakeRange(i*(3*nbytes) + 2 * nbytes, nbytes)];
            element.v1 = v1; element.v2 = v2; element.v3 = v3;
            return element;
        } else
            NSLog(@"unsupported %ld bytes per index.", nbytes);
    } else
        NSLog(@"Can only deal with Triangle primitive types (type 0). Type detected: %d", [geometryElement primitiveType]);
    element.v1 = 0; element.v2 = 0; element.v3 = 0; // return invalid vertices - this will make the edge creation fail and print error messages
    return element;
}

// setting it with a SCNGeometry object - note that this only works half with SCNKit primitives, because they don't seem to contain the real geometry data?
-(void) setGeneratedGeometry:(SCNGeometry *)geometry
{
    _generatedGeometry = geometry;
    [_generatedGeometry setFirstMaterial: [self generatedMaterial]];
 

    // empty the polyhedron first
    _surface.clear();
    
    SCNGeometrySource *vertices = [[geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex] objectAtIndex:0];
    
    // CONTINUE HERE *************************************************************
    
    NSMutableArray *vertexArray = [NSMutableArray arrayWithCapacity:[vertices vectorCount]]; // vertexArray[polyhedronIndex] = vertex index in geometry
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for vertex coordinates vs vertex reference
    NSMutableDictionary *refDic1 = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for mapping duplicate vertices to the first occurrence of the vertex
    NSMutableDictionary *refDic2 = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for mapping unique vertices to the actual numbering in the polyhedron
    int j = 0;
    for (int i = 0; i<[vertices vectorCount]; i++) {
        SCNVector3 vertex = [self getVector:i fromGeometrySource:vertices];
        NSString *key = [NSString stringWithFormat:@"%+.10le|%+.10le|%+.10le", vertex.x, vertex.y, vertex.z];
        NSNumber *n = [dic objectForKey: key];
        if (n == Nil) { // this is the first time we encounter these vertex coordinates
            [dic setObject:[NSNumber numberWithInt:i] forKey:key];
            [refDic1 setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithInt:i]];
            [refDic2 setObject:[NSNumber numberWithInt:j] forKey:[NSNumber numberWithInt:i]];
            j++;
            [vertexArray addObject:[NSNumber numberWithInt:i]]; // only add new vertices to vertexArray
        } else { // coordinates have been found before, do nothing with the vertex dictionary, but put a mapping from the new number to the old
            [refDic1 setObject:n forKey:[NSNumber numberWithInt:i]];
            [refDic2 setObject:[refDic2 objectForKey:n] forKey:[NSNumber numberWithInt:i]]; // get the value for j of the first occurrence of this vertex
        }
    }
    
    //    NSLog(@"%ld vertices in the generated geometry", [dic count]);

    NSMutableDictionary *vertexDict = [NSMutableDictionary dictionaryWithCapacity:[dic count]];
    NSMutableArray *elementArray = [NSMutableArray arrayWithCapacity:[geometry geometryElementCount]];
    
    SCNGeometryElement *element;
    for (int i=0; i<[geometry geometryElementCount]; i++) {
        element = [geometry geometryElementAtIndex:i];
        for(int j=0; j<[element primitiveCount]; j++) {
            DHTriangleElement triangle = [self getElement:j fromGeometryElement:element];
            NSData *eData = [NSData dataWithBytes: &triangle length:sizeof(DHTriangleElement)];
            [elementArray addObject: eData];
        }
    }
    
    int vCount = 0;
    
    CGAL::Polyhedron_incremental_builder_3<HDS> B( hds, true);
    
    B.begin_surface( [[dic allValues] count], [elementArray count], 0);
    for (NSNumber *n in vertexArray) {
        SCNVector3 vertex = [self getVector:[n intValue] fromGeometrySource:vertices];
        B.add_vertex( Point( 0, 0, 0));
    }
    
    for (NSData *eData in elementArray) {
        DHTriangleElement *triangle = (DHTriangleElement*)[eData bytes];
        B.begin_facet();
        B.add_vertex_to_facet([((NSNumber*)[refDic2 objectForKey:[NSNumber numberWithInt: triangle->v1]]) intValue]);
        B.add_vertex_to_facet([((NSNumber*)[refDic2 objectForKey:[NSNumber numberWithInt: triangle->v2]]) intValue]);
        B.add_vertex_to_facet([((NSNumber*)[refDic2 objectForKey:[NSNumber numberWithInt: triangle->v3]]) intValue]);
        B.end_facet();
    }
    B.end_surface();
    
    _dirty = NO;

    BOOL closed1 = _surface.is_closed();
    BOOL valid1 = _surface.is_valid() ;
    if (!(closed1 && valid1))
        NSLog(@"_surface is %@ and %@", closed1 ? @"closed" : @"open", valid1 ? @"valid" : @"not valid");
}


-(void) generate
{
    // generateSurface can set only _surface, but also _geometry, in which case we don't need to run generateGeometry
//    if (_surface == nil)
        [self generateSurface];
    if (_generatedGeometry == nil) [self generateGeometry];
//    if (_surface == nil) NSLog(@"huh?");
    _dirty = NO;
}

// this function is to be overridden
-(void) generateSurface
{
//    _surface = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());

    // sphere through isofunction
    //    GtsCartesianGrid g;
    //    g.nx = g.ny = g.nz = 21;
    //    g.x  = g.y  = g.z  = -0.5;
    //    g.dx = g.dy = g.dz = 0.05;
    //    gts_isosurface_cartesian(_surface, g, (GtsIsoCartesianFunc) sphereFunc, &g, 0.0);
    
    // sphere through ... sphere!

//    gts_surface_generate_sphere(_surface, 3);
//    BOOL closed1 = gts_surface_is_closed(_surface);
//    BOOL orientable1 = gts_surface_is_orientable(_surface);
//    if (!(closed1 && orientable1))
//        NSLog(@"_surface is %@ and %@", closed1 ? @"closed" : @"open", orientable1 ? @"orientable" : @"not orientable");
}

-(void) generateGeometry
{
//    if (_surface == nil)
        [self generateSurface];
//    GtsSurfaceStats stats;
//    gts_surface_stats (_surface, &stats);
//    uint nvertices = 3 * stats.n_faces; // this is for face_write_dup which is not yet working
//    GHashTable *vindex;
    
    NSMutableData *verticeData    = [NSMutableData dataWithLength:sizeof(double)*3*nvertices];
    NSMutableData *normalData     = [NSMutableData dataWithLength:sizeof(double)*3*nvertices];
    NSMutableData *textureMapData = [NSMutableData dataWithLength:sizeof(double)*2*nvertices];
    NSMutableData *elementData    = [NSMutableData dataWithLength:sizeof(uint)  *3*stats.n_faces];

    
    uint n,m; // vertice and face counter
//    gpointer data[8];
    data[0] = [verticeData mutableBytes];
    data[1] = [normalData mutableBytes];
    data[2] = [textureMapData mutableBytes];
    data[3] = [elementData mutableBytes];
    data[4] = &n; // counter for vertices
    data[5] = vindex = g_hash_table_new (NULL, NULL);
    data[6] = &_face;
    data[7] = &m;
    
    n = m = 0;
//    gts_surface_foreach_face (_surface, (GtsFunc) write_face, data);

    SCNGeometrySource *verticeSource = [SCNGeometrySource geometrySourceWithVertices:[verticeData mutableBytes] count:nvertices];
    SCNGeometrySource *normalSource  = [SCNGeometrySource geometrySourceWithNormals: [normalData mutableBytes] count:nvertices];

    NSArray *sources  = @[verticeSource, normalSource]; //, textureMapData];
    NSArray *elements = @[[SCNGeometryElement geometryElementWithData:elementData
                                                        primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                       primitiveCount:stats.n_faces
                                                        bytesPerIndex:sizeof(uint)]];
    
    
    _generatedGeometry = [SCNGeometry geometryWithSources:sources elements:elements];
    [_generatedGeometry setFirstMaterial: [self generatedMaterial]];
    _dirty = NO;
    [super setGeometry:_generatedGeometry];
}

-(void) safeToSTLFileAtPath:(NSString*) path
{
    if (!_surface || _dirty) [self generate];
//    NSLog(@"Save to STL file: %@", path);
    FILE *fp=fopen([path cStringUsingEncoding:NSUTF8StringEncoding],"w");// "/Users/felix/Desktop/test.stl", "w");
    gpointer data[2];
    uint n;
    data[0] = fp;
    data[1] = &n;
    fprintf (data[0], "solid test\n");
    gts_surface_foreach_face (_surface, (GtsFunc) stl_write_face, data);
    fprintf (data[0], "endsolid test\n");
    fclose(fp);
}


-(void) setDelta:(double)delta {
    _dirty = YES;
    _delta = delta;
};

-(void)destroy_surface
{
    if (_surface) {
        GtsSurfaceTraverse *t;
        t = gts_surface_traverse_new(_surface,_face);
        gts_surface_traverse_destroy(t);
    }
}

-(void)dealloc
{
    [self destroy_surface];
}


@end
