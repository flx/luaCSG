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
#import <math.h>


#define DH_PRECISION 10000.0 // precision to the 10-thousandth of a unit. As units should be millimeters, this avoids invalid solids from SCNGeometries

// static helper functions for the glib / gts stuff *******************************************************************************************

double roundToPrecision(double v) {
    double w = round(v*DH_PRECISION)/DH_PRECISION;
    // apparently 0 can have a sign - so we are getting rid of the negative zeros ...
    if (w == -0.0) w = 0.0;
    return w;
}

void printTransform(CATransform3D p)
{
    NSLog(@"\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n%9.6f, %9.6f, %9.6f, %9.6f\n",
          p.m11, p.m21, p.m31, p.m41,
          p.m12, p.m22, p.m32, p.m42,
          p.m13, p.m23, p.m33, p.m43,
          p.m14, p.m24, p.m34, p.m44);
}

struct _DHTriangleElement {uint v1, v2, v3; };  typedef struct _DHTriangleElement DHTriangleElement;

// A modifier creating a triangle with the incremental builder.
template <class HDS>
class Build_polyhedron : public CGAL::Modifier_base<HDS> {
    DHPrimitive *p;
    NSArray *vArray;
    NSArray *eArray;
    NSDictionary *refDic;
public:
    Build_polyhedron(DHPrimitive *_p, NSArray *_vArray, NSArray *_eArray, NSDictionary *_refDic) {
        p = _p;
        vArray = _vArray;
        eArray = _eArray;
        refDic = _refDic;
    }
    void operator()( HDS& hds) {
        // Postcondition: `hds' is a valid polyhedral surface.
        CGAL::Polyhedron_incremental_builder_3<HDS> B( hds, true);
        typedef typename HDS::Vertex   Vertex;
        typedef typename Vertex::Point Point;
        B.begin_surface( [vArray count], [eArray count], 0);
        for (NSNumber *n in vArray) {
            SCNVector3 vertex = [p getVector:[n intValue]];
            B.add_vertex( Point( vertex.x, vertex.y, vertex.z));
        }
        
        for (NSData *eData in eArray) {
            DHTriangleElement *triangle = (DHTriangleElement*)[eData bytes];
            B.begin_facet();
            B.add_vertex_to_facet([((NSNumber*)[refDic objectForKey:[NSNumber numberWithInt: triangle->v1]]) intValue]);
            B.add_vertex_to_facet([((NSNumber*)[refDic objectForKey:[NSNumber numberWithInt: triangle->v2]]) intValue]);
            B.add_vertex_to_facet([((NSNumber*)[refDic objectForKey:[NSNumber numberWithInt: triangle->v3]]) intValue]);
            B.end_facet();
        }
        B.end_surface();
    }
};


@implementation DHPrimitive

- (void)addChildNode:(SCNNode *) child
{
    // all nodes are originally in the global coordinate system - now the transforms need to be made relative
    [child setTransform:CATransform3DConcat(child.transform,CATransform3DInvert(self.transform))];
    [super addChildNode:child];
}

