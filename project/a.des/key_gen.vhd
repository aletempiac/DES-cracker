------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   key_gen.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity key_gen is
    port(   clk     : std_ulogic;
            sresetn : std_ulogic;
            key     : in w64;
            key_out : out key_array;
            cd16    : out w56
        );
end entity key_gen;

architecture rtl of key_gen is

    component key_round
        port(   c_in   : in w28;
                d_in   : in w28;
                shift_amount  : in natural;
                c_out  : out w28;
                d_out  : out w28;
                k_out  : out w48
            );
    end component key_round;


    component reg
	    generic(n : positive);
	    port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
		        d       : in std_ulogic_vector(n-1 downto 0);
		        q       : out std_ulogic_vector(n-1 downto 0)
	        );
    end component;


    signal pc1_local  : w56;
    signal c_local, c_local_s : cd_array;
    signal d_local, d_local_s : cd_array;

begin

    pc1_local <= pc1(key);
    c_local_s(0) <= pc1_local (1 to 28);
    d_local_s(0) <= pc1_local (29 to 56);

    gen_key_round: for i in 1 to 16 generate
        key_round_i: key_round port map(c_local_s(i-1), d_local_s(i-1), SHIFT_TABLE(i), c_local(i), d_local(i), key_out(i));
        reg_gen: if (i/=16) generate
            reg_c_i: reg generic map (28) port map (clk, sresetn, c_local(i), c_local_s(i));
            reg_d_i: reg generic map (28) port map (clk, sresetn, d_local(i), d_local_s(i));
        end generate;
    end generate;

    cd16 <= c_local_s(15) & d_local_s(15);

end rtl;
