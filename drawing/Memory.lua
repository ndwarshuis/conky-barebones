local Line 			= require 'Line'
local Text			= require 'Text'
local CriticalText	= require 'CriticalText'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local _SEPARATOR_SPACING_ = 20
local _PLOT_SECTION_BREAK_ = 20
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 16
local _TABLE_HEIGHT_ = 80

local NUM_ROWS = 3

local TABLE_CONKY = {{}, {}, {}}

for r = 1, NUM_ROWS do
	TABLE_CONKY[1][r] = '${top_mem name '..r..'}'
	TABLE_CONKY[2][r] = '${top_mem pid '..r..'}'
	TABLE_CONKY[3][r] = '${top_mem mem '..r..'}'
end

local _RIGHT_X_ = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local total_memory = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _G_INIT_DATA_.MIDDLE_Y,
		text 	= 'Total Memory'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _G_INIT_DATA_.MIDDLE_Y,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.BLUE,
		text		= Util.precision_convert_bytes(
		                Util.read_file('/proc/meminfo', 'MemTotal:%s+(%d+)'),
		                'KiB', 'GiB', 4)..' GiB'
	}
}

local _SEP_Y_ = _G_INIT_DATA_.MIDDLE_Y + _SEPARATOR_SPACING_

local separator = _G_Widget_.Line{
	p1 = {x = _G_INIT_DATA_.RIGHT_X, y = _SEP_Y_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_}
}

local _LINE_2_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local used_memory = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _LINE_2_Y_,
		text 	= 'Used Memory',
	},
	value = _G_Widget_.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _LINE_2_Y_,
		x_align 	= 'right',
		text_color	= _G_Patterns_.BLUE,
		append_end	= '%'
	}	
}

local _PLOT_Y_ = _LINE_2_Y_ + _PLOT_SECTION_BREAK_

local plot = _G_Widget_.LabelPlot{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _PLOT_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	height = _PLOT_HEIGHT_
}

local tbl = _G_Widget_.Table{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	height = _TABLE_HEIGHT_,
	num_rows=3,
	'Name',
	'PID',
	'Mem (%)'
}

local update = function(cr)
	local used_percent = Util.conky_numeric('${memperc}')

	CriticalText.set(used_memory.value, cr, used_percent)

	LabelPlot.update(plot, used_percent * 0.01)

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
	
	Text.draw(total_memory.label, cr)
	Text.draw(total_memory.value, cr)

	Line.draw(separator, cr)

	Text.draw(used_memory.label, cr)
	CriticalText.draw(used_memory.value, cr)

	LabelPlot.draw(plot, cr)

	Table.draw(tbl, cr)
end

return draw
