local Text		= require 'Text'
local ScalePlot = require 'ScalePlot'
local Util		= require 'Util'

local __string_gmatch = string.gmatch
local __io_popen		= io.popen

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
	local new_unit = Util.get_unit_base_K(bytes)
	
	local converted = Util.convert_bytes(bytes, 'KiB', new_unit)
	local precision = (converted < 10) and 1 or 0
	
	return Util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local RIGHT_X = MODULE_X + PLOT_WIDTH
local PLOT_Y = MODULE_Y + PLOT_SEC_BREAK

local dnload = {
	label = _G_Widget_.Text{
		x = MODULE_X,
		y = MODULE_Y,
		text = 'Download',
	},
	speed = _G_Widget_.Text{
		x = RIGHT_X,
		y = MODULE_Y,
		x_align = 'right',
		append_end=' KiB/s',
		text_color = _G_Patterns_.BLUE
	},
	plot = _G_Widget_.ScalePlot{
		x = MODULE_X,
		y = PLOT_Y,
		width = PLOT_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __network_label_function
	}
}

local UPLOAD_X = RIGHT_X + PLOT_SPACING

local upload = {
	label = _G_Widget_.Text{
		x = UPLOAD_X,
		y = MODULE_Y,
		text = 'Upload',
	},
	speed = _G_Widget_.Text{
		x = UPLOAD_X + PLOT_WIDTH,
		y = MODULE_Y,
		x_align = 'right',
		append_end=' KiB/s',
		text_color = _G_Patterns_.BLUE
	},
	plot = _G_Widget_.ScalePlot{
		x = UPLOAD_X,
		y = PLOT_Y,
		width = PLOT_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __network_label_function
	}
}

local interfaces = {}

local add_interface = function(iface)
	local rx_path = SYSFS_NET..iface..STATS_RX
	local tx_path = SYSFS_NET..iface..STATS_TX

	interfaces[iface] = {
		rx_path = rx_path,
		tx_path = tx_path,
		rx_cumulative_bytes = 0,
		tx_cumulative_bytes = 0,
		prev_rx_cumulative_bytes = Util.read_file(rx_path, nil, '*n'),
		prev_tx_cumulative_bytes = Util.read_file(tx_path, nil, '*n'),
	}
end

for iface in __io_popen('ls -1 '..SYSFS_NET):lines() do
	add_interface(iface)
end

local update = function(cr, update_frequency)
	local dspeed, uspeed = 0, 0
	local glob = Util.execute_cmd('ip route show')

	local rx_bps, tx_bps

	for iface in __string_gmatch(glob, 'default via %d+%.%d+%.%d+%.%d+ dev (%w+) ') do
		local current_iface = interfaces[iface]

		if not current_iface then
			add_interface(iface)
			current_iface = interfaces[iface]
		end
		
		local new_rx_cumulative_bytes = Util.read_file(current_iface.rx_path, nil, '*n')
		local new_tx_cumulative_bytes = Util.read_file(current_iface.tx_path, nil, '*n')
		
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

	local dspeed_unit = Util.get_unit(dspeed)
	local uspeed_unit = Util.get_unit(uspeed)
	
	dnload.speed.append_end = ' '..dspeed_unit..'/s'
	upload.speed.append_end = ' '..uspeed_unit..'/s'
	
	Text.set(dnload.speed, cr, Util.precision_convert_bytes(dspeed, 'B', dspeed_unit, 3))
	Text.set(upload.speed, cr, Util.precision_convert_bytes(uspeed, 'B', uspeed_unit, 3))
	
	ScalePlot.update(dnload.plot, cr, dspeed)
	ScalePlot.update(upload.plot, cr, uspeed)
end

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
	update(cr, update_frequency)
	Text.draw(dnload.label, cr)
	Text.draw(dnload.speed, cr)
	ScalePlot.draw(dnload.plot, cr)
	
	Text.draw(upload.label, cr)
	Text.draw(upload.speed, cr)
	ScalePlot.draw(upload.plot, cr)
end

return draw
