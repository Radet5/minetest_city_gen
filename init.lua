local inspect = require "inspect"
local json = require "JSON"
scale = 2.5

function plot(defined_nodes, node_type, z, y, x)
	if defined_nodes[z] then
		if defined_nodes[z][y] then
			if defined_nodes[z][y][x] then
				--io.stderr:write("node (" .. z .. "," .. y .. "," .. z .. ") multiple defined\n")
			else
				defined_nodes[z][y][x] = {node=node_type}
			end
		else 
			defined_nodes[z][y] = {x=x}
			defined_nodes[z][y][x] = {node=node_type}
		end
	else
		defined_nodes[z] = {y=y}
		defined_nodes[z][y] = {x=x}
		defined_nodes[z][y][x] = {node=node_type}
	end
end

function line(defined_nodes, node_type, org_y, nxt_y, org_x, nxt_x, draw)
	if math.abs(nxt_y - org_y) < math.abs(nxt_x - org_x) then
		if org_x > nxt_x then
			plotLineLow(nxt_x, nxt_y, org_x, org_y, defined_nodes, node_type, draw)
		else
			plotLineLow(org_x, org_y, nxt_x, nxt_y, defined_nodes, node_type, draw)
		end
	else
		if org_y > nxt_y then
			plotLineHigh(nxt_x, nxt_y, org_x, org_y, defined_nodes, node_type, draw)
		else
			plotLineHigh(org_x, org_y, nxt_x, nxt_y, defined_nodes, node_type, draw)
		end
	end
end
--local delta_x = nxt_x - org_x
--if delta_x == 0 then io.stderr:write("We fucked") end
--local delta_y = nxt_y - org_y
--local sign_delta_y = delta_y / math.abs(delta_y)
--local delta_err = math.abs(delta_y / delta_x)
--local err = 0.0
--local y = org_y
--for x = org_x,nxt_x do
--	plot(defined_nodes, node_type, y, 0, x)
--	if draw then draw[y][x] = "X" end
--	err = err + delta_err
--	if err >= 0.5 then y = y + sign_delta_y
--		err = err - 1.0
--	end
--		
--end

function plotLineLow(x0, y0, x1, y1, defined_nodes, node_type, draw)
	local dx = x1 - x0
	local dy = y1 - y0
	local yi = 1
	if dy < 0 then
		yi = -1
		dy = dy * (-1)
	end
	local D = 2*dy - dx
	local y = y0

	for x = x0,x1 do
		plot(defined_nodes, node_type, y, 0, x)
		if draw then draw[y][x] = "X" end
		if D > 0 then
			y = y + yi
			D = D -2*dx
		end
		D = D + 2*dy
	end
end

function plotLineHigh(x0, y0, x1, y1, defined_nodes, node_type, draw)
	local dx = x1 - x0
	local dy = y1 - y0
	local xi = 1
	if dx < 0 then
		xi = -1
		dx = dx * (-1)
	end
	local D = 2*dx - dy
	local x = x0

	for y = y0,y1 do
		io.stderr:write(" by ("..x..","..y..")\n")
		plot(defined_nodes, node_type, y, 0, x)
		if draw then draw[y][x] = "X" end
		if D > 0 then
			x = x + xi
			D = D - 2*dy
		end
		D = D + 2*dx
	end
end


function adjust_origin(x, low_x)
	if low_x > 0 then 
		x = x - low_x
	elseif low_x < 0 then x = x + math.abs(low_x)
	end
	return x
end

local filename = "mods/city_generator/generated_towns/large_city1/buildingData.json"
local f = assert(io.open(filename, "r"))
local t = f:read("*all")
f:close()
local building_table = json:decode(t)

local filename = "mods/city_generator/generated_towns/large_city1/wallData.json"
local f = assert(io.open(filename, "r"))
local t = f:read("*all")
f:close()
local wall_table = json:decode(t)

local defined_nodes = {}
local low_z = math.huge
local high_z = -math.huge
local low_y = math.huge
local high_y = -math.huge
local low_x = math.huge
local high_x = -math.huge


for k,v in pairs(building_table) do
	for ward,points in pairs(v) do
		local z = 0
		local y = 0
		local x = 0
		for i,point in pairs(points) do 
			z = math.floor(point.y*scale)
			x = math.floor(point.x*scale)
			if z > high_z then high_z = z end
			if z < low_z then low_z = z end
			if x > high_x then high_x = x end
			if x < low_x then low_x = x end
			if y > high_y then high_y = y end
			if y < low_y then low_y = y end
		end
	end
