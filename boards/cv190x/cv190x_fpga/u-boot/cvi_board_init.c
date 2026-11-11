int cvi_board_init(void)
{
	mmio_write_32(0x03000034, 0x8); //ETH_MAC0 PHY IF select 3'b001(RGMII), 3'b100(RMII)

	mmio_write_32(0x03001c08, 0x40); //RMII0_MDIO
	mmio_write_32(0x03001c0c, 0x40); //RMII0_RXD1
	mmio_write_32(0x03001c10, 0x40); //RMII0_REFCLKI
	mmio_write_32(0x03001c14, 0x40); //RMII0_RXD0
	mmio_write_32(0x03001c18, 0x40); // RMII0_MDC
	mmio_write_32(0x03001c1c, 0x40); //RMII0_TXD0
	mmio_write_32(0x03001c20, 0x40); //RMII0_TXD1
	mmio_write_32(0x03001c24, 0x40); //RMII0_RXDV
	mmio_write_32(0x03001c28, 0x40); //RMII0_TXCLK
	mmio_write_32(0x03001c2c, 0x40); //RMII0_TXEN

	//mmio_write_32(0x03001134, 0x4); // RMII_IRQ
	mmio_write_32(0x03001150, 0x4); //RMII0_MDC
	mmio_write_32(0x03001140, 0x4); //RMII0_MDIO
	mmio_write_32(0x03001148, 0x4); //RMII0_REFCLKI
	mmio_write_32(0x0300114c, 0x4); //RMII0_RXD0
	mmio_write_32(0x03001144, 0x4); //RMII0_RXD1
	mmio_write_32(0x03001160, 0x4); //RMII0_RXDV
	mmio_write_32(0x0300115c, 0x4); //RMII0_TXCLK
	mmio_write_32(0x03001154, 0x4); //RMII0_TXD0
	mmio_write_32(0x03001158, 0x4); //RMII0_TXD1
	mmio_write_32(0x03001164, 0x4); //RMII0_TXEN

	return 0;
}
