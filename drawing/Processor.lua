local Arc 			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local TextColumn	= require 'TextColumn'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __tonumber 	= tonumber
local __string_match	= string.match

local MODULE_X = 30
local MODULE_Y = 135
local MODULE_WIDTH = 300

local DIAL_RADIUS = 30
local DIAL_THICKNESS = 5

local TEXT_Y_OFFSET = 10
local TEXT_LEFT_X_OFFSET = 25
local TEXT_SPACING = 22
local PLOT_SECTION_BREAK = 16
local PLOT_HEIGHT = 56
local TABLE_SECTION_BREAK = 16
local TABLE_HEIGHT = 80

local TABLE_CONKY = {}
for c = 1, 3 do TABLE_CONKY[c] = {} end
for r = 1, 3 do TABLE_CONKY[1][r] = '${top name '..r..'}' end
for r = 1, 3 do TABLE_CONKY[2][r] = '${top pid '..r..'}' end
for r = 1, 3 do TABLE_CONKY[3][r] = '${top cpu '..r..'}' end

local DIAL_X = MODULE_X + DIAL_RADIUS + DIAL_THICKNESS / 2
local DIAL_Y = MODULE_Y + DIAL_RADIUS + DIAL_THICKNESS / 2

local dial = _G_Widget_.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= DIAL_THICKNESS,
	critical_limit	= '>0.8'
}

local total_load = _G_Widget_.CriticalText{
	x 			= DIAL_X,
	y 			= DIAL_Y,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%',
}

local inner_ring = _G_Widget_.Arc{
	x = DIAL_X,
	y = DIAL_Y,
	radius = DIAL_RADIUS - DIAL_THICKNESS / 2 - 2,
	theta0 = 0,
	theta1 = 360
}

local LINE_1_Y = MODULE_Y + TEXT_Y_OFFSET
local TEXT_LEFT_X = MODULE_X + DIAL_RADIUS * 2 + TEXT_LEFT_X_OFFSET + DIAL_THICKNESS
local RIGHT_X = MODULE_X + MODULE_WIDTH

local process = {
	labels = _G_Widget_.TextColumn{
		x 		= TEXT_LEFT_X,
		y 		= LINE_1_Y,
		spacing = TEXT_SPACING,
		'Running',
		'Sleeping',
		'Zombie'
	},
	totals = _G_Widget_.TextColumn{
		x 			= RIGHT_X,
		y 			= LINE_1_Y,
		spacing 	= TEXT_SPACING,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.BLUE,
		num_rows	= 3
	}
}

local PLOT_Y = MODULE_Y + PLOT_SECTION_BREAK + DIAL_RADIUS * 2 + DIAL_THICKNESS

local plot = _G_Widget_.LabelPlot{
	x 		= MODULE_X,
	y 		= PLOT_Y,
	width 	= MODULE_WIDTH,
	height 	= PLOT_HEIGHT
}

local TABLE_Y = PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK

local tbl = _G_Widget_.Table{
	x 		= MODULE_X,
	y 		= TABLE_Y,
	width 	= MODULE_WIDTH,
	height 	= TABLE_HEIGHT,
	num_rows= 3,
	'Name',
	'PID',
	'CPU (%)'
}

local N_CPU = __tonumber(__string_match(Util.execute_cmd('lscpu'), 'CPU%(s%):%s+(%d+)'))

local CPU_TABLE = {}
for i = 1, N_CPU do CPU_TABLE[i] = '${cpu '..i..'}' end

local update = function(cr)
	local sum = 0
	for i = 1, N_CPU do
		sum = sum + Util.conky_numeric(CPU_TABLE[i])
	end
	local load_percent = sum * 0.01 / N_CPU
	Dial.set(dial, load_percent)
	
	CriticalText.set(total_load, cr, load_percent * 100)

	local process_glob = Util.execute_cmd('ps -A -o s')
	
	local running 				= Util.char_count(process_glob, 'R')
	local interrupted_sleep 	= Util.char_count(process_glob, 'S')
	local zombie 				= Util.char_count(process_glob, 'Z')

	--subtract one b/c ps will always be "running"
	running = __tonumber(running) - 1

	local totals = process.totals
	TextColumn.set(totals, cr, 1, running)
	TextColumn.set(totals, cr, 2, interrupted_sleep)
	TextColumn.set(totals, cr, 3, zombie)

	LabelPlot.update(plot, load_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, 3 do
			Table.set(tbl, cr, c, r, Util.conky(column[r], '(%S+)'))
		end
	end
end

MODULE_X = nil
MODULE_Y = nil
MODULE_WIDTH = nil
DIAL_RADIUS = nil
DIAL_THICKNESS = nil
TEXT_Y_OFFSET = nil
TEXT_LEFT_X_OFFSET = nil
TEXT_SPACING = nil
PLOT_SECTION_BREAK = nil
PLOT_HEIGHT = nil
TABLE_SECTION_BREAK = nil
TABLE_HEIGHT = nil
DIAL_X = nil
DIAL_Y = nil
LINE_1_Y = nil
TEXT_LEFT_X = nil
RIGHT_X = nil
PLOT_Y = nil
TABLE_Y = nil

local draw = function(cr)
	update(cr)
	Dial.draw(dial, cr)
	Arc.draw(inner_ring, cr)
	CriticalText.draw(total_load, cr)

	TextColumn.draw(process.labels, cr)
	TextColumn.draw(process.totals, cr)

	LabelPlot.draw(plot, cr)

	Table.draw(tbl, cr)
end

return draw
