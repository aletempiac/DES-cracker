------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   tb_des_ctrl.vhd
------------------------------------------------------------
library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;

package rnd_pkg is

	type rnd_generator is protected
		procedure init(s1, s2: positive);
		impure function get_boolean return boolean;
		impure function get_integer(min, max: integer) return integer;
		impure function get_bit return bit;
		impure function get_bit_vector(size: positive) return bit_vector;
		impure function get_std_ulogic return std_ulogic;
		impure function get_std_ulogic_vector(size: positive) return std_ulogic_vector;
		impure function get_u_unsigned(size: positive) return u_unsigned;
	end protected rnd_generator;

end package rnd_pkg;

package body rnd_pkg is

	type rnd_generator is protected body
		variable seed1: positive := 1;
		variable seed2: positive := 1;
		variable rnd:   real;

		procedure throw is
		begin
			uniform(seed1, seed2, rnd);
		end procedure throw;

		procedure init(s1, s2: positive) is
		begin
			seed1 := s1;
			seed2 := s2;
		end procedure init;

		impure function get_boolean return boolean is
		begin
			throw;
			return rnd < 0.5;
		end function get_boolean;

		impure function get_integer(min, max: integer) return integer is
			variable tmp: integer;
		begin
			throw;
			tmp := min + integer(real(max - min) * rnd + 0.5);
			return tmp;
		end function get_integer;

		impure function get_bit return bit is
		variable res: bit;
		begin
			res := '0' when get_boolean else '1';
			return res;
		end function get_bit;

		impure function get_std_ulogic return std_ulogic is
		variable res: std_ulogic;
		begin
			res := '0' when get_boolean else '1';
			return res;
		end function get_std_ulogic;

		impure function get_u_unsigned(size: positive) return u_unsigned is
		variable res: u_unsigned(1 to size);
		begin
			if size < 30 then
				res := to_unsigned(get_integer(0, 2**size - 1), size);
			else
				res := to_unsigned(get_integer(0, 2**30 - 1), 30) & get_u_unsigned(size - 30);
			end if;
			return res;
		end function get_u_unsigned;

		impure function get_std_ulogic_vector(size: positive) return std_ulogic_vector is
		begin
			return std_ulogic_vector(get_u_unsigned(size));
		end function get_std_ulogic_vector;

		impure function get_bit_vector(size: positive) return bit_vector is
		begin
			return to_bitvector(get_std_ulogic_vector(size));
		end function get_bit_vector;
	end protected body rnd_generator;

end package body rnd_pkg;




-----------------------------------------------------------
-----------------------------------------------------------
--------------------DES SIMULATOR--------------------------
-----------------------------------------------------------
-----------------------------------------------------------

library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;

entity key_round_s is
  port(
    c_in   : in w28;
    d_in   : in w28;
    shift_amount  : in natural;
    c_out  : out w28;
    d_out  : out w28;
    k_out  : out w48
  );
end entity key_round_s;

architecture rtl of key_round_s is

  signal pc2_local : w56;
  signal c_local, d_local : w28;

begin

  c_local <= left_shift(c_in, shift_amount);
  d_local <= left_shift(d_in, shift_amount);
  pc2_local <= c_local & d_local;

  k_out <= pc2(pc2_local);
  c_out <= c_local;
  d_out <= d_local;

end rtl;

library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;


entity key_gen_s is
  port (
    key   : in w64;
    key_out : out key_array
  );
end entity key_gen_s;

architecture rtl of key_gen_s is

    component key_round_s
        port(   c_in   : in w28;
                d_in   : in w28;
                shift_amount  : in natural;
                c_out  : out w28;
                d_out  : out w28;
                k_out  : out w48
            );
   end component key_round_s;


  signal pc1_local  : w56;
  signal c_local : cd_array;
  signal d_local : cd_array;

