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


static void jitter(gpointer data, gpointer user_data)
{
    gdouble r1 = 1.0e-3*((float)random()/RAND_MAX*2.0 - 1.0),
            r2 = 1.0e-3*((float)random()/RAND_MAX*2.0 - 1.0),
            r3 = 1.0e-3*((float)random()/RAND_MAX*2.0 - 1.0);
    GtsVertex* vertex = (GtsVertex*) data;
    vertex->p.x += r1;
    vertex->p.y += r2;
    vertex->p.z += r3;
}

static void overlapfunc (GtsBBox *bb1, GtsBBox *bb2, gpointer data)
{
    *(BOOL*)data = YES;
}

static void build_list (gpointer data, GSList ** list)
{
    /* always use O(1) g_slist_prepend instead of O(n) g_slist_append */
    *list = g_slist_prepend (*list, data);
}

static void build_list1 (gpointer data, GList ** list)
{
    /* always use O(1) g_list_prepend instead of O(n) g_list_append */
    *list = g_list_prepend (*list, data);
}

static void delete_surface(GtsSurface *s)
{
    GSList * faces = NULL;
    GSList * i;
    gts_surface_foreach_face(s, (GtsFunc) build_list, &faces);
    i = faces;
    while (i) {
        GtsFace * t = i->data;
        gts_surface_remove_face(s, t);
        i = i->next;
    }
    gts_object_destroy (GTS_OBJECT (s));
    g_slist_free(faces);
}

static void triangle_cleanup (GtsSurface * s)
{
    GSList * triangles = NULL;
    GSList * i;
    gts_surface_foreach_face (s, (GtsFunc) build_list, &triangles);
    /* remove duplicate triangles */
    i = triangles;
    while (i) {
        GtsTriangle * t = i->data;
        // destroy t, its edges (if not used by any other triangle) and its corners (if not used by any other edge)
        if (gts_triangle_is_duplicate (t)) gts_object_destroy (GTS_OBJECT (t));
		i = i->next;
    }
    
    /* free list of triangles */
    g_slist_free (triangles);
}

static void triangle_revert (GtsSurface * s)
{
    GSList * triangles = NULL;
    GSList * i;
    gts_surface_foreach_face (s, (GtsFunc) build_list, &triangles);
    i = triangles;
    while (i) {
        GtsTriangle * t = i->data;
        gts_triangle_revert(t);
		i = i->next;
    }
    g_slist_free (triangles);
}

static void edge_deduplicate (GtsSurface *surface)
{
    GList * edges = NULL;
    gts_surface_foreach_edge (surface, (GtsFunc) build_list1, &edges);
    gts_edges_merge(edges);
    g_list_free (edges);
}

static void edge_cleanup (GtsSurface *surface)
{
    GSList * edges = NULL;
    GSList * i;
    int j;
    gts_surface_foreach_edge (surface, (GtsFunc) build_list, &edges);
    /* We want to control manually the destruction of edges */
    gts_allow_floating_edges = TRUE;
    i = edges;
    j = 0;
    while (i) {
        j++;
        GtsEdge * e = i->data;
        GtsEdge * duplicate;
         // if edge is degenerate, destroy
        if (GTS_SEGMENT (e)->v1 == GTS_SEGMENT (e)->v2) gts_object_destroy (GTS_OBJECT (e));
        else if ((duplicate = gts_edge_is_duplicate (e))) { // if duplicate, replace e with its duplicate and destroy e
            gts_edge_replace (e, duplicate);
            gts_object_destroy (GTS_OBJECT (e));
        }
        i = i->next;
    }
    /* don't forget to reset to default */
    gts_allow_floating_edges = FALSE;
    g_slist_free (edges);
}

void printTransform(CATransform3D p)
{
    NSLog(@"\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n",
          p.m11, p.m21, p.m31, p.m41,
          p.m12, p.m22, p.m32, p.m42,
          p.m13, p.m23, p.m33, p.m43,
          p.m14, p.m24, p.m34, p.m44);
}

struct _DHTriangleElement {guint v1, v2, v3; };  typedef struct _DHTriangleElement DHTriangleElement;

