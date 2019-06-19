------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   counter.vhd
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity counter is
    generic(cmax : natural);
    port(   clk         : in std_ulogic;
            sresetn     : in std_ulogic;
            cz          : in std_ulogic;
            inc         : in std_ulogic;
            end_count   : out std_ulogic
    );
end entity counter;


architecture rtl of counter is

    signal c_local : natural range 0 to cmax;

begin

    process(clk)
    begin
        if (clk='1' and clk'event) then
            if (sresetn='0') then
                c_local <= 0;
            elsif (cz='1') then
                c_local <= 0;
            elsif (c_local < cmax and inc='1') then
                c_local <= c_local+1;
            end if;
        end if;
    end process;

    end_count <= '1' when c_local = cmax else '0';

end architecture rtl;
