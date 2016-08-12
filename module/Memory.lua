local Widget		= require 'Widget'
local Arc			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local util			= require 'util'
local schema		= require 'default_patterns'

local _STRING_MATCH = string.match
local _MATH_RAD		= math.rad

local _CAIRO_PATH_DESTROY = cairo_path_destroy

local MEM_TOTAL = util.read_file('/proc/meminfo', 'MemTotal:%s+(%d+)') 	--in kB

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

local MODULE_X = CONSTRUCTION_GLOBAL.RIGHT_X
local MODULE_Y = CONSTRUCTION_GLOBAL.MIDDLE_Y
local MODULE_WIDTH = CONSTRUCTION_GLOBAL.SECTION_WIDTH
local DIAL_REAL_RADIUS = DIAL_RADIUS + DIAL_THICKNESS * 0.5

--don't nil these
local DIAL_X = MODULE_X + DIAL_REAL_RADIUS
local DIAL_Y = MODULE_Y + DIAL_REAL_RADIUS

local dial = Widget.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= DIAL_THICKNESS,
	critical_limit 	= '>0.8'
}
local cache_arc = Widget.Arc{
	x 			= DIAL_X,
	y 			= DIAL_Y,			
	radius 		= DIAL_RADIUS,
	thickness 	= DIAL_THICKNESS,
	arc_pattern	= schema.purple_rounded
}
local total_used = Widget.CriticalText{
	x 			= DIAL_X,
	y 			= DIAL_Y,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%',
}
local inner_ring = Widget.Arc{
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
	label = Widget.Text{
		x 		= TEXT_LEFT_X,
		y 		= LINE_1_Y,
		text 	= 'Total',
	},
	amount = Widget.Text{
		x 			= RIGHT_X,
		y 			= LINE_1_Y,
		x_align 	= 'right',
		text_color	= schema.blue,
		text		= util.precision_convert_bytes(MEM_TOTAL, 'KiB', 'GiB', 4)..' GiB'
	}	
}

local SEP_Y = LINE_1_Y + SEPARATOR_SPACING

local separator = Widget.Line{
	p1 = {x = TEXT_LEFT_X, y = SEP_Y},
	p2 = {x = RIGHT_X, y = SEP_Y}
}

local CACHE_BUFF_Y = SEP_Y + SEPARATOR_SPACING

local cache_buff = {
	labels = Widget.TextColumn{
		x 		= TEXT_LEFT_X,
		y 		= CACHE_BUFF_Y,
		spacing = TEXT_SPACING,
		'Cached',
		'Buffered'
	},
	percents = Widget.TextColumn{
		x 			= RIGHT_X,
		y 			= CACHE_BUFF_Y,
		spacing 	= TEXT_SPACING,
		x_align 	= 'right',
		text_color 	= schema.purple,
		append_end 	= ' %',
		'<cached>',
		'<buff>'
	}
}

local PLOT_Y = MODULE_Y + PLOT_SECTION_BREAK + DIAL_REAL_RADIUS * 2

local plot = Widget.LabelPlot{
	x = MODULE_X,
	y = PLOT_Y,
	width = MODULE_WIDTH,
	height = PLOT_HEIGHT
}

local tbl = Widget.Table{
	x = MODULE_X,
	y = PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK,
	width = MODULE_WIDTH,
	height = TABLE_HEIGHT,
	num_rows=3,
	'Name',
	'PID',
	'Mem (%)'
}

DIAL_THETA0 = _MATH_RAD(DIAL_THETA0)
DIAL_THETA1 = _MATH_RAD(DIAL_THETA1)

local __update = function(cr)
	local MEM_TOTAL = MEM_TOTAL

	local round = util.round
	local precision_round_to_string = util.precision_round_to_string
	local glob = util.read_file('/proc/meminfo')	--kB

	--see source for "free" for formulas and stuff ;)

	local page_cached 	= _STRING_MATCH(glob, 'Cached:%s+(%d+)%s'   )
	local slab 			= _STRING_MATCH(glob, 'Slab:%s+(%d+)%s'   )
	local buffers 		= _STRING_MATCH(glob, 'Buffers:%s+(%d+)%s'  )
	local free 			= _STRING_MATCH(glob, 'MemFree:%s+(%d+)%s'  )

	local cached = page_cached + buffers

	local used_percent = util.round((MEM_TOTAL - free - cached - slab) / MEM_TOTAL, 2)

	Dial.set(dial, used_percent)
	CriticalText.set(total_used, cr, used_percent * 100)

	local cache_theta = (DIAL_THETA0 - DIAL_THETA1) / MEM_TOTAL * free + DIAL_THETA1
	_CAIRO_PATH_DESTROY(cache_arc.path)
	cache_arc.path = Arc.create_path(DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)
	
	local percents = cache_buff.percents
	TextColumn.set(percents, cr, 1, precision_round_to_string(cached / MEM_TOTAL * 100))
	TextColumn.set(percents, cr, 2, precision_round_to_string(buffers / MEM_TOTAL * 100))

	LabelPlot.update(plot, used_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, 3 do
			Table.set(tbl, cr, c, r, util.conky(column[r], '(%S+)'))
		end
	end
end

Widget = nil
schema = nil
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
	__update(cr)
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
