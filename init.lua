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
		--io.stderr:write(" by ("..x..","..y..")\n")
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

local filename = "mods/minetest_city_gen/generated_towns/large_city1/streetData.json"
local f = assert(io.open(filename, "r"))
local t = f:read("*all")
f:close()
local building_table = json:decode(t)
local filename = "mods/minetest_city_gen/generated_towns/large_city1/no_farm_buildingData.json"
local f = assert(io.open(filename, "r"))
local t = f:read("*all")
f:close()
local building_table = json:decode(t)

local filename = "mods/minetest_city_gen/generated_towns/large_city1/wallData.json"
local f = assert(io.open(filename, "r"))
local t = f:read("*all")
f:close()
local wall_table = json:decode(t)

Structure = {s_type="structure", low_z = math.huge, high_z = -math.huge, low_x = math.huge, high_x = -math.huge, size_y=5}

function Structure:new (o)
	o = o or {}
	setmetatable(o, self)
	o.verticies = {}
	o.defined_nodes = {}
	self.__index = self
	return o
end

function Structure:insert_point(px,pz)
	local x=math.floor(px*scale)
	local z=math.floor(pz*scale)
	table.insert(self.verticies, {x=x,z=z})
	if z > self.high_z then self.high_z = z end
	if z < self.low_z then self.low_z = z end
	if x > self.high_x then self.high_x = x end
	if x < self.low_x then self.low_x = x end
end 
function Structure:get_size_z () return self.high_z - self.low_z end
function Structure:get_size_y () return self.size_y end
function Structure:get_size_x () return self.high_x - self.low_x end
function Structure:get_x (point_id) 
	local x = self.verticies[point_id].x
	if self.low_x > 0 then 
		x = x - self.low_x
	elseif self.low_x < 0 then x = x + math.abs(self.low_x)
	end
	return x
end
function Structure:get_z (point_id) 
	local z = self.verticies[point_id].z
	if self.low_z > 0 then 
		z = z - self.low_z
	elseif self.low_z < 0 then z = z + math.abs(self.low_z)
	end
	return z
end

function Structure:get_global_x (g_low_x)
	local x = self.low_x
	if g_low_x > 0 then 
		x = x - g_low_x
	elseif g_low_x < 0 then x = x + math.abs(g_low_x)
	end
	return x
end

function Structure:get_global_z (g_low_z)
	local z = self.low_z
	if g_low_z > 0 then 
		z = z - g_low_z
	elseif g_low_z < 0 then z = z + math.abs(g_low_z)
	end
	return z
end

function Structure:get_verticies_count()
	return #self.verticies
end

function Structure:plot(z, y, x, node_type)
	if self.defined_nodes[z] then
		if self.defined_nodes[z][y] then
			if self.defined_nodes[z][y][x] then
				--io.stderr:write("node (" .. z .. "," .. y .. "," .. z .. ") multiple defined\n")
				self.defined_nodes[z][y][x] = {node=node_type}
			else
				self.defined_nodes[z][y][x] = {node=node_type}
			end
		else 
			self.defined_nodes[z][y] = {x=x}
			self.defined_nodes[z][y][x] = {node=node_type}
		end
	else
		self.defined_nodes[z] = {y=y}
		self.defined_nodes[z][y] = {x=x}
		self.defined_nodes[z][y][x] = {node=node_type}
	end
end

function Structure:plotLineLow(x0, y0, x1, y1, level, node_type)
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
		self:plot(y, level, x, node_type)
		if D > 0 then
			y = y + yi
			D = D -2*dx
		end
		D = D + 2*dy
	end
end

function Structure:plotLineHigh(x0, y0, x1, y1, level, node_type)
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
		--io.stderr:write(" by ("..x..","..y..")\n")
		self:plot(y, level, x, node_type)
		if D > 0 then
			x = x + xi
			D = D - 2*dy
		end
		D = D + 2*dx
	end
