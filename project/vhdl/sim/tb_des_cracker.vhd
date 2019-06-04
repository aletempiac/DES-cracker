------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino
-- File         :   tb_des_cracker.vhd
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
		impure function get_boolean_p(p : real) return boolean;
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

		impure function get_boolean_p(p : real) return boolean is
		begin
			throw;
			return rnd < p;
		end function get_boolean_p;

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


use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;

package utils_pkg is

	procedure check_unknowns(v: in std_ulogic; s: in string);
	procedure check_unknowns(v: in std_ulogic_vector; s: in string);
    procedure check_ref(v, r: in std_ulogic; s: in string);
	procedure check_ref(v, r: in std_ulogic_vector; s: in string);

end package utils_pkg;

package body utils_pkg is

	function is_01(b: std_ulogic) return boolean is
	begin
		return (b = '0') or (b = '1');
	end function is_01;

	function is_01(b: std_ulogic_vector) return boolean is
	begin
		for i in b'range loop
			if not is_01(b(i)) then
				return false;
			end if;
		end loop;
		return true;
	end function is_01;

	procedure check_unknowns(v: in std_ulogic; s: in string) is
		variable l: line;
	begin
		if not is_01(v) then
			write(l, string'("NON REGRESSION TEST FAILED - "));
			write(l, now);
			writeline(output, l);
			write(l, string'("  INVALID ") & s & string'(" VALUE: "));
			write(l, v);
			writeline(output, l);
			finish;
		end if;
	end procedure check_unknowns;

	procedure check_unknowns(v: in std_ulogic_vector; s: in string) is
		variable l: line;
	begin
		if not is_01(v) then
			write(l, string'("NON REGRESSION TEST FAILED - "));
			write(l, now);
			writeline(output, l);
			write(l, string'("  INVALID ") & s & string'(" VALUE: "));
			write(l, v);
			writeline(output, l);
			finish;
		end if;
	end procedure check_unknowns;

    procedure check_ref(v, r: in std_ulogic; s: in string) is
		variable l: line;
	begin
		if r /= '-' and v /= r then
			write(l, string'("NON REGRESSION TEST FAILED - "));
			write(l, now);
			writeline(output, l);
			write(l, string'("  EXPECTED ") & s & string'("="));
			write(l, r);
			writeline(output, l);
			write(l, string'("       GOT ") & s & string'("="));
			write(l, v);
			writeline(output, l);
			finish;
		end if;
	end procedure check_ref;

    procedure check_ref(v, r: in std_ulogic_vector; s: in string) is
		variable l: line;
        constant lv: std_ulogic_vector(v'length - 1 downto 0) := v;
        constant lr: std_ulogic_vector(r'length - 1 downto 0) := r;
	begin
        for i in v'length - 1 downto 0 loop
            if lr(i) /= '-' and lv(i) /= lr(i) then
                write(l, string'("NON REGRESSION TEST FAILED - "));
                write(l, now);
                writeline(output, l);
                write(l, string'("  EXPECTED ") & s & string'("="));
                write(l, r);
                writeline(output, l);
                write(l, string'("       GOT ") & s & string'("="));
                write(l, v);
                writeline(output, l);
                finish;
            end if;
        end loop;
	end procedure check_ref;

end package body utils_pkg;


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
            stop        : out std_ulogic;
            writep      : out std_ulogic;
            writec      : out std_ulogic;
            p           : out std_ulogic_vector(63 downto 0);
            c           : out std_ulogic_vector(63 downto 0);
            k0          : out std_ulogic_vector(55 downto 0);   -- starting key
            k           : out std_ulogic_vector(55 downto 0);   -- last tried key
            k1          : out std_ulogic_vector(55 downto 0);   --found key
            found       : out std_ulogic;
            evaluate    : out std_ulogic;
            freewrite   : out std_ulogic;
            notfound    : out std_ulogic
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
        variable stop_b : boolean;
        variable stop_i : natural;
        variable start_d: integer;
        variable wait_r : integer;
    begin
        --wait for reset off
        start <= '0';
        stop <= '0';
        writep <= '0';
        writec <= '0';
        p <= (others => '0');
        c <= (others => '0');
        k0 <= (others => '0');
        k <= (others => '0');
        k1 <= (others => '0');
        found <= '0';
        evaluate <= '0';
        freewrite <= '0';
        notfound <= '0';
        wait until sresetn='1' and clk='1' and clk'event;
        loop
            evaluate <= '0';
            p <= (others => '0');
            c <= (others => '0');
            k0 <= (others => '0');
            k <= (others => '0');
            found <= '0';
            --generate new plaintext
            p_loc := rg.get_std_ulogic_vector(64);
            --generate k0
            k0_loc := rg.get_std_ulogic_vector(56);
            --generate difference btw k and k0
            d_k := rg.get_integer(0, 10000);
            --generate probability of stopping
            stop_b := rg.get_boolean_p(0.2);
            stop_i := rg.get_integer(1, d_k);
            --generate start delay
            start_d := rg.get_integer(40, 100);
            --calculate k
            k1_loc := k0_loc + d_k;
            --calculate ciphertext
            p_in <= p_loc;
            p <= p_loc;
            writep <= '1';
            key <= k1_loc(1 to 7) & '0' & k1_loc(8 to 14) & '0' & k1_loc(15 to 21) & '0' & k1_loc(22 to 28) & '0' & k1_loc(29 to 35) & '0' & k1_loc(36 to 42) & '0' & k1_loc(43 to 49) & '0' & k1_loc(50 to 56) & '0';
            wait until clk='1' and clk'event;
            writep <= '0';
            wait_r := rg.get_integer(5, 10);
            for i in  0 to wait_r loop
                wait until clk='1' and clk'event;
            end loop;
            --prepare input stimululus
            c_loc := p_out;
            c <= c_loc;
            writec <= '1';
            wait until clk='1' and clk'event;
            writec <= '0';
            wait_r := rg.get_integer(5, 10);
            for i in  0 to wait_r loop
                wait until clk='1' and clk'event;
            end loop;
            c_loc := p_out;
            k0 <= k0_loc;
            stop <= '1';
            k <= k0_loc;
            wait until clk='1' and clk'event;
            stop <= '0';
            wait_r := rg.get_integer(1, 10);
            for i in  0 to wait_r loop
                wait until clk='1' and clk'event;
            end loop;
            start <= '1';
            wait until clk='1' and clk'event;
            --now start generating signals for comparison
            start <= '0';
            if (stop_b=true) then
                n_iter := (d_k - stop_i) / DES_NUMBER + 1 + PIPE_STAGES;
            else
                n_iter := d_k / DES_NUMBER + 1 + PIPE_STAGES;
            end if;
            wait until clk='1' and clk'event;
            wait until clk='1' and clk'event;
            evaluate <= '1';
            freewrite <= '1';
            for i in 1 to n_iter-1 loop
                wait until clk='1' and clk'event;
                k <= k + DES_NUMBER;
            end loop;
            if (stop_b=true) then
                stop <= '1';
                notfound <= '1';
            else
                found <= '1';
                notfound <= '0';
            end if;
            k1 <= k1_loc;
            wait until clk='1' and clk'event;
            stop <= '0';
            evaluate <= '0';
            found <= '0';
            freewrite <= '0';
            start_d := rg.get_integer(100, 200);
            for i in 0 to start_d loop
                wait until clk='1' and clk'event;
            end loop;
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
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use WORK.des_pkg.all;
use work.rnd_pkg.all;
use work.utils_pkg.all;


entity tb_des_cracker is
end tb_des_cracker;

architecture tb of tb_des_cracker is

    component des_ref
        port(   clk         : in std_ulogic;
                sresetn     : in std_ulogic;
                start       : out std_ulogic;
                stop        : out std_ulogic;
                writep      : out std_ulogic;
                writec      : out std_ulogic;
                p           : out std_ulogic_vector(63 downto 0);
                c           : out std_ulogic_vector(63 downto 0);
                k0          : out std_ulogic_vector(55 downto 0);   -- starting key
                k           : out std_ulogic_vector(55 downto 0);   -- last tried key
                k1          : out std_ulogic_vector(55 downto 0);   --found key
                found       : out std_ulogic;
                evaluate    : out std_ulogic;
                freewrite   : out std_ulogic;
                notfound    : out std_ulogic
        );
    end component des_ref;


    component des_cracker
        port(   aclk            : in std_ulogic;
                aresetn         : in std_ulogic; -- synch active low, a means AXI
                s0_axi_araddr   : in std_ulogic_vector(11 downto 0);
                s0_axi_arvalid  : in std_ulogic;
                s0_axi_arready  : out std_ulogic;
                s0_axi_awaddr   : in std_ulogic_vector(11 downto 0);
                s0_axi_awvalid  : in std_ulogic;
                s0_axi_awready  : out std_ulogic;
                s0_axi_wdata    : in std_ulogic_vector(31 downto 0);
                s0_axi_wstrb    : in std_ulogic_vector(3 downto 0);
                s0_axi_wvalid   : in std_ulogic;
                s0_axi_wready   : out std_ulogic;
                s0_axi_rdata    : out std_ulogic_vector(31 downto 0);
                s0_axi_rresp    : out std_ulogic_vector(1 downto 0);
                s0_axi_rvalid   : out std_ulogic;
                s0_axi_rready   : in std_ulogic;
                s0_axi_bresp    : out std_ulogic_vector(1 downto 0);
                s0_axi_bvalid   : out std_ulogic;
                s0_axi_bready   : in std_ulogic;
                irq             : out std_logic;
                led             : out std_ulogic_vector(3 downto 0)
        );
    end component des_cracker;

	constant axi_resp_okay:   std_ulogic_vector(1 downto 0) := "00";
	constant axi_resp_exokay: std_ulogic_vector(1 downto 0) := "01";
	constant axi_resp_slverr: std_ulogic_vector(1 downto 0) := "10";
	constant axi_resp_decerr: std_ulogic_vector(1 downto 0) := "11";

    signal s0_axi_araddr   :  std_ulogic_vector(11 downto 0);
    signal s0_axi_arvalid  :  std_ulogic;
    signal s0_axi_arready  :  std_ulogic;
    signal s0_axi_awaddr   :  std_ulogic_vector(11 downto 0);
    signal s0_axi_awvalid  :  std_ulogic;
    signal s0_axi_awready  :  std_ulogic;
    signal s0_axi_wdata    :  std_ulogic_vector(31 downto 0);
    signal s0_axi_wstrb    :  std_ulogic_vector(3 downto 0);
    signal s0_axi_wvalid   :  std_ulogic;
    signal s0_axi_wready   :  std_ulogic;
    signal s0_axi_rdata    :  std_ulogic_vector(31 downto 0);
    signal s0_axi_rresp    :  std_ulogic_vector(1 downto 0);
    signal s0_axi_rvalid   :  std_ulogic;
    signal s0_axi_rready   :  std_ulogic;
    signal s0_axi_bresp    :  std_ulogic_vector(1 downto 0);
    signal s0_axi_bvalid   :  std_ulogic;
    signal s0_axi_bready   :  std_ulogic;

	signal s0_axi_arready_ref: std_ulogic;
	signal s0_axi_rdata_ref:   std_ulogic_vector(31 downto 0);
	signal s0_axi_rresp_ref:   std_ulogic_vector(1 downto 0);
	signal s0_axi_rvalid_ref:  std_ulogic;
	signal s0_axi_awready_ref: std_ulogic;
	signal s0_axi_wready_ref:  std_ulogic;
	signal s0_axi_bresp_ref:   std_ulogic_vector(1 downto 0);
	signal s0_axi_bvalid_ref:  std_ulogic;

    signal irq      : std_ulogic;
    signal irq_ref  : std_ulogic;
    signal led      : std_ulogic_vector(3 downto 0);
    signal led_ref  : std_ulogic_vector(3 downto 0);

    signal aclk     : std_ulogic;
    signal aresetn  : std_ulogic;
    signal start    : std_ulogic;
    signal stop     : std_ulogic;
    signal writep   : std_ulogic;
    signal writec   : std_ulogic;
    signal p        : std_ulogic_vector (63 downto 0);
    signal c        : std_ulogic_vector (63 downto 0);
    signal k0       : std_ulogic_vector (55 downto 0);
    signal k_ref    : std_ulogic_vector (55 downto 0);
    signal k1_ref   : std_ulogic_vector (55 downto 0);
    signal found_ref: std_ulogic;
    signal evaluate : std_ulogic;
    signal freewrite: std_logic;
    signal notfound : std_logic;

    signal k_freeze : std_ulogic_vector(55 downto 0);

    constant TbPeriod   : time := 10 ns;
    signal TbClock      : std_logic := '0';
    signal TbSimEnded   : std_logic := '0';

begin


    ref : des_ref
    port map (clk       => aclk,
              sresetn   => aresetn,
              start     => start,
              stop      => stop,
              writep    => writep,
              writec    => writec,
              p         => p,
              c         => c,
              k0        => k0,
              k         => k_ref,
              k1        => k1_ref,
              found     => found_ref,
              evaluate  => evaluate,
              freewrite => freewrite,
              notfound  => notfound);


	dut: des_cracker
	port map(
		aclk           => aclk,
		aresetn        => aresetn,
		s0_axi_araddr  => s0_axi_araddr,
		s0_axi_arvalid => s0_axi_arvalid,
		s0_axi_rready  => s0_axi_rready,
		s0_axi_awaddr  => s0_axi_awaddr,
		s0_axi_awvalid => s0_axi_awvalid,
		s0_axi_wdata   => s0_axi_wdata,
		s0_axi_wstrb   => s0_axi_wstrb,
		s0_axi_wvalid  => s0_axi_wvalid,
		s0_axi_bready  => s0_axi_bready,
		s0_axi_arready => s0_axi_arready,
		s0_axi_rdata   => s0_axi_rdata,
		s0_axi_rresp   => s0_axi_rresp,
		s0_axi_rvalid  => s0_axi_rvalid,
		s0_axi_awready => s0_axi_awready,
		s0_axi_wready  => s0_axi_wready,
		s0_axi_bresp   => s0_axi_bresp,
		s0_axi_bvalid  => s0_axi_bvalid,
        irq            => irq,
		led            => led
	);

	-- Submit AXI4 lite write requests
    process
		variable rg: rnd_generator;
        variable dw: boolean;
        variable pc: boolean;
        variable br: boolean;
        variable wt: integer;
    begin
            s0_axi_awaddr <= "000000000000";
            s0_axi_wdata  <= (others => '0');
            s0_axi_awvalid  <= '0';
            s0_axi_wvalid   <= '0';
            s0_axi_awready_ref <= '0';
            s0_axi_wready_ref <= '0';
            s0_axi_bvalid_ref <= '0';
            s0_axi_bready <= '0';
            s0_axi_bresp_ref <= "--";
            s0_axi_wstrb <= "1111";

            wait until aresetn='1' and aresetn'event;
        loop
            s0_axi_awaddr <= "000000000000";
            s0_axi_wdata  <= (others => '0');
            s0_axi_awvalid  <= '0';
            s0_axi_wvalid   <= '0';
            s0_axi_awready_ref <= '0';
            s0_axi_wready_ref <= '0';
            s0_axi_bvalid_ref <= '0';
            s0_axi_bready <= '0';
            s0_axi_bresp_ref <= "--";
            s0_axi_wstrb <= "1111";


            if (freewrite='0') then
                wait until start='1' or stop='1' or writep='1' or writec='1' or freewrite='1';
                --when a trigger event signal do a write request
                if (freewrite='1') then
                    wt := rg.get_integer(20, 40);
                    for i in 0 to wt loop
                        wait until aclk='1' and aclk'event;
                    end loop;
                    s0_axi_awaddr <= std_ulogic_vector(to_unsigned(rg.get_integer(24, 2**12-1), 12));
                    s0_axi_wdata <= rg.get_std_ulogic_vector(32);
                    dw := false;
                elsif (writep='1') then
                    s0_axi_awaddr <= "000000000000";
                    s0_axi_wdata  <= p(31 downto 0);
                    pc := true;
                    dw := true;
                elsif (writec='1') then
                    s0_axi_awaddr <= "000000001000";
                    s0_axi_wdata  <= c(31 downto 0);
                    pc := false;
                    dw := true;
                elsif (stop='1') then
                    s0_axi_awaddr <= "000000010000";
                    s0_axi_wdata  <= k0(31 downto 0);
                    dw := false;
                elsif (start='1') then
                    s0_axi_awaddr <= "000000010100";
                    s0_axi_wdata(31 downto 24) <= (others => '0');
                    s0_axi_wdata(23 downto 0)  <= k0(55 downto 32);
                    dw := false;
                end if;
            else
                wt := rg.get_integer(20, 40);
                for i in 0 to wt loop
                    wait until aclk='1' and aclk'event;
                end loop;
                s0_axi_awaddr <= std_ulogic_vector(to_unsigned(rg.get_integer(24, 2**12-1), 12));
                s0_axi_wdata <= rg.get_std_ulogic_vector(32);
                dw := false;
            end if;

            s0_axi_awaddr(1 downto 0) <= rg.get_std_ulogic_vector(2);

            s0_axi_awvalid  <= '1';
            s0_axi_wvalid   <= '1';
            br := rg.get_boolean;
            if (br=true) then
                s0_axi_bready <= '1';
            else
                s0_axi_bready <= '0';
            end if;

            wait until aclk='1' and aclk'event;

            s0_axi_awready_ref <= '1';
            s0_axi_wready_ref <= '1';
            s0_axi_bvalid_ref <= '1';
            if (s0_axi_awaddr<24) then
                s0_axi_bresp_ref <= axi_resp_okay;
            elsif (s0_axi_awaddr<40) then
                s0_axi_bresp_ref <= axi_resp_slverr;
            else
                s0_axi_bresp_ref <= axi_resp_decerr;
            end if;


            wait until aclk='1' and aclk'event;

            if (br=false) then
                s0_axi_awready_ref <= '0';
                s0_axi_wready_ref <= '0';
                s0_axi_bvalid_ref <= '1';
                s0_axi_bready <= '1';
                wait until aclk='1' and aclk'event;
            end if;

            s0_axi_awready_ref <= '0';
            s0_axi_wready_ref <= '0';
            s0_axi_bvalid_ref <= '0';

            if (dw=true) then
                if (pc=true) then
                    s0_axi_awaddr <= "000000000100";
                    s0_axi_wdata  <= p(63 downto 32);
                    dw := false;
                else
                    s0_axi_awaddr <= "000000001100";
                    s0_axi_wdata  <= c(63 downto 32);
                    dw := false;
                end if;

                s0_axi_awvalid  <= '1';
                s0_axi_wvalid   <= '1';
                br := rg.get_boolean;
                if (br=true) then
                    s0_axi_bready <= '1';
                else
                    s0_axi_bready <= '0';
                end if;

                wait until aclk='1' and aclk'event;

                s0_axi_awready_ref <= '1';
                s0_axi_wready_ref <= '1';
                s0_axi_bvalid_ref <= '1';

                wait until aclk='1' and aclk'event;

                if (br=false) then
                    s0_axi_awready_ref <= '0';
                    s0_axi_wready_ref <= '0';
                    s0_axi_bvalid_ref <= '1';
                    s0_axi_bready <= '1';
                    wait until aclk='1' and aclk'event;
                end if;

                s0_axi_awready_ref <= '0';
                s0_axi_wready_ref <= '0';
                s0_axi_bvalid_ref <= '0';

            end if;
        end loop;
    end process;

    process
		variable rg: rnd_generator;
        variable rd: integer;
        variable jp: boolean;
        variable br: integer;
        variable freeze : boolean;
    begin
        s0_axi_araddr <= (others => '0');
        s0_axi_arvalid <= '0';
        s0_axi_rready <= '0';
        s0_axi_arready_ref <= '0';
        s0_axi_rdata_ref <= (others => '-');
        s0_axi_rresp_ref <= "--";
        s0_axi_rvalid_ref <= '0';
        freeze := false;
        k_freeze <= (others => '0');
        wait for 500 ns;
        loop
            br := rg.get_integer(0, 50);
            for i in 0 to br loop
                wait until aclk='1' and aclk'event;
            end loop;
            --read a random register
            if (freewrite='1') then
                rd := rg.get_integer(0, 9);
                s0_axi_arvalid <= '1';
                if (rd=1) then
                    s0_axi_araddr <= "000000000000";
                elsif (rd=2) then
                    s0_axi_araddr <= "000000000100";
                elsif (rd=3) then
                    s0_axi_araddr <= "000000001000";
                elsif (rd=4) then
                    s0_axi_araddr <= "000000001100";
                elsif (rd=5) then
                    s0_axi_araddr <= "000000010000";
                elsif (rd=6) then
                    s0_axi_araddr <= "000000010100";
                elsif (rd=7) then
                    s0_axi_araddr <= "000000011000";
                elsif (rd=8) then
                    s0_axi_araddr <= "000000011100";
                elsif (rd=9) then
                    s0_axi_araddr <= std_ulogic_vector(to_unsigned(rg.get_integer(40, 2**12-1), 12));
                end if;
            else
                s0_axi_arvalid <= '1';
                if (notfound='0') then
                    rd := rg.get_integer(9, 12);
                    if (rd=10) then
                        s0_axi_araddr <= "000000100000";
                    elsif (rd=11) then
                        s0_axi_araddr <= "000000100100";
                    elsif (rd=12) then
                        s0_axi_araddr <= std_ulogic_vector(to_unsigned(rg.get_integer(40, 2**12-1), 12));
                    end if;
                else
                    rd := 12;
                    s0_axi_araddr <= std_ulogic_vector(to_unsigned(rg.get_integer(40, 2**12-1), 12));
                end if;
            end if;

            s0_axi_araddr(1 downto 0) <= rg.get_std_ulogic_vector(2);

            wait until aclk='1' and aclk'event;

            jp := rg.get_boolean;
            if (jp=true) then
                s0_axi_rready <= '1';
                s0_axi_arready_ref <= '1';
                s0_axi_rvalid_ref <= '1';
            else
                s0_axi_rready <= '0';
                s0_axi_arready_ref <= '1';
                s0_axi_rvalid_ref <= '1';
                wait until aclk='1' and aclk'event;
                s0_axi_rready <= '1';
                s0_axi_arready_ref <= '0';
                s0_axi_rvalid_ref <= '1';
            end if;

            if (rd=1) then
                s0_axi_rdata_ref <= p(31 downto 0);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=2) then
                s0_axi_rdata_ref <= p(63 downto 32);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=3) then
                s0_axi_rdata_ref <= c(31 downto 0);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=4) then
                s0_axi_rdata_ref <= c(63 downto 32);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=5) then
                s0_axi_rdata_ref <= k0(31 downto 0);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=6) then
                s0_axi_rdata_ref(31 downto 24) <= (others => '0');
                s0_axi_rdata_ref(23 downto 0) <= k0(55 downto 32);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=7) then
                if (freeze=true) then
                    s0_axi_rdata_ref(31 downto 0) <= k_freeze(31 downto 0);
                else
                    freeze := true;
                    if (jp=false) then
                        s0_axi_rdata_ref <= k_ref(31 downto 0) - 3;
                        k_freeze <= k_ref - 3;
                    else
                        s0_axi_rdata_ref <= k_ref(31 downto 0);
                        k_freeze <= k_ref;
                    end if;
                end if;
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=8) then
                if (freeze=true) then
                    s0_axi_rdata_ref(31 downto 24) <= (others => '0');
                    s0_axi_rdata_ref(23 downto 0) <= k_freeze(55 downto 32);
                else
                    s0_axi_rdata_ref(31 downto 24) <= (others => '0');
                    s0_axi_rdata_ref(23 downto 0) <= k_ref(55 downto 32);
                end if;
                s0_axi_rresp_ref <= axi_resp_okay;
                freeze := false;
            elsif (rd=9) then
                s0_axi_rdata_ref <= (others => '0');
                s0_axi_rresp_ref <= axi_resp_decerr;
            elsif (rd=10) then
                s0_axi_rdata_ref <= k1_ref(31 downto 0);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=11) then
                s0_axi_rdata_ref(31 downto 24) <= (others => '0');
                s0_axi_rdata_ref(23 downto 0) <= k1_ref(55 downto 32);
                s0_axi_rresp_ref <= axi_resp_okay;
            elsif (rd=12) then
                s0_axi_rdata_ref <= (others => '0');
                s0_axi_rresp_ref <= axi_resp_decerr;
            end if;

            wait until aclk='1' and aclk'event;

            s0_axi_arvalid <= '0';
            s0_axi_rready <= '0';
            s0_axi_arready_ref <= '0';
            s0_axi_rvalid_ref <= '0';
            s0_axi_rdata_ref <= (others => '-');
            s0_axi_rresp_ref <= "--";

        end loop;
    end process;

    process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            if (aresetn='0') then
                irq_ref <= '0';
                led_ref <= (others => '0');
            else
                irq_ref <= found_ref;
                led_ref <= k_ref(33 downto 30);
            end if;
        end if;
    end process;

	-- Check unknowns
	process
	begin
		wait until rising_edge(aclk) and aresetn = '0';
		loop
			wait until rising_edge(aclk);
			check_unknowns(s0_axi_araddr, "s0_axi_araddr");
			check_unknowns(s0_axi_arvalid, "s0_axi_arvalid");
			check_unknowns(s0_axi_arready, "s0_axi_arready");
			check_unknowns(s0_axi_awaddr, "s0_axi_awaddr");
			check_unknowns(s0_axi_awvalid, "s0_axi_awvalid");
			check_unknowns(s0_axi_awready, "s0_axi_awready");
			check_unknowns(s0_axi_wdata, "s0_axi_wdata");
			check_unknowns(s0_axi_wstrb, "s0_axi_wstrb");
			check_unknowns(s0_axi_wvalid, "s0_axi_wvalid");
			check_unknowns(s0_axi_wready, "s0_axi_wready");
			check_unknowns(s0_axi_rdata, "s0_axi_rdata");
			check_unknowns(s0_axi_rresp, "s0_axi_rresp");
			check_unknowns(s0_axi_rvalid, "s0_axi_rvalid");
			check_unknowns(s0_axi_rready, "s0_axi_rready");
			check_unknowns(s0_axi_bresp, "s0_axi_bresp");
			check_unknowns(s0_axi_bvalid, "s0_axi_bvalid");
			check_unknowns(s0_axi_bready, "s0_axi_bready");
		end loop;
	end process;

	process
	begin
        wait until rising_edge(aclk) and aresetn = '0';
		loop
			wait until rising_edge(aclk);
			check_ref(v => s0_axi_arready, r => s0_axi_arready_ref, s => "s0_axi_arready");
			check_ref(v => s0_axi_rdata, r => s0_axi_rdata_ref, s => "s0_axi_rdata");
			check_ref(v => s0_axi_rresp, r => s0_axi_rresp_ref, s => "s0_axi_rresp");
			check_ref(v => s0_axi_rvalid, r => s0_axi_rvalid_ref, s => "s0_axi_rvalid");
			check_ref(v => s0_axi_awready, r => s0_axi_awready_ref, s => "s0_axi_awready");
			check_ref(v => s0_axi_rdata, r => s0_axi_rdata_ref, s => "s0_axi_wdata");
			check_ref(v => s0_axi_awready, r => s0_axi_wready_ref, s => "s0_axi_awready");
			check_ref(v => s0_axi_bresp, r => s0_axi_bresp_ref, s => "s0_axi_bresp");
			check_ref(v => s0_axi_bvalid, r => s0_axi_bvalid_ref, s => "s0_axi_bvalid");
            check_ref(v => irq, r => irq_ref, s => "irq");
            if (evaluate='1') then
                check_ref(v => led, r => led_ref, s => "led");
            end if;
		end loop;
	end process;


    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    aclk <= TbClock;

    stimulus: process
        variable l : line;
    begin
        -- Reset generation
        aresetn <= '0';
        wait for 100 ns;
        aresetn <= '1';
        wait until aclk='1' and aclk'event;

        wait for 2 ms;
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
		write(l, string'("NON REGRESSION TEST PASSED - "));
		write(l, now);
		writeline(output, l);
        finish;
    end process;

end tb;
