------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   s_box.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_UNSIGNED.all;
use WORK.des_pkg.all;

entity s_box is
    port(   s_in    : in std_ulogic_vector(0 to 5);
            s_table : in s_matrix;
            s_out   : out std_ulogic_vector(0 to 3)
    );
end entity s_box;


architecture rtl of s_box is

    signal row_index, col_index : natural;

begin

	row_index <= to_integer(unsigned(s_in(0)&s_in(5)));
    col_index <= to_integer(unsigned(s_in(1 to 4)));
    s_out <= s_table(row_index, col_index);

end architecture rtl;