static void apply_matrix (GtsPoint * p, gpointer * data)
{
    p->x = ((CATransform3D*)data)->m11 * p->x + ((CATransform3D*)data)->m21 * p->y + ((CATransform3D*)data)->m31 * p->z + ((CATransform3D*)data)->m41;
    p->y = ((CATransform3D*)data)->m12 * p->x + ((CATransform3D*)data)->m22 * p->y + ((CATransform3D*)data)->m32 * p->z + ((CATransform3D*)data)->m42;
    p->z = ((CATransform3D*)data)->m13 * p->x + ((CATransform3D*)data)->m23 * p->y + ((CATransform3D*)data)->m33 * p->z + ((CATransform3D*)data)->m43;
}

static void write_face (GtsTriangle * t, gpointer * data)
{
    *((GtsFace**)data[6]) = (GtsFace *)t; // keep a reference to a face around for traversal at destruction
    
    // triangle data - these are the vertex indices from the hashtable
    GtsVertex *v1, *v2, *v3;
    gts_triangle_vertices(t,&v1,&v2,&v3);

    guint v1i = (*((guint *) data[4]));
    guint v2i = (*((guint *) data[4]))+1;
    guint v3i = (*((guint *) data[4]))+2;

    // write vertices - every face gets its own 3 vertices as I can't know when they should have common vertices and normals *****
    ((gdouble*)data[0])[v1i*3]   = v1->p.x; ((gdouble*)data[0])[v1i*3+1] = v1->p.y; ((gdouble*)data[0])[v1i*3+2] = v1->p.z;
    ((gdouble*)data[0])[v2i*3]   = v2->p.x; ((gdouble*)data[0])[v2i*3+1] = v2->p.y; ((gdouble*)data[0])[v2i*3+2] = v2->p.z;
    ((gdouble*)data[0])[v3i*3]   = v3->p.x; ((gdouble*)data[0])[v3i*3+1] = v3->p.y; ((gdouble*)data[0])[v3i*3+2] = v3->p.z;

    // write triangle data
    ((guint*)data[3])[(*((guint *) data[7]))*3]   = v1i; // = GPOINTER_TO_UINT (g_hash_table_lookup (data[5], v1));
    ((guint*)data[3])[(*((guint *) data[7]))*3+1] = v2i; // = GPOINTER_TO_UINT (g_hash_table_lookup (data[5], v2));
    ((guint*)data[3])[(*((guint *) data[7]))*3+2] = v3i; // = GPOINTER_TO_UINT (g_hash_table_lookup (data[5], v3));
    
    // write normals *****
    gdouble x,y,z;
    gts_triangle_normal(t, &x, &y, &z);
    
    ((gdouble*)data[1])[v1i*3]   = x; ((gdouble*)data[1])[v2i*3]   = x; ((gdouble*)data[1])[v3i*3]   = x;
    ((gdouble*)data[1])[v1i*3+1] = y; ((gdouble*)data[1])[v2i*3+1] = y; ((gdouble*)data[1])[v3i*3+1] = y;
    ((gdouble*)data[1])[v1i*3+2] = z; ((gdouble*)data[1])[v2i*3+2] = z; ((gdouble*)data[1])[v3i*3+2] = z;
    
    (*((guint *) data[4])) += 3; // increment by 3 vertices
    (*((guint *) data[7])) ++;   // increment by 1 face
}

static void stl_write_face (GtsTriangle * t, gpointer * data)
{
    gdouble x,y,z;
    gts_triangle_normal(t, &x, &y, &z);
    gdouble norm = sqrt(x*x + y*y + z*z); //NSLog(@"norm = %lf", norm);
    GtsVertex *v1, *v2, *v3;
    gts_triangle_vertices(t,&v1,&v2,&v3);
    
    fprintf (data[0], "facet normal %lf %lf %lf\nouter loop\nvertex %lf %lf %lf\nvertex %lf %lf %lf\nvertex %lf %lf %lf\nendloop\nendfacet\n",
             x/norm,y/norm,z/norm,
             v1->p.x,v1->p.y,v1->p.z,
             v2->p.x,v2->p.y,v2->p.z,
             v3->p.x,v3->p.y,v3->p.z);
}

