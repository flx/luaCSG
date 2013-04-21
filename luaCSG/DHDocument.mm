//
//  DHDocument.m
//  luaCSG
//
//  Created by Felix on 22/12/2012.
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


#import "DHDocument.h"
#import "DHSCView.h"
#import <QuartzCore/CATransform3D.h>

#include <stdio.h>
#include <string.h>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

void error (lua_State *L, const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    va_end(argp);
    lua_close(L);
    exit(EXIT_FAILURE);
}

static void stackDump (lua_State *L) {
    NSLog(@"stackdump");
    int i;
    int top = lua_gettop(L);
    for(i=1;i<=top;i++){ /*repeatforeachlevel*/
        int t = lua_type(L, i);
        switch (t) {
            case LUA_TSTRING: {  /* strings */
                printf("’%s’", lua_tostring(L, i));
                break;
            }
            case LUA_TBOOLEAN: {  /* booleans */
                printf(lua_toboolean(L, i) ? "true" : "false");
                break; }
            case LUA_TNUMBER: {  /* numbers */
                printf("%g", lua_tonumber(L, i));
                break;
            }
            default: {  /* other values */
                printf("%s", lua_typename(L, t));
                break; }
        }
        printf("  ");  /* put a separator */
    }
    printf("\n");  /* end the listing */
    NSLog(@"end stackdump");
}

static int move(lua_State *L) {
    //    stackDump(L);
    NSLog(@"move");
    DHPrimitive *p = (__bridge DHPrimitive*) luaL_checkudata(L, -4, "DHPrimitive");
    CGFloat x  = luaL_checknumber(L, -3);  /* get argument */
    CGFloat y = luaL_checknumber(L, -2);  /* get argument */
    CGFloat z = luaL_checknumber(L, -1);  /* get argument */
    
    //    NSLog(@"doc = %@", doc);
    
    if (p) {
        p.transform = CATransform3DConcat(p.transform, CATransform3DMakeTranslation(x, y, z));
    } else NSLog(@"no pointer!");
    
    return 0;  /* number of results */
}

static int rotate(lua_State *L) {
    //    stackDump(L);
    NSLog(@"rotate");    
    DHPrimitive *p = (__bridge DHPrimitive*) luaL_checkudata(L, -5, "DHPrimitive");
    CGFloat x  = luaL_checknumber(L, -4);  /* get argument */
    CGFloat y = luaL_checknumber(L, -3);  /* get argument */
    CGFloat z = luaL_checknumber(L, -2);  /* get argument */
    CGFloat rot = luaL_checknumber(L, -1);  /* get argument */
    
    //    NSLog(@"doc = %@", doc);
    
    if (p) {
        p.transform = CATransform3DConcat(p.transform, CATransform3DMakeRotation(rot, x, y, z));
    } else NSLog(@"no pointer!");
    
    return 0;  /* number of results */
}

static int difference(lua_State *L) {
//    stackDump(L);
    /* retrieve the document pointer */
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
    DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
//#define checkarray(L,i) (__bridge DHPrimitive *)luaL_checkudata(L, i, "DHPrimitive")
    DHPrimitive *p1 = (__bridge DHPrimitive*) luaL_checkudata(L, -2, "DHPrimitive");
    DHPrimitive *p2 = (__bridge DHPrimitive*) luaL_checkudata(L, -1, "DHPrimitive");
    
    
    if (doc && p1 && p2) {
        [p1 addChildNode:p2];
        p2.type = DHDifference;
        [p1 applyBooleanOperationsInScene:doc.scene];
    } else NSLog(@"no pointers!");
    
    return 0;  /* number of results */
}

static int intersection(lua_State *L) {
    /* retrieve the document pointer */
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
        DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    DHPrimitive *p1 = (__bridge DHPrimitive*) luaL_checkudata(L, -2, "DHPrimitive");
    DHPrimitive *p2 = (__bridge DHPrimitive*) luaL_checkudata(L, -1, "DHPrimitive");
    
    
    if (doc && p1 && p2) {
        [p1 addChildNode:p2];
        p2.type = DHIntersection;
        [p1 applyBooleanOperationsInScene:doc.scene];
    } else NSLog(@"no pointers!");
    
    return 0;  /* number of results */
}

