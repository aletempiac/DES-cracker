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

    --component instantiation
    entity f_wrapper is
        port(   l       : in w32;
                r       : in w32;
                k       : in w48;
                newr    : out w32
            );


    --signals declarations
    signal lr_0, lr_16 : w64;

    type lr_type is array(0 to 16) of w32;
    signal l_local, r_local : lr_type;

begin

    --initial permutation of  p_in
	lr_0 <= ip(p_in);
    l_local(0) <= lr0(1 to 32);
    r_local(0) <= lr0(33 to 64);

    --start of the enciphering process
    enc_gen: for i in 1 to 16 generate
        l_local(i) <= r_local(i-1);
        f_wrapper_i : f_wrapper port map (l_local(i-1), r_local(i-1), k(i), r_local(i));
    end generate;

    lr_16 <= r_local(16)&l_local(16);

    --end permutation
    p_out <= fp(lr_16);

end architecture rtl;

