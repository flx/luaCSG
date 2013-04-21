//
//  DHDocument.h
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


#import "Primitives.h"
#import <Cocoa/Cocoa.h>
#import "DHSCView.h"
#import <SceneKit/SceneKit.h>

@interface DHDocument : NSDocument {
    IBOutlet NSTextView *sourceView;
    IBOutlet DHSCView *sceneView;
    NSString *content;
}

-(void) addPrimitive:(DHPrimitive*)p;
-(IBAction)run:(id)sender;

@property (readonly) SCNScene *scene;
@property (readwrite, nonatomic) NSMutableArray *primitives;

@end
