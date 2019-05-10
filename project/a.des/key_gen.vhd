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
  port (
    key   : in w64;
    key_out : out key_array
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


  signal pc1_local  : w56;
  signal c_local : cd_array;
  signal d_local : cd_array;

begin

  pc1_local <= pc1(key);
  c_local(0) <= pc1_local (1 to 28);
  d_local(0) <= pc1_local (29 to 56);

  gen_key_round: for i in 1 to 16 generate
    key_round_i: key_round port map(c_local(i-1), d_local(i-1), SHIFT_TABLE(i), c_local(i), d_local(i), key_out(i));
  end generate;


end rtl;
