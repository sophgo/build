int cvi_board_init(void)
{
#if 0 /* pinmux set in alios */
	PINMUX_CONFIG(CAM_MCLK0, CAM_MCLK0);

	PINMUX_CONFIG(IIC2_SCL, IIC2_SCL);
	PINMUX_CONFIG(IIC2_SDA, IIC2_SDA);

	PINMUX_CONFIG(IIC3_SCL, IIC3_SCL);
	PINMUX_CONFIG(IIC3_SDA, IIC3_SDA);
#endif
	//enable pwm
	mmio_setbits_32(0x030002d0, 1 << 9);
	return 0;
}
