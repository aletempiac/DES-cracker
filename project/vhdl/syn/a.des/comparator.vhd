------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   comparator.vhd
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity comparator is
    generic(N   : positive := 16);
    port(   a   : in std_ulogic_vector(N-1 downto 0);
            b   : in std_ulogic_vector(N-1 downto 0);
            eq  : out std_ulogic
    );
end entity comparator;


architecture rtl of comparator is

begin

    eq <= '1' when (a=b) else '0';

end architecture rtl;