void sphereFunc(gdouble **a, GtsCartesianGrid g, guint i, gpointer data)
{
    for (guint j=0; j<g. nx;j++) {
        for (guint k=0; k<g.ny; k++) {
            gdouble x = g.x + j*g.dx;
            gdouble y = g.y + k*g.dy;
            gdouble z = g.z;
            gdouble val = x*x + y*y + z*z - 0.25;
            a[j][k] = val;
        }
    }
}

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
        _surface = nil;
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
    gts_surface_foreach_vertex (_surface, (GtsFunc) apply_matrix, (gpointer*) &transform);
    [self generateGeometry];
    self.transform = CATransform3DIdentity;
    printTransform(self.transform);
}

-(void) applyBooleanTransformationsInScene:(SCNScene *)scene
{
    if (self.childNodes.count > 0) {
        GNode *faces_tree1 = gts_bb_tree_surface(_surface);
        for (DHPrimitive *p in self.childNodes) {
            [p applyLocalTransform]; // in case the thing was moved around a bit more.
            [p applyBooleanTransformationsInScene:scene];
            
            gboolean closed1 = gts_surface_is_closed(_surface);
            gboolean orientable1 = gts_surface_is_orientable(_surface);
            if (!(closed1 && orientable1))
                NSLog(@"surface is %@ and %@",
                      closed1 ? @"closed" : @"open",
                      orientable1 ? @"orientable" : @"not orientable");

            gboolean closed2 = gts_surface_is_closed([p surface]);
            gboolean orientable2 = gts_surface_is_orientable([p surface]);
            if (!(closed2 && orientable2))
                NSLog(@"[p surface] is %@ and %@",
                      closed2 ? @"closed" : @"open",
                      orientable2 ? @"orientable" : @"not orientable");

            BOOL is_open1 = gts_surface_volume (_surface) < 0. ? TRUE : FALSE;
            BOOL is_open2 = gts_surface_volume ([p surface]) < 0. ? TRUE : FALSE;
            
            NSLog(@"surface is %@, [p surface] is %@",is_open1 ? @"open" : @"closed",is_open2 ? @"open" : @"closed");
            
            GNode *faces_tree2 = gts_bb_tree_surface([p surface]);
            
            GtsSurfaceInter* surfaceInter = gts_surface_inter_new(gts_surface_inter_class(), _surface, [p surface], faces_tree1, faces_tree2, NO, NO);
            GtsSurface* tmp;
            //        GSList* intersection = gts_surface_intersection(_surface, [p surface], faces_tree1, faces_tree2); // these are a list of edges on the intersection ... YAY!
            switch (self.type) {
                case DHUnion:
                    tmp = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_1_OUT_2); // add parts of surface 1 that lie outside surface
                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_2_OUT_1); // add parts of surface 2 that lie outside _surface
                    delete_surface(_surface);
                    _surface = tmp;
                    break;
                case DHDifference:
                    tmp = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_2_IN_1); // add parts of surface 2 that lie outside _surface
                    triangle_revert(tmp); // this breaks the closed and orientable condition but keeps it displayable
                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_1_OUT_2); // add parts of surface 2 that lie outside _surface
                    delete_surface(_surface);
                    _surface = tmp;
                    break;
                case DHIntersection:
                    tmp = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_1_IN_2); // add parts of surface 2 that lie outside _surface
                    gts_surface_inter_boolean(surfaceInter, tmp, GTS_2_IN_1); // add parts of surface 2 that lie outside _surface
                    delete_surface(_surface);
                    _surface = tmp;
                    break;
                default:
                    NSLog(@"No valid boolean operation type.");
            }
            gts_kdtree_destroy(faces_tree2);
            //        g_slist_free(intersection);
