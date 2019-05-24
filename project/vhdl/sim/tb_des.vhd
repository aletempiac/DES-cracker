------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   tb_des.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;
USE ieee.std_logic_signed.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

entity tb_des is
end entity tb_des;


architecture rtl of tb_des is

    component des
        port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
                p_in    : in w64;       --input plaintext
                key     : in w64;       --key
                p_out   : out w64       --output ciphereded plaintext
            );
    end component des;

    --signals
    signal clk      : std_ulogic;
    signal sresetn  : std_ulogic;
    signal p_in     : w64;
    signal key      : w64;
    signal p_out    : w64;

    -- Clock period definitions
   constant clk_period : time := 10 ns;

begin

    des_uut: des port map(clk, sresetn, p_in, key, p_out);

    -- Clock process definitions
    clk_gen : process
    begin
        clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
    end process;

    --read inputs process
	input_proc : process
		FILE 	vectorfile 	: text;
		VARIABLE inputline 	: line;
		VARIABLE readp_in	: w64;
        VARIABLE readkey	: w64;
		VARIABLE space     	: character;
    begin
		file_open(vectorfile, "vector.txt", read_mode);

        sresetn <= '0';
        key <= (others => '0');
        p_in <= (others => '0');

        wait for 100 ns;
        wait until clk='1' and clk'event;
        sresetn <= '1';

		while not endfile(vectorfile) loop
			readline(vectorfile, inputline);

			hread(inputline, readp_in);	--read p_in
			read(inputline, space);		--read a space divider
			hread(inputline, readkey);	--read key

			p_in <= readp_in;
			key <= readkey;

            -- wait until clk='1' and clk'event;
			wait for clk_period;
		end loop;

		file_close(vectorfile);
		wait;
	end process;

	--read expected output and verify the result
	output_proc : process
		FILE 	expectedfile 	: text;
		VARIABLE resultline 	: line;
        VARIABLE readciphered     : w64;
	begin

		file_open(expectedfile, "expected.txt", read_mode);
        wait for 100 ns;
        wait for clk_period*15;

		wait until clk='1' AND clk'event;

		while not endfile(expectedfile) loop
			readline(expectedfile, resultline);

			hread(resultline, readciphered);

			assert (p_out = readciphered) report "Wrong result! DES failure.. Result:" & to_hstring(p_out) &" Expected:" & to_hstring(readciphered);
            wait for clk_period;
		end loop;

		file_close(expectedfile);

		wait;
	end process;

    -- stimulus: process
    -- begin
    --     sresetn <= '0';
    --     key <= X"133457799BBCDFF1";
    --     p_in <= X"0123456789ABCDEF";
    --     wait for 100 ns;
    --     wait until clk='1' and clk'event;
    --     sresetn <= '1';
    --     wait until clk='1' and clk'event;
    --
    --     key <= X"0E329232EA6D0D73";
    --     p_in <= X"8787878787878787";
    --     wait until clk='1' and clk'event;
    --
    --     key <= X"145B7FFF52C891D0";
    --     p_in <= X"1abafd3e17eda1f3";
    --     wait until clk='1' and clk'event;
    --
    --     p_in <= X"07a98ef65635d797";
    --     wait until clk='1' and clk'event;
    --
    --     wait;
    -- end process;
    --
    -- assert_p: process
    -- begin
    --     wait until sresetn='1' and sresetn'event;
    --     for i in 0 to 15 loop
    --         wait until clk='1' and clk'event;
    --     end loop;
    --
    --     assert (p_out=X"85E813540F0AB405") report "first wrong";
    --     wait until clk='1' and clk'event;
    --     assert (p_out=X"0000000000000000") report "second wrong";
    --     wait until clk='1' and clk'event;
    --     assert(p_out=X"707F775A1FA7D83A") report "third wrong";
    --     wait until clk='1' and clk'event;
    --     assert (p_out=X"4A8B77C1AFA91043") report "fourth wrong";
    --     wait;
    -- end process;

end architecture rtl;
