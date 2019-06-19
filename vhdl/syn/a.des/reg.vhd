------------------------------------------------------------
-- Author       :   Pietro Mambelli & Alessandro Tempia Calvino
-- File         :   reg.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity reg is
	generic(n : positive);
	port(   clk     : in std_ulogic;
            sresetn : in std_ulogic;
		    d       : in std_ulogic_vector(n-1 downto 0);
		    q       : out std_ulogic_vector(n-1 downto 0)
	    );
end entity reg;

architecture rtl of reg is

begin

    process(clk)
    begin
        if (clk='1' and clk'event) then
            if sresetn='0' then
                q <= (others => '0');
            else
                q <= d;
            end if;
      end if;
	end process;

end architecture rtl;