//            [p removeFromParentNode];
        }
        
        for (DHPrimitive *p in self.childNodes) {
            p.transform = self.worldTransform;
            [scene.rootNode addChildNode:p];
            p.geometry.firstMaterial.transparency = 0.9;
            p.geometry.firstMaterial.transparencyMode = SCNTransparencyModeRGBZero;
        }
        
        gts_kdtree_destroy(faces_tree1);
        
        edge_deduplicate(_surface);
        triangle_cleanup(_surface);
        edge_cleanup(_surface);
        
        [self generateGeometry];
        gboolean closed1 = gts_surface_is_closed(_surface);
        gboolean orientable1 = gts_surface_is_orientable(_surface);
        if (!(closed1 && orientable1))
            NSLog(@"After boolean operation %@ :surface is %@ and %@",
                  self.type == DHUnion ? @"DHUnion" : (self.type == DHDifference ? @"DHDifference" : (self.type == DHIntersection ? @"DHIntersection" : @"unkown")),
                  closed1 ? @"closed" : @"open",
                  orientable1 ? @"orientable" : @"not orientable");
    }
}


-(GtsSurface *) surface
{
    if (_surface && !_dirty) return _surface;
    [self generate];
    return _surface;
}

-(SCNGeometry *) generatedGeometry
{
//    if (_geometry == nil) NSLog(@"Geometry is nil"); else NSLog(@"Geometry is non nil");
//    if (_surface == nil)  NSLog(@"Surface is nil");  else NSLog(@"Surface is non nil");
    if (_generatedGeometry && !_dirty) return _generatedGeometry;
    [self generate];
    return _generatedGeometry;
}

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    return vector;
}


-(SCNVector3) getVector:(guint)i fromGeometrySource: (SCNGeometrySource *) vectorSource
{
    NSInteger nbytes = [vectorSource bytesPerComponent];
    NSInteger stride = [vectorSource dataStride];
    NSInteger offset = [vectorSource dataOffset];
    
    if ([[vectorSource semantic] isEqualToString:SCNGeometrySourceSemanticNormal] ||
        [[vectorSource semantic] isEqualToString:SCNGeometrySourceSemanticVertex]) {
        if ([vectorSource bytesPerComponent] == 4) {
            float dx, dy, dz;
//            r1 = 1.0e-3*((float)random()/RAND_MAX*2.0 - 1.0),
//            r2 = 1.0e-3*((float)random()/RAND_MAX*2.0 - 1.0),
//            r3 = 1.0e-3*((float)random()/RAND_MAX*2.0 - 1.0);
//            NSLog(@"float r1, r2, r3: %g %g %g", 1.0e6*r1, 1.0e6*r2, 1.0e6*r3);
            
            [[vectorSource data] getBytes:&dx range: NSMakeRange(i*stride + offset                  , nbytes)];
            [[vectorSource data] getBytes:&dy range: NSMakeRange(i*stride + nbytes + offset         , nbytes)];
            [[vectorSource data] getBytes:&dz range: NSMakeRange(i*stride + nbytes + nbytes + offset, nbytes)];
//            return [self transformVector:SCNVector3Make((CGFloat) dx + r1, (CGFloat) dy + r2, (CGFloat) dz + r3)];
            return [self transformVector:SCNVector3Make((CGFloat) dx, (CGFloat) dy, (CGFloat) dz)];
        } else if ([vectorSource bytesPerComponent] == 8) {
            CGFloat dx,dy,dz;
//            r1 = 1.0e-3*((CGFloat)random()/RAND_MAX*2.0 - 1.0),
//            r2 = 1.0e-3*((CGFloat)random()/RAND_MAX*2.0 - 1.0),
//            r3 = 1.0e-3*((CGFloat)random()/RAND_MAX*2.0 - 1.0);
//            NSLog(@"CGFloat r1, r2, r3: %g %g %g", 1.0e6*r1, 1.0e6*r2, 1.0e6*r3);

            [[vectorSource data] getBytes:&dx range: NSMakeRange(i*stride + offset                  , nbytes)];
            [[vectorSource data] getBytes:&dy range: NSMakeRange(i*stride + nbytes + offset         , nbytes)];
            [[vectorSource data] getBytes:&dz range: NSMakeRange(i*stride + nbytes + nbytes + offset, nbytes)];
            return [self transformVector:SCNVector3Make((CGFloat) dx, (CGFloat) dy, (CGFloat) dz)];
//            return [self transformVector:SCNVector3Make((CGFloat) dx + r1, (CGFloat) dy + r2, (CGFloat) dz + r3)];
        } else
            NSLog(@"unknown float with %ld bytes per Component.", [vectorSource bytesPerComponent]);
    } else
        NSLog(@"wrong geometry source semantic: %@", [vectorSource semantic]);
    return SCNVector3Make(1.0, 0.0, 0.0);
}

