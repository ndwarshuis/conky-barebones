local UPDATE_FREQUENCY = 1						--Hz

_G_INIT_DATA_ = {
	UPDATE_INTERVAL = 1 / UPDATE_FREQUENCY,
	WINDOW_WIDTH	= 700,
	WINDOW_HEIGHT	= 780,
	LEFT_X 			= 30,
	RIGHT_X 		= 360,
	TOP_Y			= 34,
	MIDDLE_Y		= 135,
	SECTION_WIDTH 	= 300,

	ABS_PATH		= os.getenv('CONKY_LUA_HOME')
}

package.path = _G_INIT_DATA_.ABS_PATH..'/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/drawing/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/schema/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/func/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/super/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/arc/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/image/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/text/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/plot/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/rect/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'/core/widget/poly/?.lua;'

conky_set_update_interval(_G_INIT_DATA_.UPDATE_INTERVAL)

require 'cairo'

_G_Widget_ 		= require 'Widget'
_G_Patterns_ 	= require 'Patterns'

local Network 		= require 'Network'
local Processor 	= require 'Processor'
local Memory		= require 'Memory'

local _unrequire_ = function(m) package.loaded[m] = nil end

_G_Widget_ = nil
_G_Patterns_ = nil

_unrequire_('Super')
_unrequire_('Color')
_unrequire_('Gradient')
_unrequire_('Widget')
_unrequire_('Patterns')

_unrequire_ = nil

_G_INIT_DATA_ = nil

local __cairo_xlib_surface_create 	= cairo_xlib_surface_create
local __cairo_create 				= cairo_create
local __cairo_surface_destroy 		= cairo_surface_destroy
local __cairo_destroy 				= cairo_destroy
local __collectgarbage				= collectgarbage

function conky_main()
	local _cw = conky_window
    if not _cw then return end
    local cs = __cairo_xlib_surface_create(_cw.display, _cw.drawable, _cw.visual, 700, 778)
    local cr = __cairo_create(cs)
	
	Network(cr, UPDATE_FREQUENCY)
	
	Processor(cr)
	
	Memory(cr)
	
    __cairo_surface_destroy(cs)
    __cairo_destroy(cr)
    __collectgarbage()
end
