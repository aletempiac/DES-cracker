------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   des_wrap.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.des_pkg.all;

entity des_wrap is
    port(   clk     : in std_ulogic;
            sresetn : in std_ulogic;
            p_in    : in w64;       --input plaintext
            key     : in w64;       --key
            index   : in natural range 0 to DES_NUMBER-1;
            p_out   : out w64       --output cyphered plaintext
    );
end entity des_wrap;


architecture rtl of des_wrap is

    component des
        port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
                p_in    : in w64;       --input plaintext
                key     : in w64;       --key
                p_out   : out w64       --output cyphered plaintext
        );
    end component;

    component reg
	    generic(n : positive);
	    port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
		        d       : in std_ulogic_vector(n-1 downto 0);
		        q       : out std_ulogic_vector(n-1 downto 0)
	        );
    end component;


    signal key_local    : w64;
    signal key_local_s  : w64;


begin

	key_local   <= key + index;

    reg_add: reg generic map (64) port map (clk, sresetn, key_local, key_local_s);

    des_0: des port map(clk     => clk,
                        sresetn => sresetn,
                        p_in    => p_in,
                        key     => key_local_s,
                        p_out   => p_out);

end architecture rtl;

