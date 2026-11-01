NeoLaghaim asset conversion for Laimhara mobile project

Textures
--------
Converted images are in textures\ and preserve their source-folder layout.
NTX images are grouped under textures\variants\ntx\. Files with colliding
base names are separated under textures\variants\<extension>\.

texture_conversion_report.csv lists the source, output, dimensions, and
conversion status for every inspected texture. 23,273 textures were decoded
to PNG, including WXY-wrapped BMP, SEK-wrapped TGA, NTX, BMP, DDS, TGA, and
JPG files.

Unsupported texture files
-------------------------
38 SEK and 7 WXY files could not be decoded. See the report for paths and
decoder errors.

GLB models
----------
182 static GLB models were exported from readable CSY mesh files:
179 character parts, 1 NPC, and 2 pets. Model geometry and available per-mesh
textures are embedded in each GLB. model_conversion_report.csv lists each
source, GLB path, mesh count, vertex count, and triangle count.

Run `python ..\..\tools\laghaim_convert\batch_models.py` from this folder to
repeat the model export. The converter is in
..\..\tools\laghaim_convert\csy_to_glb.py. It exports static meshes only; it
does not yet include skeletons or animations. Most NPC, pet, mount, and item
CSY files have non-plain headers and were skipped; the converter does not
attempt to bypass their protection. Map files and full map geometry are not
converted to GLB.

Android game project
--------------------
Laimhara currently contains an extracted Godot Android export, not an
editable Godot source project. Its scripts and scenes are compiled resources;
project.godot, editable .gd/.tscn sources, and the Godot build tools are not
present. Therefore these assets are prepared for integration, but an updated
installable APK cannot be built from this extracted folder. The editable
Laimhara Godot project and its Android export setup are needed to implement
and build the mobile gameplay changes.