static int do_union(lua_State *L) {
    NSLog(@"union");
    /* retrieve the document pointer */
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
    DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    DHPrimitive *p1 = (__bridge DHPrimitive*) luaL_checkudata(L, -2, "DHPrimitive");
    DHPrimitive *p2 = (__bridge DHPrimitive*) luaL_checkudata(L, -1, "DHPrimitive");
    
    
    if (doc && p1 && p2) {
        [p1 addChildNode:p2];
        p2.type = DHUnion;
        [p1 applyBooleanOperationsInScene:doc.scene];
//        [p1 safeToSTLFileAtPath:@"/Users/felix/Desktop/union.stl"];
    } else NSLog(@"no pointers!");
    
    return 0;  /* number of results */
}


static int create_box (lua_State *L) {
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
        DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    if (doc) {
        CGFloat width  = luaL_checknumber(L, -3);  /* get argument */
        CGFloat height = luaL_checknumber(L, -2);  /* get argument */
        CGFloat length = luaL_checknumber(L, -1);  /* get argument */
        DHPrimitive *p = [DHBox boxWithWidth:width height:height length:length];
        [doc addPrimitive:p];
        lua_pushlightuserdata(L, (__bridge void *)p);  /* push result */
    } else {
        NSLog(@"Error - could not retrieve document pointer from registry.");
        lua_pushlightuserdata(L, nil);
    }
    
    luaL_getmetatable(L, "DHPrimitive");
    lua_setmetatable(L, -2);
    
    return 1;  /* number of results */
}

static int create_cone (lua_State *L) {
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
        DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    if (doc) {
        CGFloat bradius  = luaL_checknumber(L, -2);  /* get argument */
        CGFloat height = luaL_checknumber(L, -1);  /* get argument */
        DHPrimitive *p = [DHCone coneWithBottomRadius:bradius height:height];
        [doc addPrimitive:p];
        lua_pushlightuserdata(L, (__bridge void *)p);  /* push result */
    } else {
        NSLog(@"Error - could not retrieve document pointer from registry.");
        lua_pushlightuserdata(L, nil);
    }
    
    luaL_getmetatable(L, "DHPrimitive");
    lua_setmetatable(L, -2);

    return 1;  /* number of results */
}

static int create_tube(lua_State *L) {
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
        DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    if (doc) {
        CGFloat iradius  = luaL_checknumber(L, -3);  /* get argument */
        CGFloat oradius  = luaL_checknumber(L, -2);  /* get argument */
        CGFloat height = luaL_checknumber(L, -1);  /* get argument */
        DHPrimitive *p = [DHTube tubeWithInnerRadius:iradius outerRadius:oradius height:height];
        [doc addPrimitive:p];
        lua_pushlightuserdata(L, (__bridge void *)p);  /* push result */
    } else {
        NSLog(@"Error - could not retrieve document pointer from registry.");
        lua_pushlightuserdata(L, nil);
    }
    
    luaL_getmetatable(L, "DHPrimitive");
    lua_setmetatable(L, -2);

    return 1;  /* number of results */
}

static int create_sphere(lua_State *L) {
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
        DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    if (doc) {
        CGFloat radius = luaL_checknumber(L, -1);  /* get argument */
        DHPrimitive *p = [DHSphere sphereWithRadius:radius];
        [doc addPrimitive:p];
        lua_pushlightuserdata(L, (__bridge void *)p);  /* push result */
    } else {
        NSLog(@"Error - could not retrieve document pointer from registry.");
        lua_pushlightuserdata(L, nil);
    }
    
    luaL_getmetatable(L, "DHPrimitive");
    lua_setmetatable(L, -2);

    return 1;  /* number of results */
}

static int create_cylinder(lua_State *L) {
    lua_pushstring(L, "doc");  /* push key */
    lua_gettable(L, LUA_REGISTRYINDEX);  /* retrieve value */
        DHDocument* doc = (__bridge DHDocument*) lua_topointer(L, -1);
    lua_pop(L,1);
    
    if (doc) {
        CGFloat radius = luaL_checknumber(L, -2);  /* get argument */
        CGFloat height = luaL_checknumber(L, -1);  /* get argument */
        DHPrimitive *p = [DHCylinder cylinderWithRadius:radius height:height];
        [doc addPrimitive:p];
        lua_pushlightuserdata(L, (__bridge void *)p);  /* push result */
    } else {
        NSLog(@"Error - could not retrieve document pointer from registry.");
        lua_pushlightuserdata(L, nil);
    }
    
    luaL_getmetatable(L, "DHPrimitive");
    lua_setmetatable(L, -2);
    
    return 1;  /* number of results */
}

