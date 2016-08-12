--CONVENTIONS:
--0: true, 1: false

local ABS_PATH = os.getenv('CONKY_LUA_HOME')

package.path = ABS_PATH..'/?.lua;'..
  ABS_PATH..'/module/?.lua;'..
  ABS_PATH..'/func/?.lua;'..
  ABS_PATH..'/super/?.lua;'..
  ABS_PATH..'/schema/?.lua;'..
  ABS_PATH..'/widget/?.lua;'..
  ABS_PATH..'/widget/arc/?.lua;'..
  ABS_PATH..'/widget/image/?.lua;'..
  ABS_PATH..'/widget/text/?.lua;'..
  ABS_PATH..'/widget/plot/?.lua;'..
  ABS_PATH..'/widget/rect/?.lua;'..
  ABS_PATH..'/widget/poly/?.lua;'

ABS_PATH = nil

local UPDATE_FREQUENCY = 1						--Hz

CONSTRUCTION_GLOBAL = {
	UPDATE_INTERVAL = 1 / UPDATE_FREQUENCY,
	WINDOW_WIDTH	= 700,
	WINDOW_HEIGHT	= 780,
	LEFT_X 			= 30,
	RIGHT_X 		= 360,
	TOP_Y			= 34,
	MIDDLE_Y		= 135,
	SECTION_WIDTH 	= 300,
}

conky_set_update_interval(CONSTRUCTION_GLOBAL.UPDATE_INTERVAL)

require 'cairo'

local Network 		= require 'Network'
local Processor 	= require 'Processor'
local Memory		= require 'Memory'


local updates = -2

local unrequire = function(m)
	package.loaded[m] = nil
	_G[m] = nil
end

unrequire('Gradient')

unrequire = nil

CONSTRUCTION_GLOBAL = nil

local _CAIRO_XLIB_SURFACE_CREATE 	= cairo_xlib_surface_create
local _CAIRO_CREATE 				= cairo_create
local _CAIRO_SURFACE_DESTROY 		= cairo_surface_destroy
local _CAIRO_DESTROY 				= cairo_destroy
local _COLLECTGARBAGE				= collectgarbage

function conky_main()
	local cw = conky_window
    if not cw then return end
    --~ print(cw.width, cw.height)	###USE THIS TO GET WIDTH AND HEIGHT OF WINDOW
    local cs = _CAIRO_XLIB_SURFACE_CREATE(cw.display, cw.drawable, cw.visual, 700, 778)
    local cr = _CAIRO_CREATE(cs)

	Network(cr, UPDATE_FREQUENCY)
	Processor(cr)
	Memory(cr)

    _CAIRO_SURFACE_DESTROY(cs)
    _CAIRO_DESTROY(cr)
    _COLLECTGARBAGE()
end
