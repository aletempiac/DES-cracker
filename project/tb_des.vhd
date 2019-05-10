------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   tb_des.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity tb_des is
end entity tb_des;


architecture rtl of tb_des is

    component des
        port(   --clk     : in std_ulogic;
            --sresetn : in std_ulogic;
            p_in    : in w64;       --input plaintext
            key     : in w64;       --key
            p_out   : out w64       --output cyphered plaintext
        );
    end component des;

    --signals
    signal p_in     : w64;
    signal key      : w64;
    signal p_out    : w64;

begin

    des_uut: des port map(p_in, key, p_out);

    stimulus: process
    begin
        key <= X"133457799BBCDFF1";
        p_in <= X"0123456789ABCDEF";
        wait for 20 ns;
        assert (p_out=X"85E813540F0AB405") report "first wrong";
        key <= X"0E329232EA6D0D73";
        p_in <= X"8787878787878787";
        wait for 20 ns;
        assert (p_out=X"0000000000000000") report "second wrong";
        key <= X"145B7FFF52C891D0";
        p_in <= X"1abafd3e17eda1f3";
        wait for 20 ns;
        assert(p_out=X"707F775A1FA7D83A") report "third wrong";
        p_in <= X"07a98ef65635d797";
        wait for 20 ns;
        assert (p_out=X"4A8B77C1AFA91043") report "fourth wrong";
        wait;
    end process;

end architecture rtl;

