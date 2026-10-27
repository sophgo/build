#force u_chip_top.chip_core.A_rtc_pr_wrap.A_rtc_pwr_wrap.u_rtc_sys.u_rtc.POR_CORE 1'b0
#force u_chip_top.chip_core.A_rtc_pr_wrap.A_rtc_pwr_wrap.u_rtc_sys.u_rtc.POR_CORE 1'b1
force rstn 1'b0
#force JTAG0_NSRST 1'b0
sleep 1
#force JTAG0_NSRST 1'b1
force rstn 1'b1