begin

  pc1_local <= pc1(key);
  c_local(0) <= pc1_local (1 to 28);
  d_local(0) <= pc1_local (29 to 56);

  gen_key_round_s: for i in 1 to 16 generate
    key_round_s_i: key_round_s port map(c_local(i-1), d_local(i-1), SHIFT_TABLE(i), c_local(i), d_local(i), key_out(i));
  end generate;


end rtl;


library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;

entity s_box_s is
    port(   s_in    : in std_ulogic_vector(0 to 5);
            s_table : in s_matrix(0 to 3, 0 to 15);
            s_out   : out std_ulogic_vector(0 to 3)
    );
end entity s_box_s;


architecture rtl of s_box_s is

    signal row_index, col_index : natural;
    signal s_in_row : std_ulogic_vector(0 to 1);

begin

    s_in_row <= s_in(0) & s_in(5);
	row_index <= to_integer(unsigned(s_in_row));
    col_index <= to_integer(unsigned(s_in(1 to 4)));
    s_out <= s_table(row_index, col_index);

end architecture rtl;


library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;


entity cipher_f_s is
    port(   r   : in w32;
            k   : in w48;
            f_out : out w32
    );
end entity cipher_f_s;


architecture rtl of cipher_f_s is

    component s_box_s
        port(   s_in    : in std_ulogic_vector(0 to 5);
                s_table : in s_matrix;
                s_out   : out std_ulogic_vector(0 to 3)
        );
    end component s_box_s;


    signal e_local : w48;
    signal x_local : w48;
    signal s_local : w32;

begin

	e_local <= e(r);            --e permutation
    x_local <= e_local xor k;

    gen_s_box_s: for i in 0 to 7 generate
        s_box_s_i: s_box_s port map(x_local(i*6+1 to i*6+6), S_BOXES(i), s_local(i*4+1 to i*4+4));
    end generate;

    f_out <= p(s_local);    --p permutation

end architecture rtl;


library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;


entity f_wrapper_s is
    port(   l       : in w32;
            r       : in w32;
            k       : in w48;
            newr    : out w32
    );
end entity f_wrapper_s;


architecture rtl of f_wrapper_s is

    component cipher_f_s
        port(   r   : in w32;
                k   : in w48;
                f_out : out w32
        );
    end component cipher_f_s;

    signal f_local : w32;
begin

	cipher_f_s_0: cipher_f_s port map(r, k, f_local);

    newr <= l xor f_local;

end architecture rtl;


library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;


entity des_sim is
    port(   p_in    : in w64;       --input plaintext
            key     : in w64;       --key
            p_out   : out w64       --output cyphered plaintext
    );
end entity des_sim;

architecture rtl of des_sim is

    --component instantiation
    component f_wrapper_s
        port(   l       : in w32;
                r       : in w32;
                k       : in w48;
                newr    : out w32
            );
    end component;


    component key_gen_s
        port(   key   : in w64;
                key_out : out key_array
            );
    end component;


    --signals declarations
    signal lr_0, lr_16 : w64;

    type lr_type is array(0 to 16) of w32;
    signal l_local, r_local : lr_type;
    signal k : key_array;

begin

    --initial permutation of  p_in
	lr_0 <= ip(p_in);
    l_local(0) <= lr_0(1 to 32);
    r_local(0) <= lr_0(33 to 64);


    key_gen_s_0: key_gen_s port map (key, k);

    --start of the enciphering process
    enc_gen: for i in 1 to 16 generate
        l_local(i) <= r_local(i-1);
        f_wrapper_s_i : f_wrapper_s port map (l_local(i-1), r_local(i-1), k(i), r_local(i));
    end generate;

    lr_16 <= r_local(16)&l_local(16);

    --end permutation
    p_out <= fp(lr_16);

end architecture rtl;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.math_real.all;
use WORK.des_pkg.all;
use work.rnd_pkg.all;