- (id)init
{
    self = [super init];
    if (self) {
        _dirty_polyhedron     = YES;
        _dirty_nef_polyhedron = YES;
        _dirty_transform      = YES;
        
        _lastTransform = CATransform3DIdentity;
        
        self.type = DHOpNotSet;
        
        // Add an image
        // NSImage *img = [NSImage imageNamed:@"bnr_hat_only.png"];
        self.generatedMaterial = [SCNMaterial material];
        self.generatedMaterial.diffuse.contents = [NSColor redColor];
        
        // self.generatedMaterial.transparency = 0.5;
        // self.generatedMaterial.transparencyMode = SCNTransparencyModeRGBZero;
        // self.generatedMaterial.transparency = 0.5;
        // self.generatedMaterial.transparencyMode = SCNTransparencyModeAOne;
        // self.generatedMaterial.doubleSided = YES;
        
        // Configure all the material properties
        void(^configureMaterialProperty)(SCNMaterialProperty *materialProperty) = ^(SCNMaterialProperty *materialProperty) {
            // Setup a trilinear filtering to reduce the aliasing when minimizing / maximizing the images
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

-(void) applyTransform: (CATransform3D) t
{
    AffTransform A(t.m11, t.m21, t.m31, t.m41,
                   t.m12, t.m22, t.m32, t.m42,
                   t.m13, t.m23, t.m33, t.m43,
                                        t.m44);
    _nef_polyhedron.transform(A);
}

-(void) applyBooleanOperationsInScene:(SCNScene *)scene
{
//    NSLog(@"+ applyBooleanOperationsInScene");
    [self applyTransform:self.worldTransform];
    if (self.childNodes.count > 0) { // are there any?
        for (DHPrimitive *p in self.childNodes) {
            [p applyBooleanOperationsInScene:scene]; // apply boolean operations on child nodes before
            Nef_polyhedron n1 = [self nef_polyhedron];
            Nef_polyhedron n2 = [p nef_polyhedron];
            if      (DHUnion        == [p type]) n1 += n2;
            else if (DHDifference   == [p type]) n1 -= n2;
            else if (DHIntersection == [p type]) n1 *= n2;
            else NSLog(@"No boolean operation performed. -> %i", [p type]);
            _nef_polyhedron.clear();
            _nef_polyhedron = n1;
        }
        for (DHPrimitive *p in self.childNodes) {
            [p removeFromParentNode];
            // keep child nodes around - transparently // This doesnt work any more as we dont reconvert everything all the time.
            // [scene.rootNode addChildNode:p];
            // p.geometry.firstMaterial.transparency = 0.9;
            // p.geometry.firstMaterial.transparencyMode = SCNTransparencyModeRGBZero;
        }
    }
//    NSLog(@"- applyBooleanOperationsInScene");
}


-(Polyhedron) polyhedron
{
    if (!_dirty_polyhedron) return _polyhedron;
    [self generate];
    return _polyhedron;
}

-(Nef_polyhedron) nef_polyhedron
{
    if (!_dirty_nef_polyhedron) return _nef_polyhedron;
    // Only create the nef polyhedron if there is any need -- this code should never be run
    _nef_polyhedron.clear();
    Nef_polyhedron N1(_polyhedron);
    _nef_polyhedron = N1;
    _dirty_nef_polyhedron = NO;
    
    return _nef_polyhedron;
}

// this to override the geometry produced by SceneKit primitives ...
-(SCNVector3) transformVector:(SCNVector3) vector
{
    // generically this should not do anything - so just return the vector as is
    return vector;
}


-(SCNVector3) getVector:(uint)i
{
    SCNGeometrySource *vectorSource = [[self.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex] objectAtIndex:0];
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
            return [self transformVector:SCNVector3Make((CGFloat) roundToPrecision(dx), (CGFloat) roundToPrecision(dy), (CGFloat) roundToPrecision(dz))];
        } else if ([vectorSource bytesPerComponent] == 8) {
            CGFloat dx,dy,dz;
            [[vectorSource data] getBytes:&dx range: NSMakeRange(i*stride + offset                  , nbytes)];
            [[vectorSource data] getBytes:&dy range: NSMakeRange(i*stride + nbytes + offset         , nbytes)];
            [[vectorSource data] getBytes:&dz range: NSMakeRange(i*stride + nbytes + nbytes + offset, nbytes)];
            return [self transformVector:SCNVector3Make((CGFloat) roundToPrecision(dx), (CGFloat) roundToPrecision(dy), (CGFloat) roundToPrecision(dz))];
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

-(void) generate
{
    // subclasses can override generateGeometry or generatePolyhedron - and return YES for the overridden method that now returns NO all the time
    
    if (![self generateGeometry]) {
        // geometry has not been generated so try to generate the polyhedron
        if ([self generatePolyhedron])
            // polyhedron has been generated - now derive geometry from polyhedron
            [self geometryFromPolyhedron];
        else
            NSLog(@"*************** couldn't generate geometry or polyhedron");
    } else {
        // geometry has been generated - now derive polyhedron from it
        [self polyhedronFromGeometry];
    }
}

// this function is to be overridden
-(BOOL) generatePolyhedron
{
    return NO; // indicate that no polyhedron has been generated
}

// this function is to be overridden
-(BOOL) generateGeometry
{
    return NO; // indicate that no geometry has been generated
}

-(void) polyhedronFromGeometry
{
    // empty the polyhedron first
    _polyhedron.clear();
    
    SCNGeometrySource *vertices = [[self.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex] objectAtIndex:0];
    
    NSMutableArray *vertexArray = [NSMutableArray arrayWithCapacity:[vertices vectorCount]]; // vertexArray[polyhedronIndex] = vertex index in geometry
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for vertex coordinates vs vertex reference
    NSMutableDictionary *refDic1 = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for mapping duplicate vertices to the first occurrence of the vertex
    NSMutableDictionary *refDic2 = [NSMutableDictionary dictionaryWithCapacity:[vertices vectorCount]]; // dictionary for mapping unique vertices to the actual numbering in the polyhedron
    int j = 0;
    
    // set up vertexArray and refDic2 - which allows to map the original vertice numbers to the ones used for the polyhedron
    for (int i = 0; i<[vertices vectorCount]; i++) {
        SCNVector3 vertex = [self getVector:i];
        NSString *key = [NSString stringWithFormat:@"%.10le|%.10le|%.10le", vertex.x, vertex.y, vertex.z];
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
    
    // set up the element array
    NSMutableArray *elementArray = [NSMutableArray arrayWithCapacity:[self.geometry geometryElementCount]];
    SCNGeometryElement *element;
    for (int i=0; i<[self.geometry geometryElementCount]; i++) {
        element = [self.geometry geometryElementAtIndex:i];
        for(int j=0; j<[element primitiveCount]; j++) {
            DHTriangleElement triangle = [self getElement:j fromGeometryElement:element];
            NSData *eData = [NSData dataWithBytes: &triangle length:sizeof(DHTriangleElement)];
            [elementArray addObject: eData];
        }
    }
    
    Build_polyhedron<HalfedgeDS> surfaceBuilder(self, vertexArray, elementArray, refDic2);
    _polyhedron.delegate(surfaceBuilder);
    
    _dirty_polyhedron = NO;
    Nef_polyhedron n(_polyhedron);
    _nef_polyhedron.clear();
    _nef_polyhedron = n;
    _dirty_nef_polyhedron = NO;
    
    BOOL closed1 = _polyhedron.is_closed();
    BOOL valid1 = _polyhedron.is_valid() ;
    if (!(closed1 && valid1))
        NSLog(@"_polyhedron is %@ and %@", closed1 ? @"closed" : @"open", valid1 ? @"valid" : @"not valid");
}

-(void) geometryFromPolyhedron
{
//    NSLog(@"+geometryFromPolyhedron");

    if(_nef_polyhedron.is_simple()) {
        NSLog(@"convert nef_polyhedron back to polyhedron");
        _polyhedron.clear();
        _nef_polyhedron.convert_to_polyhedron(_polyhedron);
        //                    [self geometryFromPolyhedron];
    } else
        NSLog(@"****************** _polyhedron is not a 2-manifold.");

    
    unsigned long nfacets   = _polyhedron.size_of_facets();
    unsigned long nvertices = nfacets * 3; // we create 3 new vertices per facet to not create shared normals - we don't have information on the actual normals

    NSMutableData *verticeData    = [NSMutableData dataWithLength:sizeof(double) * 3 * nvertices];
    NSMutableData *normalData     = [NSMutableData dataWithLength:sizeof(double) * 3 * nvertices];
    //    NSMutableData *textureMapData = [NSMutableData dataWithLength:sizeof(double) * 2 * nvertices]; // TextureMaps are not implemented yet.
    NSMutableData *elementData    = [NSMutableData dataWithLength:sizeof(uint)   * 3 * nfacets];
    
    uint vindex = 0;
    uint findex = 0;
    for (Facet_iterator i = _polyhedron.facets_begin(); i != _polyhedron.facets_end(); ++i) {
        Halfedge_facet_circulator j = i->facet_begin();
        // Facets in polyhedral surfaces are at least triangles.
        CGAL_assertion( CGAL::circulator_size(j) >= 3);
        if (CGAL::circulator_size(j) != 3) NSLog(@"Found facet with more than 3 vertices.");
        
        Point_3 p[3];
        double x[3], y[3], z[3];
        uint ind=0;
        do {
            // write vertices - every face gets its own 3 vertices as I can't know when they should have common vertices and normals *****
            if (ind>2) NSLog(@"Error! non-triangular facet found!");
            else {
                p[ind] = j->vertex()->point();
                x[ind] = p[ind].x().to_double();
                y[ind] = p[ind].y().to_double();
                z[ind] = p[ind].z().to_double();
            }
            ind++;
        } while ( ++j != i->facet_begin());

        Vector_3 n = CGAL::normal(p[0], p[1], p[2]);
        
        double nx = n.x().to_double();
        double ny = n.y().to_double();
        double nz = n.z().to_double();
        double norm = sqrt(nx*nx + ny*ny + nz*nz);
        
        for (int k=0; k<3; k++) {
            // write vertices - every face gets its own 3 vertices as I can't know when they should have common vertices and normals *****
            ((double*)[verticeData mutableBytes])[vindex*3]   = x[k];
            ((double*)[verticeData mutableBytes])[vindex*3+1] = y[k];
            ((double*)[verticeData mutableBytes])[vindex*3+2] = z[k];
            // write normals *****
            ((double*)[normalData mutableBytes])[vindex*3]   = nx / norm;
            ((double*)[normalData mutableBytes])[vindex*3+1] = ny / norm;
            ((double*)[normalData mutableBytes])[vindex*3+2] = nz / norm;
            vindex++;
        }
        
        // write triangle data
        ((uint*)[elementData mutableBytes])[findex*3]   = vindex - 3;
        ((uint*)[elementData mutableBytes])[findex*3+1] = vindex - 2;
        ((uint*)[elementData mutableBytes])[findex*3+2] = vindex - 1;
        findex++;
    }

    
    SCNGeometrySource *verticeSource = [SCNGeometrySource geometrySourceWithVertices:(SCNVector3*)[verticeData mutableBytes] count:nvertices];
    SCNGeometrySource *normalSource  = [SCNGeometrySource geometrySourceWithNormals: (SCNVector3*)[normalData mutableBytes] count:nvertices];
    
    NSArray *sources  = @[verticeSource, normalSource]; //, textureMapData];
    NSArray *elements = @[[SCNGeometryElement geometryElementWithData:elementData
                                                        primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                       primitiveCount:nfacets
                                                        bytesPerIndex:sizeof(uint)]];
    
    
    SCNGeometry *geom = [SCNGeometry geometryWithSources:sources elements:elements];
    [geom setFirstMaterial: [self generatedMaterial]];
    _dirty_polyhedron = NO;
    self.geometry = geom; 
//    NSLog(@"-geometryFromPolyhedron");
}

-(void) safeToSTLFileAtPath:(NSString*) path
{
    if (_dirty_polyhedron) [self generate];
    NSLog(@"Save to STL file: %@", path);
    FILE *fp=fopen([path cStringUsingEncoding:NSUTF8StringEncoding],"w");// "/Users/felix/Desktop/test.stl", "w");
    fprintf (fp, "solid test\n");
    
    for (Facet_iterator i = _polyhedron.facets_begin(); i != _polyhedron.facets_end(); ++i) {
        Halfedge_facet_circulator j = i->facet_begin();
        // Facets in polyhedral surfaces are at least triangles.
        CGAL_assertion( CGAL::circulator_size(j) >= 3);
        if (CGAL::circulator_size(j) != 3) NSLog(@"Found facet with more than 3 vertices.");

        double x[3], y[3], z[3];
        Point_3 p[3];
        uint ind=0;
        do {
            // write vertices - every face gets its own 3 vertices as I can't know when they should have common vertices and normals *****
            p[ind] = j->vertex()->point();
            x[ind] = p[ind].x().to_double();
            y[ind] = p[ind].y().to_double();
            z[ind] = p[ind].z().to_double();
            ind++;
        } while ( ++j != i->facet_begin());
        
        Vector_3 n = CGAL::normal(p[0], p[1], p[2]);
        
        double nx = n.x().to_double();
        double ny = n.y().to_double();
        double nz = n.z().to_double();
        double norm = sqrt(nx*nx + ny*ny + nz*nz);

        fprintf (fp, "facet normal %lf %lf %lf\nouter loop\nvertex %lf %lf %lf\nvertex %lf %lf %lf\nvertex %lf %lf %lf\nendloop\nendfacet\n",
                 nx/norm, ny/norm, nz/norm,
                 x[0], y[0], z[0],
                 x[1], y[1], z[1],
                 x[2], y[2], z[2]);
    }

    fprintf (fp, "endsolid test\n");
    fclose(fp);
}


-(void) setDelta:(double)delta {
    _dirty_polyhedron = YES;
    _dirty_nef_polyhedron = YES;
    _delta = delta;
};

-(void)dealloc
{
    _polyhedron.clear();
    _nef_polyhedron.clear();
}


@end
