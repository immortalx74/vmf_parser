UI = require "ui/ui"

local lines_t = {}
local brush_coords_strings = {}
local brush_coords = {}
local boxes = {}
local level = { w = 15, d = 600, h = 25, name = "D:\\dev\\lovr\\projects\\VRBat\\levels\\su" }

local coins_coords_strings = {}
local coins_coords = {}

local player_start_coords_strings = {}
local player_start_coords = { x = 0, y = 0, v = 0 }

local game_end_coords_strings = {}
local game_end_z = 0

local function split( str, delimiter )
	local result = {}
	for part in str:gmatch( "[^" .. delimiter .. "]+" ) do
		result[ #result + 1 ] = part
	end
	return result
end

local function ReadVMF()
	local file = io.open( level.name .. ".vmf", "r" )
	for line in file:lines() do
		lines_t[ #lines_t + 1 ] = line
	end
	file:close()
end

local function StoreRawVMFCoords()
	-- store lines that contain brush indices
	for i, v in ipairs( lines_t ) do
		local l = split( v, '"' )
		for j, k in ipairs( l ) do
			if k == "TOOLS/TOOLSNODRAW" then
				brush_coords_strings[ #brush_coords_strings + 1 ] = lines_t[ i - 1 ]
			end
			if k == "info_node#1" then
				coins_coords_strings[ #coins_coords_strings + 1 ] = lines_t[ i + 1 ]
			end
			if k == "info_player_start" then
				player_start_coords_strings[ #player_start_coords_strings + 1 ] = lines_t[ i + 1 ]
			end
			if k == "light" then
				game_end_coords_strings[ #game_end_coords_strings + 1 ] = lines_t[ i + 5 ]
			end
		end
	end

	-- parse actual brush coordinates
	for i, v in ipairs( brush_coords_strings ) do
		for word in v:gmatch( "%b()" ) do
			word = word:sub( 2, -2 )
			local l = split( word, " " )
			local count = 1
			local c = {}
			for j, k in ipairs( l ) do
				c[ #c + 1 ] = tonumber( k )
			end

			brush_coords[ #brush_coords + 1 ] = { x = c[ 1 ], y = c[ 3 ], z = c[ 2 ] }
		end
	end

	-- parse actual coin coordinates
	for i, v in ipairs( coins_coords_strings ) do
		local l = split( v, '"' )
		local str = l[ #l ]
		local crds = split( str, " " )
		local coin = { x = tonumber( crds[ 1 ] ) /39.37, y = tonumber( crds[ 3 ] ) /39.37, z = tonumber( crds[ 2 ] ) /39.37 }
		coins_coords[ #coins_coords + 1 ] = coin
	end

	-- parse player_start
	for i, v in ipairs( player_start_coords_strings ) do
		local l = split( v, '"' )
		local str = l[ #l ]
		local crds = split( str, " " )
		player_start_coords.x = tonumber( crds[ 1 ] ) /39.37
		player_start_coords.y = tonumber( crds[ 3 ] ) /39.37
		player_start_coords.z = tonumber( crds[ 2 ] ) /39.37
	end

	-- parse game_end
	for i, v in ipairs( game_end_coords_strings ) do
		local l = split( v, '"' )
		local str = l[ #l ]
		local crds = split( str, " " )
		game_end_z = tonumber( crds[ 2 ] ) /39.37
	end
end

local function StoreBoxes()
	local minx = math.huge
	local maxx = -math.huge
	local miny = math.huge
	local maxy = -math.huge
	local minz = math.huge
	local maxz = -math.huge

	local counter = 0

	for i, v in ipairs( brush_coords ) do
		if v.x < minx then minx = v.x end
		if v.x > maxx then maxx = v.x end
		if v.y < miny then miny = v.y end
		if v.y > maxy then maxy = v.y end
		if v.z < minz then minz = v.z end
		if v.z > maxz then maxz = v.z end

		counter = counter + 1

		if counter == 18 then
			counter = 0
			boxes[ #boxes + 1 ] = { minx = minx /39.37, maxx = maxx /39.37, miny = miny /39.37, maxy = maxy /39.37, minz = -maxz /39.37, maxz = -minz /39.37 }
			minx = math.huge
			maxx = -math.huge
			miny = math.huge
			maxy = -math.huge
			minz = math.huge
			maxz = -math.huge
		end
	end
end

local function SaveLevel()
	local file = io.open( level.name .. "_col.txt", "w" )
	file:write( level.w, ",", level.d, ",", level.h, ",", level.name, ",", player_start_coords.x, ",", player_start_coords.y, ",", player_start_coords.z, ",",
		game_end_z, "\n" )
	for i, v in ipairs( boxes ) do
		file:write( v.minx, ",", v.maxx, ",", v.miny, ",", v.maxy, ",", v.minz, ",", v.maxz, "\n" )
	end
	file:close()

	local file = io.open( level.name .. "_coins.txt", "w" )
	for i, v in ipairs( coins_coords ) do
		file:write( v.x, ",", v.y, ",", -v.z, "\n" )
	end
	file:close()
	print( "saved" )
end

local function DrawBoxes( pass )
	for i, v in ipairs( boxes ) do
		local m = mat4( vec3( (v.maxx + v.minx) / 2, (v.maxy + v.miny) / 2, (v.maxz + v.minz) / 2 ), vec3( (v.maxx - v.minx), (v.maxy - v.miny), (v.maxz - v.minz) ) )
		pass:box( m, "line" )
	end
end

function lovr.load()
	UI.Init()

end

function lovr.update( dt )
	UI.InputInfo()
end

function lovr.draw( pass )
	UI.NewFrame( pass )

	UI.Begin( "test", mat4( 0, 1.4, -1 ) )
	local _
	_, level.w = UI.SliderInt( "Level width", level.w, 10, 50, 556 )
	_, level.d = UI.SliderInt( "Level depth", level.d, 50, 600, 556 )
	_, level.h = UI.SliderInt( "Level height", level.h, 3, 70, 556 )
	local got_focus, buffer_changed, textbox_id
	got_focus, buffer_changed, textbox_id, level.name = UI.TextBox( "Level name", 16, level.name )
	if UI.Button( "Load VMF" ) then
		ReadVMF()
		StoreRawVMFCoords()
		StoreBoxes()
	end
	if UI.Button( "Save" ) then
		SaveLevel()

	end
	UI.End( pass )

	pass:setColor( 1, 0, 0 )
	pass:box( mat4( vec3( 0, 0.32, 0 ), vec3( 2.56, 0.64, 5.12 ) ), "line" )
	pass:setColor( 1, 0, 1 )
	DrawBoxes( pass )

	local ui_passes = UI.RenderFrame( pass )
	table.insert( ui_passes, pass )
	return lovr.graphics.submit( ui_passes )
end
