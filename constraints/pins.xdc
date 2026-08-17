## Constraint defined on the output clock net of BUFG
create_clock -period 15.385 -name internal_clk [get_pins startup_inst/CFGMCLK]

## User LED (D1)
set_property -dict { PACKAGE_PIN E13 IOSTANDARD LVCMOS33 } [get_ports { led }]

## Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]
