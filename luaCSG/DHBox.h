//
//  DHBox.h
//  luaCSG
//
//  Created by Felix on 01/01/2013.
//  Copyright (c) 2013 Felix Matschke.
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

@interface DHBox : DHPrimitive

+(id) boxWithWidth:(CGFloat)width height:(CGFloat)height length:(CGFloat)length;
-(id) initWithWidth:(CGFloat)width height:(CGFloat)height length:(CGFloat)length;

@property (readonly) CGFloat width;
@property (readonly) CGFloat height;
@property (readonly) CGFloat length;

@end