entity des_ref is
    port(   clk         : in std_ulogic;
            sresetn     : in std_ulogic;
            start       : out std_ulogic;
            p           : out std_ulogic_vector(63 downto 0);
            c           : out std_ulogic_vector(63 downto 0);
            k0          : out std_ulogic_vector(55 downto 0);   -- starting key
            k           : out std_ulogic_vector(55 downto 0);   -- last tried key
            k1          : out std_ulogic_vector(55 downto 0);   --found key
            found       : out std_ulogic;
            evaluate    : out std_ulogic
    );
end entity des_ref;


architecture beh of des_ref is


    component des_sim
        port(   p_in    : in w64;       --input plaintext
                key     : in w64;       --key
                p_out   : out w64       --output cyphered plaintext
        );
    end component des_sim;

    signal p_in     : w64;
    signal key      : w64;
    signal p_out    : w64;

    constant PIPE_STAGES : natural := 17;

begin

    des_sim_u : entity work.des_sim(rtl)
    port map(
        p_in    => p_in,
        key     => key,
        p_out   => p_out
    );

    process
        variable rg     : rnd_generator;
        variable d_k    : integer;  --distance between k0 and k
        variable k0_loc : w56;
        variable k_loc  : w56;
        variable p_loc  : w64;
        variable c_loc  : w64;
        variable k1_loc : w56;
        variable n_iter : natural;
    begin
        --wait for reset off
        start <= '0';
        p <= (others => '0');
        c <= (others => '0');
        k0 <= (others => '0');
        k <= (others => '0');
        k1 <= (others => '0');
        found <= '0';
        evaluate <= '0';
        wait until sresetn='1' and clk='1' and clk'event;
        loop
            evaluate <= '0';
            --start <= '0';
            p <= (others => '0');
            c <= (others => '0');
            k0 <= (others => '0');
            k <= (others => '0');
            k1 <= (others => '0');
            found <= '0';
            --generate new plaintext
            p_loc := rg.get_std_ulogic_vector(64);
            --generate k0
            k0_loc := rg.get_std_ulogic_vector(56);
            --generate difference btw k and k0
            d_k := rg.get_integer(10, 2048);
            --calculate k
            k1_loc := k0_loc + d_k;
            --calculate ciphertext
            p_in <= p_loc;
            key <= k1_loc(1 to 7) & '0' & k1_loc(8 to 14) & '0' & k1_loc(15 to 21) & '0' & k1_loc(22 to 28) & '0' & k1_loc(29 to 35) & '0' & k1_loc(36 to 42) & '0' & k1_loc(43 to 49) & '0' & k1_loc(50 to 56) & '0';
            wait until clk='1' and clk'event;
            --prepare input stimululus
            c_loc := p_out;
            start <= '1';
            p <= p_loc;
            c <= c_loc;
            k0 <= k0_loc;
            k <= k0_loc;
            k1 <= k1_loc;
            wait until clk='1' and clk'event;
            --now start generating signals for comparison
            start <= '0';
            n_iter := d_k / DES_NUMBER + 1 + PIPE_STAGES;
            wait until clk='1' and clk'event;
            k <= k + DES_NUMBER;
            evaluate <= '1';
            for i in 1 to n_iter-1 loop
                wait until clk='1' and clk'event;
                k <= k + DES_NUMBER;
            end loop;
            found <= '1';
            wait until clk='1' and clk'event;
        end loop;
    end process;
end architecture;


------------------------------------------------------------
------------------------------------------------------------
---------------------TESTBENCH------------------------------
------------------------------------------------------------
------------------------------------------------------------

use std.textio.all;
use std.env.all;
library ieee;
library WORK;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.des_pkg.all;
use work.rnd_pkg.all;


entity tb_des_ctrl is
end tb_des_ctrl;