-(DHTriangleElement) getElement:(guint)i fromGeometryElement: (SCNGeometryElement *) geometryElement
{
//    NSLog(@"getting element %d", i);
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
            guint v1, v2, v3;
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

// setting it with a SCNGeometry object - note that this will be not quite right with the primitives ... because they don't contain the real geometry data out of some reason
-(void) setGeneratedGeometry:(SCNGeometry *)geometry
{
    GtsFace *f;
    _generatedGeometry = geometry;
    [_generatedGeometry setFirstMaterial: [self generatedMaterial]];
 
    [self destroy_surface];
    _surface = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());
    
    SCNGeometrySource *vertices = [[geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex] objectAtIndex:0];
    SCNGeometryElement *element;
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for vertex coordinates vs vertex reference
    NSMutableDictionary *refDic = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for mapping duplicate vertices to the first occurrence of the vertex
    
    for (int i = 0; i<[vertices vectorCount]; i++) {
        SCNVector3 vertex = [self getVector:i fromGeometrySource:vertices];
        NSString *key = [NSString stringWithFormat:@"%+.10le|%+.10le|%+.10le", vertex.x, vertex.y, vertex.z];
        NSNumber *n = [dic objectForKey: key];
        if (n == Nil) { // this is the first time we encounter these vertex coordinates
            [dic setObject:[NSNumber numberWithInt:i] forKey:key];
            [refDic setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithInt:i]];
        } else { // coordinates have been found before, do nothing with the vertex dictionary, but put a mapping from the new number to the old
            [refDic setObject:n forKey:[NSNumber numberWithInt:i]];
        }
    }
    
//    NSLog(@"%ld vertices in the generated geometry", [dic count]);

    NSMutableDictionary *vertexArray = [NSMutableDictionary dictionaryWithCapacity:[dic count]];
//    for (int i = 0; i< [refDic count]; i++) [vertexArray addObject:[NSNull null]]; // make sure we can index all values in array. the array will have holes as the vertice references in dic are not necessarily contiguous. (e.g. vertex 2 might be the same as vertex 1 and will not be contained in dic, but vertex 3 exists)
    for (NSNumber *n in [dic allValues]) {
        SCNVector3 vertex = [self getVector:[n intValue] fromGeometrySource:vertices];
        GtsVertex* gtsV = gts_vertex_new(gts_vertex_class(), vertex.x, vertex.y, vertex.z);
        NSValue *gtsVertexVal = [NSValue valueWithPointer:gtsV];
        vertexArray[n] = gtsVertexVal;
    }
    
    for (int i=0; i<[geometry geometryElementCount]; i++) {
        element = [geometry geometryElementAtIndex:i];
        for(int j=0; j<[element primitiveCount]; j++) {
            DHTriangleElement triangle = [self getElement:j fromGeometryElement:element];
            GtsVertex *v1, *v2, *v3;
            [vertexArray[refDic[[NSNumber numberWithInt: triangle.v1]]] getValue:&v1];
            [vertexArray[refDic[[NSNumber numberWithInt: triangle.v2]]] getValue:&v2];
            [vertexArray[refDic[[NSNumber numberWithInt: triangle.v3]]] getValue:&v3];
            
            GtsEdge *e1 = gts_edge_new(gts_edge_class(),v1,v2);
            GtsEdge *e2 = gts_edge_new(gts_edge_class(),v2,v3);
            GtsEdge *e3 = gts_edge_new(gts_edge_class(),v3,v1);
            f  = gts_face_new(gts_face_class(), e1, e2, e3);
            gts_surface_add_face(_surface,f);
        }
    }
    _face = f; // for the traversal at destruction - just keep a reference to the last face
    _dirty = NO;

    GList *vtx = NULL;
    gboolean (* check) (GtsVertex *, GtsVertex *) = NULL;
    gts_surface_foreach_vertex(_surface, (GtsFunc) build_list1, &vtx);
	vtx = gts_vertices_merge (vtx, (gdouble)1e-6, check);
    // g_list_foreach(vtx,(GFunc)jitter, nil); // this to move points around randomly to avoid conflicts in gts ... this does not work.
	g_list_free (vtx);

    triangle_cleanup(_surface);
    edge_cleanup(_surface);
    gboolean closed1 = gts_surface_is_closed(_surface);
    gboolean orientable1 = gts_surface_is_orientable(_surface);
    if (!(closed1 && orientable1))
        NSLog(@"_surface is %@ and %@", closed1 ? @"closed" : @"open", orientable1 ? @"orientable" : @"not orientable");
}


