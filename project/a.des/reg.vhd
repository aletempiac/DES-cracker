------------------------------------------------------------
-- Author       :   Pietro Mambelli
-- File         :   dht11_ctrl_axi_wrapper.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity reg is
	generic (
    n : positive
  );
	port (
    clk    : in std_ulogic;
    reset  : in std_ulogic;
		d      : in std_ulogic_vector(n-1 downto 0);
		q      : out std_ulogic_vector(n-1 downto 0)
	);
end entity reg;

architecture rtl of reg is

  begin

  process(clk, reset)
    begin
      if reset='1' then
        q <= (others => '0');
			elsif clk'event and clk='1' then
        q <= d;
      end if;
	end process;

end architecture rtl;
