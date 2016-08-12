local Widget	= require 'Widget'
local Text		= require 'Text'
local ScalePlot = require 'ScalePlot'
local util		= require 'util'
local schema	= require 'default_patterns'

local _STRING_GMATCH = string.gmatch
local _IO_POPEN		= io.popen

--construction params
local MODULE_X = 30
local MODULE_Y = 34

local PLOT_SEC_BREAK = 20
local PLOT_HEIGHT = 56
local PLOT_WIDTH = 300
local PLOT_SPACING = 30

local SYSFS_NET = '/sys/class/net/'
local STATS_RX = '/statistics/rx_bytes'
local STATS_TX = '/statistics/tx_bytes'

local __network_label_function = function(bytes)
	local new_unit = util.get_unit_base_K(bytes)
	
	local converted = util.convert_bytes(bytes, 'KiB', new_unit)
	local precision = (converted < 10) and 1 or 0
	
	return util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local RIGHT_X = MODULE_X + PLOT_WIDTH
local PLOT_Y = MODULE_Y + PLOT_SEC_BREAK

local dnload = {
	label = Widget.Text{
		x = MODULE_X,
		y = MODULE_Y,
		text = 'Download',
	},
	speed = Widget.Text{
		x = RIGHT_X,
		y = MODULE_Y,
		x_align = 'right',
		append_end=' KiB/s',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = MODULE_X,
		y = PLOT_Y,
		width = PLOT_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __network_label_function
	}
}

local UPLOAD_X = RIGHT_X + PLOT_SPACING

local upload = {
	label = Widget.Text{
		x = UPLOAD_X,
		y = MODULE_Y,
		text = 'Upload',
	},
	speed = Widget.Text{
		x = UPLOAD_X + PLOT_WIDTH,
		y = MODULE_Y,
		x_align = 'right',
		append_end=' KiB/s',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = UPLOAD_X,
		y = PLOT_Y,
		width = PLOT_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __network_label_function
	}
}

local interfaces = {}

local __add_interface = function(iface)
	local rx_path = SYSFS_NET..iface..STATS_RX
	local tx_path = SYSFS_NET..iface..STATS_TX

	interfaces[iface] = {
		rx_path = rx_path,
		tx_path = tx_path,
		rx_cumulative_bytes = 0,
		tx_cumulative_bytes = 0,
		prev_rx_cumulative_bytes = util.read_file(rx_path, nil, '*n'),
		prev_tx_cumulative_bytes = util.read_file(tx_path, nil, '*n'),
	}
end

for iface in _IO_POPEN('ls -1 '..SYSFS_NET):lines() do
	__add_interface(iface)
end

local __update = function(cr, update_frequency)
	local dspeed, uspeed = 0, 0
	local glob = util.execute_cmd('ip route show')

	local rx_bps, tx_bps

	for iface in _STRING_GMATCH(glob, 'default via %d+%.%d+%.%d+%.%d+ dev (%w+) ') do
		local current_iface = interfaces[iface]

		if not current_iface then
			__add_interface(iface)
			current_iface = interfaces[iface]
		end
		
		local new_rx_cumulative_bytes = util.read_file(current_iface.rx_path, nil, '*n')
		local new_tx_cumulative_bytes = util.read_file(current_iface.tx_path, nil, '*n')
		
		rx_bps = (new_rx_cumulative_bytes - current_iface.prev_rx_cumulative_bytes) * update_frequency
		tx_bps = (new_tx_cumulative_bytes - current_iface.prev_tx_cumulative_bytes) * update_frequency

		current_iface.prev_rx_cumulative_bytes = new_rx_cumulative_bytes
		current_iface.prev_tx_cumulative_bytes = new_tx_cumulative_bytes

		--mask overflow
		if rx_bps < 0 then rx_bps = 0 end
		if tx_bps < 0 then tx_bps = 0 end

		dspeed = dspeed + rx_bps
		uspeed = uspeed + tx_bps
	end

	local dspeed_unit = util.get_unit(dspeed)
	local uspeed_unit = util.get_unit(uspeed)
	
	dnload.speed.append_end = ' '..dspeed_unit..'/s'
	upload.speed.append_end = ' '..uspeed_unit..'/s'
	
	Text.set(dnload.speed, cr, util.precision_convert_bytes(dspeed, 'B', dspeed_unit, 3))
	Text.set(upload.speed, cr, util.precision_convert_bytes(uspeed, 'B', uspeed_unit, 3))
	
	ScalePlot.update(dnload.plot, cr, dspeed)
	ScalePlot.update(upload.plot, cr, uspeed)
end

Widget = nil
schema = nil
MODULE_X = nil
MODULE_Y = nil
PLOT_SEC_BREAK = nil
PLOT_SPACING = nil
PLOT_HEIGHT = nil
SYSFS_NET = nil
STATS_RX = nil
STATS_TX = nil
RIGHT_X = nil
UPLOAD_X = nil
PLOT_Y = nil

local draw = function(cr, update_frequency)
	__update(cr, update_frequency)
	Text.draw(dnload.label, cr)
	Text.draw(dnload.speed, cr)
	ScalePlot.draw(dnload.plot, cr)
	
	Text.draw(upload.label, cr)
	Text.draw(upload.speed, cr)
	ScalePlot.draw(upload.plot, cr)
end

return draw