-(void) generate
{
    // generateSurface can set only _surface, but also _geometry, in which case we don't need to run generateGeometry
    if (_surface == nil) [self generateSurface];
    if (_generatedGeometry == nil) [self generateGeometry];
    if (_surface == nil) NSLog(@"huh?");
    _dirty = NO;
}

// this function is to be overridden
-(void) generateSurface
{
    _surface = gts_surface_new(gts_surface_class(), gts_face_class(), gts_edge_class(), gts_vertex_class());

    // sphere through isofunction
    //    GtsCartesianGrid g;
    //    g.nx = g.ny = g.nz = 21;
    //    g.x  = g.y  = g.z  = -0.5;
    //    g.dx = g.dy = g.dz = 0.05;
    //    gts_isosurface_cartesian(_surface, g, (GtsIsoCartesianFunc) sphereFunc, &g, 0.0);
    
    // sphere through ... sphere!

    gts_surface_generate_sphere(_surface, 3);
    gboolean closed1 = gts_surface_is_closed(_surface);
    gboolean orientable1 = gts_surface_is_orientable(_surface);
    if (!(closed1 && orientable1))
        NSLog(@"_surface is %@ and %@", closed1 ? @"closed" : @"open", orientable1 ? @"orientable" : @"not orientable");
}

-(void) generateGeometry
{
    if (_surface == nil) [self generateSurface];
    GtsSurfaceStats stats;
    gts_surface_stats (_surface, &stats);
    guint nvertices = 3 * stats.n_faces; // this is for face_write_dup which is not yet working
    GHashTable *vindex;
    
    NSMutableData *verticeData    = [NSMutableData dataWithLength:sizeof(gdouble)*3*nvertices];
    NSMutableData *normalData     = [NSMutableData dataWithLength:sizeof(gdouble)*3*nvertices];
    NSMutableData *textureMapData = [NSMutableData dataWithLength:sizeof(gdouble)*2*nvertices];
    NSMutableData *elementData    = [NSMutableData dataWithLength:sizeof(guint)  *3*stats.n_faces];

    
    guint n,m; // vertice and face counter
    gpointer data[8];
    data[0] = [verticeData mutableBytes];
    data[1] = [normalData mutableBytes];
    data[2] = [textureMapData mutableBytes];
    data[3] = [elementData mutableBytes];
    data[4] = &n; // counter for vertices
    data[5] = vindex = g_hash_table_new (NULL, NULL);
    data[6] = &_face;
    data[7] = &m;
    
    n = m = 0;
    gts_surface_foreach_face (_surface, (GtsFunc) write_face, data);

    SCNGeometrySource *verticeSource = [SCNGeometrySource geometrySourceWithVertices:[verticeData mutableBytes] count:nvertices];
    SCNGeometrySource *normalSource  = [SCNGeometrySource geometrySourceWithNormals: [normalData mutableBytes] count:nvertices];

    NSArray *sources  = @[verticeSource, normalSource]; //, textureMapData];
    NSArray *elements = @[[SCNGeometryElement geometryElementWithData:elementData
                                                        primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                       primitiveCount:stats.n_faces
                                                        bytesPerIndex:sizeof(guint)]];
    
    
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
    guint n;
    data[0] = fp;
    data[1] = &n;
    fprintf (data[0], "solid test\n");
    gts_surface_foreach_face (_surface, (GtsFunc) stl_write_face, data);
    fprintf (data[0], "endsolid test\n");
    fclose(fp);
}


-(void) setDelta:(gdouble)delta {
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