end
function Structure:plotLine(org_y, nxt_y, org_x, nxt_x, level, node_type)
	if math.abs(nxt_y - org_y) < math.abs(nxt_x - org_x) then
		if org_x > nxt_x then
			self:plotLineLow(nxt_x, nxt_y, org_x, org_y, level, node_type)
		else
			self:plotLineLow(org_x, org_y, nxt_x, nxt_y, level, node_type)
		end
	else
		if org_y > nxt_y then
			self:plotLineHigh(nxt_x, nxt_y, org_x, org_y, level, node_type)
		else
			self:plotLineHigh(org_x, org_y, nxt_x, nxt_y, level, node_type)
		end
	end
end

function Structure:buildPerimeter(node_type)
	for y =0,self:get_size_y() do
		for i = 1,self:get_verticies_count() do
			--print(inspect(self:get_x(i)))
			local nxt_x = self:get_x(1)
			local nxt_z = self:get_z(1)
			if i < #self.verticies then
				nxt_x = self:get_x(i+1)
				nxt_z = self:get_z(i+1)
			end
			self:plotLine(self:get_z(i), nxt_z, self:get_x(i), nxt_x, y, node_type)
		end
	end
end
function Structure:buildFillPlatform(level, node_type)
	local cur = false
	for z =0,self:get_size_z() do
		local first_x = -1
		local last_x = -1
		for x =0,self:get_size_x() do
			if self.defined_nodes[z][level][x] then 
				if first_x < 0 then 
					first_x = x
					last_x = x
				elseif x > last_x then last_x = x
				end
			end
		end
		if first_x >= 0 then
			for x = first_x+1,last_x do
				self:plot(z, level, x, node_type)
			end
		end

	end
end



function Structure:buildAddDoors()
	local filename = "errr.txt"
	for i = 1,self:get_verticies_count() do
		local nxt_x = self:get_x(1)
		local nxt_z = self:get_z(1)
		if i < #self.verticies then
			nxt_x = self:get_x(i+1)
			nxt_z = self:get_z(i+1)
		end
		local mid_z = math.floor(((self:get_z(i)+ nxt_z )/2)+0.5)
		local mid_x = math.floor(((self:get_x(i)+ nxt_x)/2)+0.5)
		local trys = {
			function (mid_z, mid_x) return mid_z+1,mid_x end,
			function (mid_z, mid_x) return mid_z,mid_x+1 end,
			function (mid_z, mid_x) return mid_z-1,mid_x end,
			function (mid_z, mid_x) return mid_z,mid_x-1 end,
			function (mid_z, mid_x) return mid_z+1,mid_x+1 end,
			function (mid_z, mid_x) return mid_z-1,mid_x-1 end,
			function (mid_z, mid_x) return mid_z+1,mid_x-1 end,
			function (mid_z, mid_x) return mid_z-1,mid_x+1 end
		}
		for j,try in pairs(trys) do
			local f = assert(io.open(filename, "w"))
			if self.defined_nodes[mid_z] then
				if self.defined_nodes[mid_z][1] then
					if self.defined_nodes[mid_z][1][mid_x] then
						if self.defined_nodes[mid_z][1][mid_x].node == "air" then
							--print (j.." FUCKK it's AIR")
						else 
							--print(j.."Don't worry champ we got it")
							break
						end
					else
						--print (j.." FFUUUUUUCCCKKKK not even HERE ("..mid_z..","..mid_x..")")
					end
					mid_z,mid_x = try(mid_z,mid_x)
				else break end
			else break end
		end
		self:plot(mid_z, 1, mid_x, "doors:door_wood_a")
		self:plot(mid_z, 2, mid_x, "doors:hidden")
	end
end

function Structure:build ()
	self:buildPerimeter("default:wood")
	if self.s_type ~= "Wall" then
		self:buildFillPlatform(0, "default:stone")
		self:buildFillPlatform(self:get_size_y(), "default:wood")
		self:buildAddDoors()
	end
end

function Structure:get_schematic ()
	local schematic = {size={x=self:get_size_x()+1,y=self:get_size_y()+1,z=self:get_size_z()+1},data={}, yslice_prob={}}
	for i = 0,self.size_y do
		table.insert(schematic.yslice_prob, {ypos=tostring(i), prob="254"})
	end
	for z = 0,self:get_size_z() do
		for y =0,self:get_size_y() do
			for x =0,self:get_size_x() do
				local name = ""
				if pcall(function() name = self.defined_nodes[z][y][x].node end) == false then 
					name = "air"
					if y == 0 then name = "default:dirt" end
				end
				table.insert(schematic.data, {name = name, prob="254", param2="0"})
			end
		end
	end
	return schematic
