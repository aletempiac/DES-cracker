------------------------------------------------------------
-- Author       :   Pietro Mambelli
-- File         :   dht11_ctrl_axi_wrapper.vhd
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
    k_out  : out w48
  );
end entity key_round;

architecture rtl of key_round is

  signal pc2_local : w56;

begin

  

end rtl;
