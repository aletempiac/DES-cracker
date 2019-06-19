------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   cipher_f.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity cipher_f is
    port(   r   : in w32;
            k   : in w48;
            f_out : out w32
    );
end entity cipher_f;


architecture rtl of cipher_f is

    component s_box
        port(   s_in    : in std_ulogic_vector(0 to 5);
                s_table : in s_matrix;
                s_out   : out std_ulogic_vector(0 to 3)
        );
    end component s_box;


    signal e_local : w48;
    signal x_local : w48;
    signal s_local : w32;

begin

	e_local <= e(r);            --e permutation
    x_local <= e_local xor k;

    gen_s_box: for i in 0 to 7 generate
        s_box_i: s_box port map(x_local(i*6+1 to i*6+6), S_BOXES(i), s_local(i*4+1 to i*4+4));
    end generate;

    f_out <= p(s_local);    --p permutation

end architecture rtl;
