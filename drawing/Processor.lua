local Arc 			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local TextColumn	= require 'TextColumn'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __tonumber 		= tonumber
local __string_match	= string.match

local _DIAL_RADIUS_ = 30
local _DIAL_THICKNESS_ = 5

local _TEXT_Y_OFFSET_ = 10
local _TEXT_LEFT_X_OFFSET_ = 25
local _TEXT_SPACING_ = 22
local _PLOT_SECTION_BREAK_ = 20
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 16
local _TABLE_HEIGHT_ = 80

local NUM_ROWS = 3

local TABLE_CONKY = {{}, {}, {}}

for r = 1, NUM_ROWS do
	TABLE_CONKY[1][r] = '${top name '..r..'}'
	TABLE_CONKY[2][r] = '${top pid '..r..'}'
	TABLE_CONKY[3][r] = '${top cpu '..r..'}'
end

local _DIAL_X_ = _G_INIT_DATA_.LEFT_X + _DIAL_RADIUS_ + _DIAL_THICKNESS_ / 2
local _DIAL_Y_ = _G_INIT_DATA_.MIDDLE_Y + _DIAL_RADIUS_ + _DIAL_THICKNESS_ / 2

local dial = _G_Widget_.Dial{
	x 				= _DIAL_X_,
	y 				= _DIAL_Y_,			
	radius 			= _DIAL_RADIUS_,
	thickness 		= _DIAL_THICKNESS_,
	critical_limit	= '>0.8'
}

local total_load = _G_Widget_.CriticalText{
	x 			= _DIAL_X_,
	y 			= _DIAL_Y_,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%',
}

local inner_ring = _G_Widget_.Arc{
	x = _DIAL_X_,
	y = _DIAL_Y_,
	radius = _DIAL_RADIUS_ - _DIAL_THICKNESS_ / 2 - 2,
	theta0 = 0,
	theta1 = 360
}

local _LINE_1_Y_ = _G_INIT_DATA_.MIDDLE_Y + _TEXT_Y_OFFSET_
local _TEXT_LEFT_X_ = _G_INIT_DATA_.LEFT_X + _DIAL_RADIUS_ * 2 + _TEXT_LEFT_X_OFFSET_ + _DIAL_THICKNESS_
local _RIGHT_X_ = _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH

local process = {
	labels = _G_Widget_.TextColumn{
		x 		= _TEXT_LEFT_X_,
		y 		= _LINE_1_Y_,
		spacing = _TEXT_SPACING_,
		'Running',
		'Sleeping',
		'Zombie'
	},
	totals = _G_Widget_.TextColumn{
		x 			= _RIGHT_X_,
		y 			= _LINE_1_Y_,
		spacing 	= _TEXT_SPACING_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.BLUE,
		num_rows	= 3
	}
}

local _PLOT_Y_ = _G_INIT_DATA_.MIDDLE_Y + _PLOT_SECTION_BREAK_ + _DIAL_RADIUS_ * 2 + _DIAL_THICKNESS_

local plot = _G_Widget_.LabelPlot{
	x 		= _G_INIT_DATA_.LEFT_X,
	y 		= _PLOT_Y_,
	width 	= _G_INIT_DATA_.SECTION_WIDTH,
	height 	= _PLOT_HEIGHT_
}

local tbl = _G_Widget_.Table{
	x 		= _G_INIT_DATA_.LEFT_X,
	y 		= _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
	width 	= _G_INIT_DATA_.SECTION_WIDTH,
	height 	= _TABLE_HEIGHT_,
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

	local totals = process.totals
	TextColumn.set(totals, cr, 1, Util.char_count(process_glob, 'R') - 1)
	TextColumn.set(totals, cr, 2, Util.char_count(process_glob, 'S'))
	TextColumn.set(totals, cr, 3, Util.char_count(process_glob, 'Z'))

	LabelPlot.update(plot, load_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, NUM_ROWS do
			Table.set(tbl, cr, c, r, Util.conky(column[r], '(%S+)'))
		end
	end
end

_DIAL_RADIUS_ = nil
_DIAL_THICKNESS_ = nil
_TEXT_Y_OFFSET_ = nil
_TEXT_LEFT_X_OFFSET_ = nil
_TEXT_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_DIAL_X_ = nil
_DIAL_Y_ = nil
_LINE_1_Y_ = nil
_TEXT_LEFT_X_ = nil
_RIGHT_X_ = nil
_PLOT_Y_ = nil

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
