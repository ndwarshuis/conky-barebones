local M = {}

local Color = require 'Color'
local Util 	= require 'Util'

local WHITE = 0xffffffff
	
local grey1 = 0xeeeeeeff
local grey2 = 0xbfbfbfff
local grey3 = 0xd6d6d6ff
local grey4 = 0x888888ff
local grey5 = 0x565656ff
local grey6 = 0x2f2f2fb2
local black = 0x000000ff

local blue1 = 0x99CEFFff
local blue2 = 0xBFE1FFff
local blue3 = 0x316BA6ff

local red1 = 0xFF3333ff
local red2 = 0xFF8282ff
local red3 = 0xFFB8B8ff

local purple1 = 0xeecfffff
local purple2 = 0xcb91ffff
local purple3 = 0x9523ffff

M.WHITE = Color.init{hex_rgba = WHITE}

M.LIGHT_GREY = Color.init{hex_rgba = grey1}
M.MID_GREY = Color.init{hex_rgba = grey3}
M.DARK_GREY = Color.init{hex_rgba = grey4}

M.BLUE = Color.init{hex_rgba = blue2}
M.RED = Color.init{hex_rgba = red2}
M.PURPLE = Color.init{hex_rgba = purple2}

M.GREY_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = grey5, stop = 0.0},
	Color.ColorStop{hex_rgba = grey2, stop = 0.5},
	Color.ColorStop{hex_rgba = grey5, stop = 1.0}	
}

M.BLUE_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = blue3, stop = 0.0},
	Color.ColorStop{hex_rgba = blue1, stop = 0.5},
	Color.ColorStop{hex_rgba = blue3, stop = 1.0}
}

M.RED_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = red1, stop = 0.0},
	Color.ColorStop{hex_rgba = red3, stop = 0.5},
	Color.ColorStop{hex_rgba = red1, stop = 1.0}
}

M.PURPLE_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = purple3, stop = 0.0},
	Color.ColorStop{hex_rgba = purple1, stop = 0.5},
	Color.ColorStop{hex_rgba = purple3, stop = 1.0}
}

M.TRANSPARENT_BLACK = Color.Gradient{
	Color.ColorStop{hex_rgba = grey6, stop = 0.0, force_alpha = 0.7},
	Color.ColorStop{hex_rgba = black, stop = 1.0, force_alpha = 0.7}
}

M.TRANSPARENT_BLUE = Color.Gradient{
	Color.ColorStop{hex_rgba = blue3, stop = 0.0, force_alpha = 0.2},
	Color.ColorStop{hex_rgba = blue1, stop = 1.0, force_alpha = 1.0}
}

M = Util.set_finalizer(M, function() print('Cleaning up Patterns.lua') end)

return M