@implementation DHDocument

@synthesize scene = _scene;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"DHDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

-(void) addPrimitive:(DHPrimitive*) p
{
    [sceneView.scene.rootNode addChildNode:p];
}

-(void) initScene
{
    //    // Configure the SCNView.
    sceneView.allowsCameraControl = YES;              // Allow the user to manipulate the 3D model using SCNView's default behavior.
                                                      //    sceneView.jitteringEnabled = YES;                 // Improve the antialiasing when the scene is stationary.
                                                      //    sceneView.playing = YES;                          // Play the animations.
    sceneView.autoenablesDefaultLighting = YES;       // Automatically light scenes that have no light.
    
    
    sceneView.backgroundColor = [NSColor grayColor];
    
    // Create the scene and get the root
    sceneView.scene = [SCNScene scene];
    SCNNode *root = sceneView.scene.rootNode;

    
    // Turn on the lights!     // ******************************************************************************************
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeDirectional;
    root.light = light;
    
    // Ambient light
    SCNLight *alight = [SCNLight light];
    alight.type = SCNLightTypeDirectional;
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = alight;
    ambientLightNode.position = SCNVector3Make(3.0, 3.0, 5.0);
    ambientLightNode.rotation = SCNVector4Make(1.0, 0.3, 0.0, -30.0/180.0*3.1415);
    [root addChildNode:ambientLightNode];
    _scene = sceneView.scene;
}

- (void)awakeFromNib {
//    [self initScene];
    if (content) [sourceView setString:content];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    // NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    // @throw exception;
    
    NSLog(@"data type: %@",typeName);
    NSData *ret = [[sourceView string] dataUsingEncoding:NSUTF8StringEncoding];
    return ret;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    // NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    // @throw exception;

    content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return YES;
}

-(IBAction)run:(id)sender
{
    NSLog(@"run!");
    [self initScene]; // reset everything to 0
    if (sourceView.string) {
        const char *buff = sourceView.string.UTF8String;
        int error;
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);        /* opens the standard libraries */
        
        lua_pushcfunction(L, create_box);
        lua_setglobal(L, "box");
        
        lua_pushcfunction(L, create_cone);
        lua_setglobal(L, "cone");
        
        lua_pushcfunction(L, create_tube);
        lua_setglobal(L, "tube");
        
        lua_pushcfunction(L, create_sphere);
        lua_setglobal(L, "sphere");
        
        lua_pushcfunction(L, create_cylinder);
        lua_setglobal(L, "cylinder");
        
        lua_pushcfunction(L, move);
        lua_setglobal(L, "move");
        
        lua_pushcfunction(L, rotate);
        lua_setglobal(L, "rotate");
        
        lua_pushcfunction(L, difference);
        lua_setglobal(L, "difference");
        
        lua_pushcfunction(L, intersection);
        lua_setglobal(L, "intersection");
        
        lua_pushcfunction(L, do_union);
        lua_setglobal(L, "union");
        
        luaL_newmetatable(L, "DHPrimitive");
        
        lua_pushstring(L, "doc");  /* push key */
        lua_pushlightuserdata(L, (__bridge void *)self);  /* push value */
        lua_settable(L, LUA_REGISTRYINDEX);  /* registry[key] = value */        

        error = luaL_loadbuffer(L, buff, strlen(buff), self.displayName.UTF8String) ||
        lua_pcall(L, 0, 0, 0);
        if (error) {
            fprintf(stderr, "%s", lua_tostring(L, -1));
            lua_pop(L, 1);  /* pop error message from the stack */
        }
        lua_close(L);    }
}


@end

