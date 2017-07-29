local Line 			= require 'Line'
local Text			= require 'Text'
local CriticalText	= require 'CriticalText'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __tonumber 		= tonumber
local __string_match	= string.match

local _SEPARATOR_SPACING_ = 20
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

local _RIGHT_X_ = _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH

local process = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _G_INIT_DATA_.MIDDLE_Y,
		text 	= 'R | S | Z'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _G_INIT_DATA_.MIDDLE_Y,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.BLUE,
	}
}

local _SEP_Y_ = _G_INIT_DATA_.MIDDLE_Y + _SEPARATOR_SPACING_

local separator = _G_Widget_.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_}
}

local _LINE_2_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local total_load = {
	label = _G_Widget_.Text{
		x 			= _G_INIT_DATA_.LEFT_X,
		y 			= _LINE_2_Y_,
		text 		= 'CPU Load'
	},
	value = _G_Widget_.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _LINE_2_Y_,
		x_align 	= 'right',
		append_end 	= '%',
	}
}

local _PLOT_Y_ = _LINE_2_Y_ + _PLOT_SECTION_BREAK_

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
	num_rows= NUM_ROWS,
	'Name',
	'PID',
	'CPU (%)'
}

local N_CPU = __tonumber(__string_match(Util.execute_cmd('lscpu'), 'CPU%(s%):%s+(%d+)'))

local CPU_TABLE = {}
for i = 1, N_CPU do CPU_TABLE[i] = '${cpu '..i..'}' end

local update = function(cr)
	local sum = 0
	for i = 1, N_CPU do	sum = sum + Util.conky_numeric(CPU_TABLE[i]) end
	local load_percent = sum * 0.01 / N_CPU
	
	local process_glob = Util.execute_cmd('ps -A -o s')

	Text.set(process.value, cr, (Util.char_count(process_glob, 'R') - 1)..' | '..
	  Util.char_count(process_glob, 'S')..' | '..
	  Util.char_count(process_glob, 'Z'))

	CriticalText.set(total_load.value, cr, load_percent * 100)

	LabelPlot.update(plot, load_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, NUM_ROWS do
			Table.set(tbl, cr, c, r, Util.conky(column[r], '(%S+)'))
		end
	end
end

_SEPARATOR_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_SEP_Y_ = nil
_LINE_2_Y_ = nil
_RIGHT_X_ = nil
_PLOT_Y_ = nil

local draw = function(cr)
	update(cr)

	Text.draw(process.label, cr)
	Text.draw(process.value, cr)

	Line.draw(separator, cr)
	
	Text.draw(total_load.label, cr)
	CriticalText.draw(total_load.value, cr)

	LabelPlot.draw(plot, cr)

	Table.draw(tbl, cr)
end

return draw
