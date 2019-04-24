# minetest_city_gen
This works in conjunction with watabou's Medieval Fantasy City Generator to generate expansive and interesting towns and cities for minetest worlds

If everything goes according to plan this mod will become part of a larger minetest game I'm writing called NoMore.

This is very early in dvelopment. Currently it imports JSON encoded patch and coordinate data exported from a modified version of Medieval Fantasy City Generator, converts this data to form a minetest schematic which defines a single-block high outline of all the buildings and walls. This schematic is then registered into the minetest world but must be manually placed. The ID of the registered schematic is output to output_schem.txt

Future versions will generate individual schematics for each of the buildings and place them relative to the walls. Ideally once generated these schematics would be cached and recycled for other cities generated with some variations. The spirit of this is to keep cities interesting and fun to explore.
