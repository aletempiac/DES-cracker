------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   key_round.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity key_round is
  port(
    c_in   : in w28;
    d_in   : in w28;
    shift_amount  : in natural;
    c_out  : out w28;
    d_out  : out w28;
    k_out  : out w48
  );
end entity key_round;

architecture rtl of key_round is

  signal pc2_local : w56;
  signal c_local, d_local : w28;

begin

  c_local <= left_shift(c_in, shift_amount);
  d_local <= left_shift(d_in, shift_amount);
  pc2_local <= c_local & d_local;

  k_out <= pc2(pc2pc2_local);
  c_out <= c_local;
  d_out <= d_local;

end rtl;
