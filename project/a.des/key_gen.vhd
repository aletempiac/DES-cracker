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
    shift_table  : in table(1 to 16);
    key_out : out key_array
  );
end entity key_gen;

architecture rtl of key_gen is

  signal pc1_local  : w56;
  signal c_local : cd_array;
  signal d_local : cd_array;

begin

  pc1_local <= pc1(key);
  c_local(0) <= pc1_local (1 to 28);
  d_local(0) <= pc1_local (29 to 56);

  gen_key_round: for i in 1 to 8 generate
    key_round_i: key_round port map(c_local(i-1), d_local(i-1), SHIFT_TABLE(i), c_local(i), d_local(i), k_out(i));
  end generate;


end rtl;