architecture tb of tb_des_ctrl is

    component des_ref
        port(   clk         : in std_ulogic;
                sresetn     : in std_ulogic;
                start       : out std_ulogic;
                p           : out std_ulogic_vector(63 downto 0);
                c           : out std_ulogic_vector(63 downto 0);
                k0          : out std_ulogic_vector(55 downto 0);   -- starting key
                k           : out std_ulogic_vector(55 downto 0);   -- last tried key
                k1          : out std_ulogic_vector(55 downto 0);   --found key
                found       : out std_ulogic;
                evaluate    : out std_ulogic
        );
    end component des_ref;


    component des_ctrl
        port (clk     : in std_ulogic;
              sresetn : in std_ulogic;
              start   : in std_ulogic;
              p       : in std_ulogic_vector (63 downto 0);
              c       : in std_ulogic_vector (63 downto 0);
              k0      : in std_ulogic_vector (55 downto 0);
              k       : out std_ulogic_vector (55 downto 0);
              k1      : out std_ulogic_vector (55 downto 0);
              found   : out std_ulogic);
    end component;

    signal clk      : std_ulogic;
    signal sresetn  : std_ulogic;
    signal start    : std_ulogic;
    signal p        : std_ulogic_vector (63 downto 0);
    signal c        : std_ulogic_vector (63 downto 0);
    signal k0       : std_ulogic_vector (55 downto 0);
    signal k_ref    : std_ulogic_vector (55 downto 0);
    signal k        : std_ulogic_vector (55 downto 0);
    signal k1_ref   : std_ulogic_vector (55 downto 0);
    signal k1       : std_ulogic_vector (55 downto 0);
    signal found_ref: std_ulogic;
    signal found    : std_ulogic;
    signal evaluate : std_ulogic;

    constant TbPeriod   : time := 10 ns;
    signal TbClock      : std_logic := '0';
    signal TbSimEnded   : std_logic := '0';

begin


    ref : des_ref
    port map (clk       => clk,
              sresetn   => sresetn,
              start     => start,
              p         => p,
              c         => c,
              k0        => k0,
              k         => k_ref,
              k1        => k1_ref,
              found     => found_ref,
              evaluate  => evaluate);


    dut : des_ctrl
    port map (clk     => clk,
              sresetn => sresetn,
              start   => start,
              p       => p,
              c       => c,
              k0      => k0,
              k       => k,
              k1      => k1,
              found   => found);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    clk <= TbClock;

    stimulus: process
        variable l : line;
    begin
        -- Reset generation
        sresetn <= '0';
        wait for 100 ns;
        sresetn <= '1';
        wait until clk='1' and clk'event;

        wait for 200 us;
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
		write(l, string'("NON REGRESSION TEST PASSED - "));
		write(l, now);
		writeline(output, l);
        finish;
    end process;

    process
        variable l : line;
    begin
    wait until clk='1' and clk'event;
    if (evaluate='1') then
    	if (found_ref /= found and found_ref = '1') then
    		write(l, string'("NON REGRESSION TEST FAILED - "));
    		write(l, now);
    		writeline(output, l);
    		write(l, string'("  found SHOULD HAVE BEEN ASSERTED"));
    		writeline(output, l);
    		finish;
    	end if;
    	if (found_ref /= found and found = '1') then
    		write(l, string'("NON REGRESSION TEST FAILED - "));
    		write(l, now);
    		writeline(output, l);
    		write(l, string'("  found SHOULD HAVE NOT BEEN ASSERTED"));
    		writeline(output, l);
    		finish;
    	end if;
    	if not (k_ref = k) then
    		write(l, string'("NON REGRESSION TEST FAILED - "));
    		write(l, now);
    		writeline(output, l);
    		write(l, string'("  k SHOULD HAVE BEEN UPDATED"));
    		writeline(output, l);
    		finish;
    	end if;
    	if (k1_ref /= k1 and found = '1') then
    		write(l, string'("NON REGRESSION TEST FAILED - "));
    		write(l, now);
    		writeline(output, l);
            write(l, string'("  WRONG KEY FOUND"));
    		writeline(output, l);
    		finish;
    	end if;
    end if;
    end process;

end tb;
