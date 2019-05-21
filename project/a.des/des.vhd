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
    port(   clk     : in std_ulogic;
            sresetn : in std_ulogic;
            p_in    : in w64;       --input plaintext
            key     : in w64;       --key
            p_out   : out w64;      --output cyphered plaintext
            cd16     : out w56      --cd16 represents the permutated key
    );
end entity des;


architecture rtl of des is

    --component instantiation
    component f_wrapper
        port(   l       : in w32;
                r       : in w32;
                k       : in w48;
                newr    : out w32
            );
    end component;


    component key_gen
        port(   clk     : std_ulogic;
                sresetn : std_ulogic;
                key     : in w64;
                key_out : out key_array;
                cd16    : out w56
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


    --signals declarations
    signal lr_0, lr_16 : w64;

    type lr_type is array(0 to 16) of w32;
    signal l_local, r_local, l_local_s, r_local_s : lr_type;
    signal k : key_array;

begin

    --initial permutation of  p_in
	lr_0 <= ip(p_in);
    l_local_s(0) <= lr_0(1 to 32);
    r_local_s(0) <= lr_0(33 to 64);


    key_gen_0: key_gen port map (clk, sresetn, key, k, cd16);

    --start of the enciphering process
    enc_gen: for i in 1 to 16 generate
        l_local(i) <= r_local_s(i-1);
        f_wrapper_i : f_wrapper port map (l_local_s(i-1), r_local_s(i-1), k(i), r_local(i));
        reg_gen: if (i/=16) generate
            reg_l_i: reg generic map (32) port map (clk, sresetn, l_local(i), l_local_s(i));
            reg_r_i: reg generic map (32) port map (clk, sresetn, r_local(i), r_local_s(i));
        end generate;
    end generate;

    lr_16 <= r_local(16)&l_local(16);

    --end permutation
    p_out <= fp(lr_16);

end architecture rtl;

