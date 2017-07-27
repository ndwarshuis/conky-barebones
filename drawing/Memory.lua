local Arc			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __string_match 	= string.match

local __cairo_path_destroy = cairo_path_destroy

local _DIAL_THICKNESS_ = 5
local _TEXT_Y_OFFSET_ = 10
local _TEXT_LEFT_X_OFFSET_ = 30
local _TEXT_SPACING_ = 18
local _SEPARATOR_SPACING_ = 15
local _PLOT_SECTION_BREAK_ = 20
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 16
local _TABLE_HEIGHT_ = 80

local MEM_TOTAL_KB = Util.read_file('/proc/meminfo', 'MemTotal:%s+(%d+)') 	--in kB
local NUM_ROWS = 3

local TABLE_CONKY = {{}, {}, {}}

for r = 1, NUM_ROWS do
	TABLE_CONKY[1][r] = '${top_mem name '..r..'}'
	TABLE_CONKY[2][r] = '${top_mem pid '..r..'}'
	TABLE_CONKY[3][r] = '${top_mem mem '..r..'}'
end

local DIAL_RADIUS = 30
local DIAL_THETA0 = math.rad(90)
local DIAL_THETA1 = math.rad(360)
local DIAL_X = _G_INIT_DATA_.RIGHT_X + DIAL_RADIUS + _DIAL_THICKNESS_ * 0.5
local DIAL_Y = _G_INIT_DATA_.MIDDLE_Y + DIAL_RADIUS + _DIAL_THICKNESS_ * 0.5

local dial = _G_Widget_.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= _DIAL_THICKNESS_,
	critical_limit 	= '>0.8'
}
local cache_arc = _G_Widget_.Arc{
	x 			= DIAL_X,
	y 			= DIAL_Y,			
	radius 		= DIAL_RADIUS,
	thickness 	= _DIAL_THICKNESS_,
	arc_pattern	= _G_Patterns_.PURPLE_ROUNDED
}
local total_used = _G_Widget_.CriticalText{
	x 			= DIAL_X,
	y 			= DIAL_Y,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%',
}
local inner_ring = _G_Widget_.Arc{
	x 		= DIAL_X,
	y 		= DIAL_Y,
	radius 	= DIAL_RADIUS - _DIAL_THICKNESS_ / 2 - 2,
	theta0	= 0,
	theta1	= 360
}

local _LINE_1_Y_ = _G_INIT_DATA_.MIDDLE_Y + _TEXT_Y_OFFSET_
local _TEXT_LEFT_X_ = _G_INIT_DATA_.RIGHT_X + DIAL_RADIUS * 2 + _TEXT_LEFT_X_OFFSET_
local _RIGHT_X_ = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local total = {
	label = _G_Widget_.Text{
		x 		= _TEXT_LEFT_X_,
		y 		= _LINE_1_Y_,
		text 	= 'Total',
	},
	amount = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _LINE_1_Y_,
		x_align 	= 'right',
		text_color	= _G_Patterns_.BLUE,
		text		= Util.precision_convert_bytes(MEM_TOTAL_KB, 'KiB', 'GiB', 4)..' GiB'
	}	
}

local _SEP_Y_ = _LINE_1_Y_ + _SEPARATOR_SPACING_

local separator = _G_Widget_.Line{
	p1 = {x = _TEXT_LEFT_X_, y = _SEP_Y_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_}
}

local _CACHE_BUFF_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local cache_buff = {
	labels = _G_Widget_.TextColumn{
		x 		= _TEXT_LEFT_X_,
		y 		= _CACHE_BUFF_Y_,
		spacing = _TEXT_SPACING_,
		'Cached',
		'Buffered'
	},
	percents = _G_Widget_.TextColumn{
		x 			= _RIGHT_X_,
		y 			= _CACHE_BUFF_Y_,
		spacing 	= _TEXT_SPACING_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		append_end 	= ' %',
		'<cached>',
		'<buff>'
	}
}

local _PLOT_Y_ = _G_INIT_DATA_.MIDDLE_Y + _PLOT_SECTION_BREAK_ + DIAL_RADIUS * 2 + _DIAL_THICKNESS_

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
	local glob = Util.read_file('/proc/meminfo')	--kB

	--see source for "free" for formulas and stuff ;)

	local page_cached 	= __string_match(glob, 'Cached:%s+(%d+)%s'   )
	local slab 			= __string_match(glob, 'Slab:%s+(%d+)%s'   )
	local buffers 		= __string_match(glob, 'Buffers:%s+(%d+)%s'  )
	local free 			= __string_match(glob, 'MemFree:%s+(%d+)%s'  )

	local cached = page_cached + buffers

	local used_percent = Util.round((MEM_TOTAL_KB - free - cached - slab) / MEM_TOTAL_KB, 2)

	Dial.set(dial, used_percent)
	CriticalText.set(total_used, cr, used_percent * 100)

	local cache_theta = (DIAL_THETA0 - DIAL_THETA1) / MEM_TOTAL_KB * free + DIAL_THETA1
	__cairo_path_destroy(cache_arc.path)
	cache_arc.path = Arc.create_path(cr, DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)
	
	local percents = cache_buff.percents
	TextColumn.set(percents, cr, 1, Util.precision_round_to_string(cached / MEM_TOTAL_KB * 100))
	TextColumn.set(percents, cr, 2, Util.precision_round_to_string(buffers / MEM_TOTAL_KB * 100))

	LabelPlot.update(plot, used_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, NUM_ROWS do
			Table.set(tbl, cr, c, r, Util.conky(column[r], '(%S+)'))
		end
	end
end

_DIAL_THICKNESS_ = nil
_TEXT_Y_OFFSET_ = nil
_TEXT_LEFT_X_OFFSET_ = nil
_TEXT_SPACING_ = nil
_SEPARATOR_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_LINE_1_Y_ = nil
_TEXT_LEFT_X_ = nil
_RIGHT_X_ = nil
_SEP_Y_ = nil
_CACHE_BUFF_Y_ = nil
_PLOT_Y_ = nil

local draw = function(cr)
	update(cr)
	Dial.draw(dial, cr)
	Arc.draw(cache_arc, cr)
	Arc.draw(inner_ring, cr)
	CriticalText.draw(total_used, cr)

	Text.draw(total.label, cr)
	Text.draw(total.amount, cr)

	Line.draw(separator, cr)

	TextColumn.draw(cache_buff.labels, cr)
	TextColumn.draw(cache_buff.percents, cr)

	LabelPlot.draw(plot, cr)

	Table.draw(tbl, cr)
end

return draw
