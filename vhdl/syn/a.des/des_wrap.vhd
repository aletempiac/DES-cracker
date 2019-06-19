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
            p_in    : in w64;                               --input plaintext
            key     : in w56;                               --key
            index   : in natural range 0 to DES_NUMBER-1;
            p_out   : out w64;                              --output cyphered plaintext
            cd16    : out w56                               --cd16 represents the permutated key
    );
end entity des_wrap;


architecture rtl of des_wrap is

    component des
        port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
                p_in    : in w64;       --input plaintext
                key     : in w64;       --key
                p_out   : out w64;      --output cyphered plaintext
                cd16    : out w56       --cd16 represents the permutated key
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


    signal key_local    : w56;
    signal key_64       : w64;
    signal key_local_s  : w64;
    -- signal index_unsigned : unsigned(3 downto 0);


begin

	key_local <= std_ulogic_vector(unsigned(key) + index);
    key_64 <= key_local(1 to 7) & '0' & key_local(8 to 14) & '0' & key_local(15 to 21) & '0' & key_local(22 to 28) & '0' & key_local(29 to 35) & '0' & key_local(36 to 42) & '0' & key_local(43 to 49) & '0' & key_local(50 to 56) & '0';

    reg_add: reg generic map (64) port map (clk, sresetn, key_64, key_local_s);

    des_0: des port map(clk     => clk,
                        sresetn => sresetn,
                        p_in    => p_in,
                        key     => key_local_s,
                        p_out   => p_out,
                        cd16    => cd16
                    );

end architecture rtl;
