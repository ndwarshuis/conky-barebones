local Arc			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __string_match = string.match
local __math_rad		= math.rad

local __cairo_path_destroy = cairo_path_destroy

local MEM_TOTAL = Util.read_file('/proc/meminfo', 'MemTotal:%s+(%d+)') 	--in kB

local DIAL_RADIUS = 30
local DIAL_THETA0 = 90
local DIAL_THETA1 = 360

local TABLE_CONKY = {}
for c = 1, 3 do TABLE_CONKY[c] = {} end
for r = 1, 3 do TABLE_CONKY[1][r] = '${top_mem name '..r..'}' end
for r = 1, 3 do TABLE_CONKY[2][r] = '${top_mem pid '..r..'}' end
for r = 1, 3 do TABLE_CONKY[3][r] = '${top_mem mem '..r..'}' end

--contruction param
local DIAL_THICKNESS = 5
local DIAL_SPACING = 1
local TEXT_Y_OFFSET = 10
local TEXT_LEFT_X_OFFSET = 30
local TEXT_SPACING = 18
local SEPARATOR_SPACING = 15
local PLOT_SECTION_BREAK = 16
local PLOT_HEIGHT = 56
local TABLE_SECTION_BREAK = 16
local TABLE_HEIGHT = 80

local MODULE_X = _G_INIT_DATA_.RIGHT_X
local MODULE_Y = _G_INIT_DATA_.MIDDLE_Y
local MODULE_WIDTH = _G_INIT_DATA_.SECTION_WIDTH
local DIAL_REAL_RADIUS = DIAL_RADIUS + DIAL_THICKNESS * 0.5

--don't nil these
local DIAL_X = MODULE_X + DIAL_REAL_RADIUS
local DIAL_Y = MODULE_Y + DIAL_REAL_RADIUS

local dial = _G_Widget_.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= DIAL_THICKNESS,
	critical_limit 	= '>0.8'
}
local cache_arc = _G_Widget_.Arc{
	x 			= DIAL_X,
	y 			= DIAL_Y,			
	radius 		= DIAL_RADIUS,
	thickness 	= DIAL_THICKNESS,
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
	radius 	= DIAL_RADIUS - DIAL_THICKNESS / 2 - 2,
	theta0	= 0,
	theta1	= 360
}

local LINE_1_Y = MODULE_Y + TEXT_Y_OFFSET
local TEXT_LEFT_X = MODULE_X + DIAL_REAL_RADIUS * 2 + TEXT_LEFT_X_OFFSET
local RIGHT_X = MODULE_X + MODULE_WIDTH

local total = {
	label = _G_Widget_.Text{
		x 		= TEXT_LEFT_X,
		y 		= LINE_1_Y,
		text 	= 'Total',
	},
	amount = _G_Widget_.Text{
		x 			= RIGHT_X,
		y 			= LINE_1_Y,
		x_align 	= 'right',
		text_color	= _G_Patterns_.BLUE,
		text		= Util.precision_convert_bytes(MEM_TOTAL, 'KiB', 'GiB', 4)..' GiB'
	}	
}

local SEP_Y = LINE_1_Y + SEPARATOR_SPACING

local separator = _G_Widget_.Line{
	p1 = {x = TEXT_LEFT_X, y = SEP_Y},
	p2 = {x = RIGHT_X, y = SEP_Y}
}

local CACHE_BUFF_Y = SEP_Y + SEPARATOR_SPACING

local cache_buff = {
	labels = _G_Widget_.TextColumn{
		x 		= TEXT_LEFT_X,
		y 		= CACHE_BUFF_Y,
		spacing = TEXT_SPACING,
		'Cached',
		'Buffered'
	},
	percents = _G_Widget_.TextColumn{
		x 			= RIGHT_X,
		y 			= CACHE_BUFF_Y,
		spacing 	= TEXT_SPACING,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		append_end 	= ' %',
		'<cached>',
		'<buff>'
	}
}

local PLOT_Y = MODULE_Y + PLOT_SECTION_BREAK + DIAL_REAL_RADIUS * 2

local plot = _G_Widget_.LabelPlot{
	x = MODULE_X,
	y = PLOT_Y,
	width = MODULE_WIDTH,
	height = PLOT_HEIGHT
}

local tbl = _G_Widget_.Table{
	x = MODULE_X,
	y = PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK,
	width = MODULE_WIDTH,
	height = TABLE_HEIGHT,
	num_rows=3,
	'Name',
	'PID',
	'Mem (%)'
}

DIAL_THETA0 = __math_rad(DIAL_THETA0)
DIAL_THETA1 = __math_rad(DIAL_THETA1)

local update = function(cr)
	local MEM_TOTAL = MEM_TOTAL

	local round = Util.round
	local precision_round_to_string = Util.precision_round_to_string
	local glob = Util.read_file('/proc/meminfo')	--kB

	--see source for "free" for formulas and stuff ;)

	local page_cached 	= __string_match(glob, 'Cached:%s+(%d+)%s'   )
	local slab 			= __string_match(glob, 'Slab:%s+(%d+)%s'   )
	local buffers 		= __string_match(glob, 'Buffers:%s+(%d+)%s'  )
	local free 			= __string_match(glob, 'MemFree:%s+(%d+)%s'  )

	local cached = page_cached + buffers

	local used_percent = Util.round((MEM_TOTAL - free - cached - slab) / MEM_TOTAL, 2)

	Dial.set(dial, used_percent)
	CriticalText.set(total_used, cr, used_percent * 100)

	local cache_theta = (DIAL_THETA0 - DIAL_THETA1) / MEM_TOTAL * free + DIAL_THETA1
	__cairo_path_destroy(cache_arc.path)
	cache_arc.path = Arc.create_path(cr, DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)
	
	local percents = cache_buff.percents
	TextColumn.set(percents, cr, 1, precision_round_to_string(cached / MEM_TOTAL * 100))
	TextColumn.set(percents, cr, 2, precision_round_to_string(buffers / MEM_TOTAL * 100))

	LabelPlot.update(plot, used_percent)

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
DIAL_THICKNESS = nil
DIAL_SPACING = nil
TEXT_Y_OFFSET = nil
TEXT_LEFT_X_OFFSET = nil
TEXT_SPACING = nil
SEPARATOR_SPACING = nil
PLOT_SECTION_BREAK = nil
PLOT_HEIGHT = nil
TABLE_SECTION_BREAK = nil
TABLE_HEIGHT = nil
LINE_1_Y = nil
TEXT_LEFT_X = nil
RIGHT_X = nil
SEP_Y = nil
CACHE_BUFF_Y = nil
PLOT_Y = nil
DIAL_REAL_RADIUS = nil

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
