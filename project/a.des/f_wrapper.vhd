------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   f_wrapper.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

--this block wraps the cipher_f with the xor operation
entity f_wrapper is
    port(   l       : in w32;
            r       : in w32;
            k       : in w48;
            newr    : out w32
    );
end entity f_wrapper;


architecture rtl of f_wrapper is

    component cipher_f
        port(   r   : in w32;
                k   : in w48;
                f_out : out w32;
        );
    end component cipher_f;

    signal f_local : w32;
begin

	cipher_f_0: cipher_f port map(r, k, f_local);

    newr <= l xor f_local;

end architecture rtl;

