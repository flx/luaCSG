//
//  DHSCView.m
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


#import "DHSCView.h"

@interface DHSCView ()
@property (weak) SCNMaterial *selectedMaterial;
@end


@implementation DHSCView

- (void)selectNode:(SCNNode *)node geometryElementIndex:(NSUInteger)index {
    [self.selectedMaterial.emission removeAllAnimations];
    self.selectedMaterial = nil;
    
    if (node != nil) {
        // Convert the geometry element index to a material index.
        index = index % [node.geometry.materials count];
        
        // Make the material unique (i.e. unshared).
        SCNMaterial *unsharedMaterial = [[node.geometry.materials objectAtIndex:index] copy];
        [node.geometry replaceMaterialAtIndex:index withMaterial:unsharedMaterial];
        
        // Select the material.
        self.selectedMaterial = unsharedMaterial;
        
        // Animate the material.
        CABasicAnimation *highlightAnimation = [CABasicAnimation animationWithKeyPath:@"contents"];
        highlightAnimation.toValue = [NSColor greenColor];
        highlightAnimation.fromValue = [NSColor blackColor];
        highlightAnimation.repeatCount = MAXFLOAT;
        highlightAnimation.autoreverses = YES;
        highlightAnimation.duration = 0.5;
        highlightAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        [self.selectedMaterial.emission addAnimation:highlightAnimation forKey:@"highlight"];
    }
}

- (void)mouseDown:(NSEvent *)event {
    // Convert the mouse location
    NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    NSArray *hits = [self hitTest:mouseLocation options:nil];
    
    // If there was a hit, select the nearest object; otherwise unselect.
    if ([hits count] > 0) {
        SCNHitTestResult *hit = hits[0]; // Choose the nearest object hit.
        [self selectNode:hit.node geometryElementIndex:hit.geometryIndex];
    }
    else {
        [self selectNode:nil geometryElementIndex:NSNotFound];
    }
    
    [super mouseDown:event];
}

@end
