------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   des.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity des is
    generic();
    port(   clk     : in std_ulogic;
            sresetn : in std_ulogic;
            p_in    : in w64;       --input plaintext
            k       : in w64;       --key
            p_out   : out w64;      --output cyphered plaintext
    );
end entity des;


architecture rtl of des is

begin

	

end architecture rtl;