end

--local name = ""
--for z=0,size_z-1 do
--	for y=0,size_y-1 do
--		for x=0,size_x-1 do
--			if pcall(function() name = defined_nodes[z][y][x].node end) == false then 
--				name = "air"
--			end
--			table.insert(schematic.data, {name = name, prob="254", param2="0"})
--		end
--	end
--end

structures = {}

local defined_nodes = {}
local g_low_z = math.huge
local g_high_z = -math.huge
local g_low_y = math.huge
local g_high_y = -math.huge
local g_low_x = math.huge
local g_high_x = -math.huge
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
		structure = Structure:new({s_type=ward})
		for i,point in pairs(points) do 
			structure:insert_point(point.x, point.y)
			z = math.floor(point.y*scale)
			x = math.floor(point.x*scale)
			if z > g_high_z then g_high_z = z end
			if z < g_low_z then g_low_z = z end
			if x > g_high_x then g_high_x = x end
			if x < g_low_x then g_low_x = x end
			if y > g_high_y then g_high_y = y end
			if y < g_low_y then g_low_y = y end
		end
		table.insert(structures,structure)
	end
end
local z = 0
local y = 0
local x = 0
wall = Structure:new({s_type="Wall"})
wall.size_y = 9
for i,point in pairs(wall_table) do
	wall:insert_point(point.x, point.y)
	z = math.floor(point.y*scale)
	x = math.floor(point.x*scale)
	if z > high_z then high_z = z end
	if z < low_z then low_z = z end
	if x > high_x then high_x = x end
	if x < low_x then low_x = x end
	if y > high_y then high_y = y end
	if y < low_y then low_y = y end
end
for i,structure in pairs(structures) do
	--print(inspect(structure))
	local draw = {}
	for z = 0,structure:get_size_z() do
		draw[z] = {}
		for x = 0,structure:get_size_x() do
			draw[z][x] = "-"
		end
	end
	for i,v in pairs(structure.verticies) do
		--print("("..v.x..","..v.z..") = ("..structure:get_x(i)..","..structure:get_z(i)..")")
		draw[structure:get_z(i)][structure:get_x(i)] = "X"
	end
	for z = 0,structure:get_size_z() do
		for x = 0,structure:get_size_x() do
			--io.stderr:write(draw[z][x])
		end
		--io.stderr:write("\n")
	end
end

