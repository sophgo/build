int cvi_board_init(void)
{
	PINMUX_CONFIG(CAM_MCLK0, CAM_MCLK0);

	// PINMUX_CONFIG(IIC2_SCL, IIC2_SCL);
	// PINMUX_CONFIG(IIC2_SDA, IIC2_SDA);
	PINMUX_CONFIG(CAM_RST0, XGPIOA_2);

	PINMUX_CONFIG(IIC3_SCL, IIC3_SCL);
	PINMUX_CONFIG(IIC3_SDA, IIC3_SDA);

	return 0;
}
