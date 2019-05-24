------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   des_cracker.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity des_cracker is
    generic(frequency_mhz   : positive := 100;
            start_us        : positive := 20000;
            warm_us         : positive := 1000000);

    port(   aclk             : in std_ulogic;
            aresetn          : in std_ulogic; -- synch active low, a means AXI
            s0_axi_araddr    : in std_ulogic_vector(11 downto 0);
            s0_axi_arvalid   : in std_ulogic;
            s0_axi_arready    : out std_ulogic;
            s0_axi_awaddr     : in std_ulogic_vector(11 downto 0);
            s0_axi_awvalid    : in std_ulogic;
            s0_axi_awready    : out std_ulogic;
            s0_axi_wdata      : in std_ulogic_vector(31 downto 0);
            s0_axi_wstrb      : in std_ulogic_vector(3 downto 0);
            s0_axi_wvalid     : in std_ulogic;
            s0_axi_wready     : out std_ulogic;
            s0_axi_rdata      : out std_ulogic_vector(31 downto 0);
            s0_axi_rresp      : out std_ulogic_vector(1 downto 0);
            s0_axi_rvalid     : out std_ulogic;
            s0_axi_rready     : in std_ulogic;
            s0_axi_bresp      : out std_ulogic_vector(1 downto 0);
            s0_axi_bvalid     : out std_ulogic;
            s0_axi_bready     : in std_ulogic;
            irq               : out std_logic;
            led               : out std_ulogic_vector(3 downto 0)
    );

end entity des_cracker;

architecture rtl of des_cracker is

  signal p    : std_ulogic_vector(63 downto 0);
  signal c    : std_ulogic_vector(63 downto 0);
  signal k0   : std_ulogic_vector(55 downto 0);
  signal k    : std_ulogic_vector(55 downto 0);
  signal k1   : std_ulogic_vector(55 downto 0);



end architecture rtl;