local place_x = -620
local place_y = 0
local place_z = 590
local schem_count = 700
print("Building Count: "..#structures)
--wall:build()
--shhh = minetest.register_schematic(wall:get_schematic())
local schematic_ids = {}
for i = 1,schem_count do
	structures[i]:build()
	table.insert(schematic_ids, dump(minetest.register_schematic(structures[i]:get_schematic())))
end
minetest.register_chatcommand("place", {func = function (name, param) 
	--minetest.place_schematic({x=place_x,y=place_y,z=place_z}, shhh, 0, {}, true)
	for i =1,schem_count do
		local schem_x = place_x + structures[i]:get_global_x(low_x)
		local schem_y = place_y
		local schem_z = place_z + structures[i]:get_global_z(low_z)
		print(dump(minetest.place_schematic({x=schem_x,y=schem_y,z=schem_z}, schematic_ids[i], 0, {}, false)))
	end
	return true
end})
local filename = "small_schem.txt"
local f = assert(io.open(filename, "w"))
--f:write("\n" .. inspect(small_schematic_id))
f:close()

--local size_x = high_x - low_x
--local size_y = high_y - low_y
--local size_z = high_z - low_z
--io.stderr:write("x range: "..low_x.." - "..high_x..": size - "..size_x.."\n")
--io.stderr:write("y range: "..low_y.." - "..high_y..": size - "..size_y.."\n")
--io.stderr:write("z range: "..low_z.." - "..high_z..": size - "..size_z.."\n")
--local draw = {}
--for z = 0,size_z do
--	draw[z] = {}
--	for x = 0,size_x do
--		draw[z][x] = "-"
--	end
--end
--
--		
--
--		
--for k,v in pairs(building_table) do
--	local node_type = ""
--	for ward,points in pairs(v) do
--		if ward == "Market" then node_type = "default:stone"
--		elseif ward == "Craftsmen" then node_type = "default:wood"
--		elseif ward == "" then 
--			node_type = "default:cobble"
--			ward = "no ward"
--		else node_type = "default:dirt"
--		end
--		--io.stderr:write(ward .. " - " .. node_type .. "\n") 
--		local z = 0
--		local y = 0
--		local x = 0
--		for i,point in pairs(points) do --converting to a table indexed by minetest coords for schematics z, y, x. (towngen-X = minetest-X, towngen-Y = minetest-Z)
--			z = math.floor(point.y*scale)
--			x = math.floor(point.x*scale)
--			z = adjust_origin(z, g_low_z)
--			x = adjust_origin(x, g_low_x)
--			plot(defined_nodes, node_type, z, y, x)
--			--io.stderr:write("("..x..","..z..") = ")
--			--io.stderr:write(draw[z][x].."\n")
--			--draw[z][x] = i 
--			if i < #points then
--				nxt_z = math.floor(points[i+1].y*scale)
--				nxt_x = math.floor(points[i+1].x*scale)
--				nxt_z = adjust_origin(nxt_z, g_low_z)
--				nxt_x = adjust_origin(nxt_x, g_low_x)
--			else 
--				nxt_z = math.floor(points[1].y*scale)
--				nxt_x = math.floor(points[1].x*scale)
--				nxt_z = adjust_origin(nxt_z, g_low_z)
--				nxt_x = adjust_origin(nxt_x, g_low_x)
--			end
--			--io.stderr:write("to: ("..nxt_x..","..nxt_z..")\n")
--			line(defined_nodes, node_type, z, nxt_z, x, nxt_x, draw)
--		end
--	end
--end
--
--node_type = "default:cobble"
--local z = 0
--local y = 0
--local x = 0
--for i,point in pairs(wall_table) do
--	z = math.floor(point.y*scale)
--	x = math.floor(point.x*scale)
--	z = adjust_origin(z, low_z)
--	x = adjust_origin(x, low_x)
--	plot(defined_nodes, node_type, z, y, x)
--	draw[z][x] = "x"
--	if i < #wall_table then
--		nxt_z = math.floor(wall_table[i+1].y*scale)
--		nxt_x = math.floor(wall_table[i+1].x*scale)
--		nxt_z = adjust_origin(nxt_z, low_z)
--		nxt_x = adjust_origin(nxt_x, low_x)
--	else 
--		nxt_z = math.floor(wall_table[1].y*scale)
--		nxt_x = math.floor(wall_table[1].x*scale)
--		nxt_z = adjust_origin(nxt_z, low_z)
--		nxt_x = adjust_origin(nxt_x, low_x)
--	end
--	line(defined_nodes, node_type, z, nxt_z, x, nxt_x, draw)
--
--end
--
--local schematic = {size={x=size_x,y=size_y,z=size_z},yslice_prob={ypos="0", prob="254"},data={}}
--local name = ""
--for z=0,size_z-1 do
--	for y=0,size_y-1 do
--		for x=0,size_x-1 do
--			if pcall(function() name = defined_nodes[z][y][x].node end) == false then 
--				name = "air"
--			end
--			table.insert(schematic.data, {name = name, prob="254", param2="0"})
--		end
--	end
--end
--local filename = "output_draw.txt"
--local f = assert(io.open(filename, "w"))
--for z = 0,size_z do
--	for x = 0,size_x do
--		f:write(draw[z][x])
--	end
--	f:write("\n")
--end
--f:close()
--local filename = "output_schem.txt"
--local f = assert(io.open(filename, "w"))
--f:write(inspect(schematic.size))
--f:close()
--io.stderr:write(inspect(defined_nodes))
--io.stdout:write(inspect(schematic))
--local filename = "output_schem.txt"
--local f = assert(io.open(filename, "w"))
--f:write(inspect(schematic))
--f:close()
--schematic_id = dump(minetest.register_schematic(schematic))
--local filename = "output_schem.txt"
--local f = assert(io.open(filename, "a"))
--f:write("\n" .. inspect(schematic_id))
--f:close()
