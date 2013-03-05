luaCSG is a very early stage scriptable Constructive Solid Geometry (CSG) application.
The idea for luaCSG came from looking at the excellent SceneKit implementation in 
Cocoa while simultaneously using OpenSCAD (http://www.openscad.org).

OpenSCAD uses a custom scripting language to create solids - which exhibits undesirable
effects that I have seen in other ad-hoc scripting languages that evolved out of a data
representation languages.

I wanted to have a scriptable CSG application that uses lua - as lua is powerful
and already debugged. 

Connecting lua and OSX is banal, SceneKit does not require a lot of work out of the
gate, so I needed to connect it to a library for boolean operations on solids. My choice
fell on the GNU triangulated surface library gts (http://gts.sourceforge.net).

Unfortunately gts has bugs and can be unstable with boolean operations - so there are
significant fixes needed in luaCGS / gts to make it remotely usable.

I am currently deliberating abandoning gts and switching to CGAL.