//
//    void(^create)(DHPrimitive *p1, DHPrimitive *p2, short op, SCNVector3 t, NSString *name) = ^(DHPrimitive *p1, DHPrimitive *p2, short op, SCNVector3 t, NSString *name) {
//        p1.position = t;
//        p2.position = SCNVector3Make(t.x + 0.5, t.y + 0.1, t.z + 1.0);
//        p1.type = op;
////        [p1 generateGeometry];
////        [p2 generateGeometry];
//        [p1 addChildNode:p2];
//        [p1 applyBooleanOperations];
//        [root addChildNode:p1];
//        [p1 safeToSTLFileAtPath:[NSString stringWithFormat:@"/Users/felix/Desktop/%@.stl", name]];
//    };
//
//    create([DHBox boxWithWidth:1.0 height:2.0 length:3.0],              [DHBox boxWithWidth:1.0 height:2.0 length:3.0],              DHUnion, SCNVector3Make( 0.0, 0.0, 0.0), @"DHUnion-boxes");
//    create([DHCylinder cylinderWithRadius:1.5 height:2.0],              [DHCylinder cylinderWithRadius:2.0 height:3.0],              DHUnion, SCNVector3Make( 5.0, 0.0, 0.0), @"DHUnion-cylinder");
//    create([DHCone coneWithBottomRadius:2.0 height:3.0],                [DHCone coneWithBottomRadius:2.5 height:2.0],                DHUnion, SCNVector3Make(10.0, 0.0, 0.0), @"DHUnion-cone");
//    create([DHTube tubeWithInnerRadius:2.0 outerRadius:2.1 height:2.0], [DHTube tubeWithInnerRadius:1.5 outerRadius:2.0 height:2.1], DHUnion, SCNVector3Make(15.0, 0.0, 0.0), @"DHUnion-Tube");
//    create([DHSphere sphereWithRadius:2.0],                             [DHSphere sphereWithRadius:2.4],                             DHUnion, SCNVector3Make(20.0, 0.0, 0.0), @"DHUnion-sphere");
//
//    create([DHBox boxWithWidth:1.0 height:2.0 length:3.0],              [DHBox boxWithWidth:1.0 height:2.0 length:3.0],              DHDifference, SCNVector3Make( 0.0,5.0, 0.0), @"DHDiff-boxes");
//    create([DHCylinder cylinderWithRadius:1.5 height:2.0],              [DHCylinder cylinderWithRadius:2.0 height:3.0],              DHDifference, SCNVector3Make( 5.0,5.0, 0.0), @"DHDiff-cylinder");
//    create([DHCone coneWithBottomRadius:2.0 height:3.0],                [DHCone coneWithBottomRadius:2.5 height:2.0],                DHDifference, SCNVector3Make(10.0,5.0, 0.0), @"DHDiff-cone");
//    create([DHTube tubeWithInnerRadius:2.0 outerRadius:2.1 height:2.0], [DHTube tubeWithInnerRadius:1.5 outerRadius:2.0 height:2.1], DHDifference, SCNVector3Make(15.0,5.0, 0.0), @"DHDiff-Tube");
//    create([DHSphere sphereWithRadius:2.0],                             [DHSphere sphereWithRadius:2.4],                             DHDifference, SCNVector3Make(20.0,5.0, 0.0), @"DHDiff-sphere");
//
//    create([DHBox boxWithWidth:1.0 height:2.0 length:3.0],              [DHBox boxWithWidth:1.0 height:2.0 length:3.0],              DHIntersection, SCNVector3Make( 0.0,10.0, 0.0), @"DHInters-boxes");
//    create([DHCylinder cylinderWithRadius:1.5 height:2.0],              [DHCylinder cylinderWithRadius:2.0 height:3.0],              DHIntersection, SCNVector3Make( 5.0,10.0, 0.0), @"DHInters-cylinder");
//    create([DHCone coneWithBottomRadius:2.0 height:3.0],                [DHCone coneWithBottomRadius:2.5 height:2.0],                DHIntersection, SCNVector3Make(10.0,10.0, 0.0), @"DHInters-cone");
//    create([DHTube tubeWithInnerRadius:2.0 outerRadius:2.1 height:2.0], [DHTube tubeWithInnerRadius:1.5 outerRadius:2.0 height:2.1], DHIntersection, SCNVector3Make(15.0,10.0, 0.0), @"DHInters-Tube");
//    create([DHSphere sphereWithRadius:2.0],                             [DHSphere sphereWithRadius:2.4],                             DHIntersection, SCNVector3Make(20.0,10.0, 0.0), @"DHInters-sphere");