end

local size_x = high_x - low_x + 1
local size_y = high_y - low_y + 1
local size_z = high_z - low_z + 1
io.stderr:write("x range: "..low_x.." - "..high_x..": size - "..size_x.."\n")
io.stderr:write("y range: "..low_y.." - "..high_y..": size - "..size_y.."\n")
io.stderr:write("z range: "..low_z.." - "..high_z..": size - "..size_z.."\n")
local draw = {}
for z = 0,size_z+(1*scale) do
	draw[z] = {}
	for x = 0,size_x+(1*scale) do
		draw[z][x] = "-"
	end
end

		

		
for k,v in pairs(building_table) do
	local node_type = ""
	for ward,points in pairs(v) do
		if ward == "Market" then node_type = "default:stone"
		elseif ward == "Craftsmen" then node_type = "default:wood"
		elseif ward == "" then 
			node_type = "default:cobble"
			ward = "no ward"
		else node_type = "default:dirt"
		end
		--io.stderr:write(ward .. " - " .. node_type .. "\n") 
		local z = 0
		local y = 0
		local x = 0
		for i,point in pairs(points) do --converting to a table indexed by minetest coords for schematics z, y, x. (towngen-X = minetest-X, towngen-Y = minetest-Z)
			z = math.floor(point.y*scale)
			x = math.floor(point.x*scale)
			z = adjust_origin(z, low_z)
			x = adjust_origin(x, low_x)
			plot(defined_nodes, node_type, z, y, x)
			io.stderr:write("("..x..","..z..") = ")
			--io.stderr:write(draw[z][x].."\n")
			draw[z][x] = i 
			if i < #points then
				nxt_z = math.floor(points[i+1].y*scale)
				nxt_x = math.floor(points[i+1].x*scale)
				nxt_z = adjust_origin(nxt_z, low_z)
				nxt_x = adjust_origin(nxt_x, low_x)
			else 
				nxt_z = math.floor(points[1].y*scale)
				nxt_x = math.floor(points[1].x*scale)
				nxt_z = adjust_origin(nxt_z, low_z)
				nxt_x = adjust_origin(nxt_x, low_x)
			end
			io.stderr:write("to: ("..nxt_x..","..nxt_z..")\n")
			line(defined_nodes, node_type, z, nxt_z, x, nxt_x, draw)
		end
	end
end

node_type = "default:cobble"
local z = 0
local y = 0
local x = 0
for i,point in pairs(wall_table) do
	z = math.floor(point.y*scale)
	x = math.floor(point.x*scale)
	z = adjust_origin(z, low_z)
	x = adjust_origin(x, low_x)
	plot(defined_nodes, node_type, z, y, x)
	draw[z][x] = "x"
	if i < #wall_table then
		nxt_z = math.floor(wall_table[i+1].y*scale)
		nxt_x = math.floor(wall_table[i+1].x*scale)
		nxt_z = adjust_origin(nxt_z, low_z)
		nxt_x = adjust_origin(nxt_x, low_x)
	else 
		nxt_z = math.floor(wall_table[1].y*scale)
		nxt_x = math.floor(wall_table[1].x*scale)
		nxt_z = adjust_origin(nxt_z, low_z)
		nxt_x = adjust_origin(nxt_x, low_x)
	end
	line(defined_nodes, node_type, z, nxt_z, x, nxt_x, draw)

end

local schematic = {size={x=size_x,y=size_y,z=size_z},yslice_prob={ypos="0", prob="254"},data={}}
local name = ""
for z=0,size_z-1 do
	for y=0,size_y-1 do
		for x=0,size_x-1 do
			if pcall(function() name = defined_nodes[z][y][x].node end) == false then 
				name = "air"
			end
			table.insert(schematic.data, {name = name, prob="254", param2="0"})
		end
	end
end
local filename = "output_draw.txt"
local f = assert(io.open(filename, "w"))
for z = 0,size_z do
	for x = 0,size_x do
		f:write(draw[z][x])
	end
	f:write("\n")
end
f:close()
--io.stderr:write(inspect(defined_nodes))
--io.stdout:write(inspect(schematic))
--local filename = "output_schem.txt"
--local f = assert(io.open(filename, "w"))
--f:write(inspect(schematic))
--f:close()
schematic_id = dump(minetest.register_schematic(schematic))
local filename = "output_schem.txt"
local f = assert(io.open(filename, "w"))
f:write("\n" .. inspect(schematic.size))
f:write("\n" .. inspect(schematic_id))
f:close()
