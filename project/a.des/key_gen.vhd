------------------------------------------------------------
-- Author       :   Pietro Mambelli
-- File         :   dht11_ctrl_axi_wrapper.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity key_gen is
  port (
    key   : in w64;
    k1    : out w48;
    k2    : out w48;
    k3    : out w48;
    k4    : out w48;
    k5    : out w48;
    k6    : out w48;
    k7    : out w48;
    k8    : out w48;
    k9    : out w48;
    k10    : out w48;
    k11    : out w48;
    k12    : out w48;
    k13    : out w48;
    k14    : out w48;
    k15    : out w48;
    k16    : out w48
  );
end entity key_gen;

architecture rtl of key_gen is

  signal pc1_local  : w56;

end rtl;
