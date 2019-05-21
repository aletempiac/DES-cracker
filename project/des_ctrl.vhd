------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   des_ctrl.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity des_ctrl is
    port(   clk         : in std_ulogic;
            sresetn     : in std_ulogic;
            start       : in std_ulogic;
            p           : in std_ulogic_vector(63 downto 0);
            c           : in std_ulogic_vector(63 downto 0);
            k0          : in std_ulogic_vector(55 downto 0);    -- starting key
            k           : out std_ulogic_vector(55 downto 0);   -- last tried key
            k1          : out std_ulogic_vector(55 downto 0);   --found key
            found       : out std_ulogic
    );
end entity des_ctrl;

architecture rtl of des_ctrl is

    component des_wrap
        port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
                p_in    : in w64;       --input plaintext
                key     : in w64;       --key
                index   : natural range(0 to DES_NUMBER-1);
                p_out   : out w64;      --output cyphered plaintext
                cd16    : out w56       --cd16 represents the permutated key
        );
    end component;

    component counter
        generic(cmax : natural);
        port(   clk         : in std_ulogic;
                sresetn     : in std_ulogic;
                cz          : in std_ulogic;
                inc         : in std_ulogic;
                end_count   : out std_ulogic
        );
    end component;

    component comparator
        generic(N   : positive := 16);
        port(   a   : in std_ulogic_vector(N-1 downto 0);
                b   : in std_ulogic_vector(N-1 downto 0);
                eq  : out std_ulogic
        );
    end component;

    component reg
	    generic(n : positive);
	    port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
		        d       : in std_ulogic_vector(n-1 downto 0);
		        q       : out std_ulogic_vector(n-1 downto 0)
	        );
    end component;

    -- signals

    type state is (IDLE, LOAD_KEY, WAIT_PIPE, COMPARE, FOUND, NOT_FOUND);
    signal c_state, n_state     : state;

    type cd16_array is array (0 to DES_NUMBER-1) of w56;
    signal key              : w64;
    signal inc_count        : std_ulogic;
    signal end_count        : std_ulogic;
    signal found_local      : std_ulogic;
    signal found_array      : std_ulogic_vector(0 to DES_NUMBER-1);
    signal overflow         : std_ulogic;
    signal key_inc          : std_ulogic;
    signal mux_sel          : std_ulogic;
    signal p_out_array      : des_out_array;
    signal p_out_array_s    : des_out_array;
    signal cd16             : cd16_array;
    signal cd16_s           : cd16_array;
    signal cd16_mux         : w56;

begin

    des_wrap_gen: for i in 0 to DES_NUMBER-1 generate
        des_wrap_i:     des_wrap    port map(clk, sresetn, p, key, i, p_out_array(i), cd16(i));
        reg_des_ciph_i: reg         port map(clk, sresetn, p_out_array(i), p_out_array_s(i));
        reg_des_cd16_i: reg         port map(clk, sresetn, cd16(i), cd16_s(i));
        comparator_i:   comparator  port map(c, p_out_array_s(i), found_array(i));
    end generate;

    p_mux: process(cd16_s, found_array)
    begin
        for i in 0 to DES_NUMBER-1 loop
            if (found_array(i)='1') then
                cd16_mux <= cd16_s(i);
            end if;
        end loop;
    end process;

    k1 <= pc1_inv(cd16_mux);

    p_found: process(found_local)
        variable tmp : std_ulogic;
    begin
        tmp := '0';
        for i in 0 to DES_NUMBER-1 loop
            tmp := tmp or found_array(i);
        end loop;
        found_local <= tmp;
    end process;

    found <= found_local;

    counter_0: counter port map(clk, sresetn, start, inc_count, end_count);

    p_key_inc: process(clk)
    begin
        if (clk='1' and clk'event) then
            if (key_inc='0') then
                key <= k0;
            else
                key <= key + DES_NUMBER;
            end if;
        end if;
    end process;

    k <= key;


    p_states: process(clk)
    begin
        if (clk='1' and clk'event) then
            if (sresetn='0') then
                c_state <= idle;
            else
                c_state <= n_state;
            end if;
        end if;
    end process;

    p_comb: process(c_state, start, end_count, found_local)
    begin
        n_state     <= c_state;
        inc_count   <= '0';
        key_inc     <= '0';
        found       <= '0';

        case c_state is
            when IDLE =>
                if (start = '1') then
                    --n_state <= LOAD_KEY;
                    n_state <= WAIT_PIPE;
                end if;

            --when LOAD_KEY =>

               -- n_state <= WAIT_PIPE;

                --key_inc <= '0';
                --inc_count <= '1';


            when WAIT_PIPE =>
                if (end_count = '1') then
                    n_state <= COMPARE;
                end if;

                key_inc <= '1';
                inc_count <= '1';

            when COMPARE =>
                if (found_local = '1') then
                    n_state <= FOUND;
                end if;

                key_inc <= '1';

            when FOUND =>
                n_state <= IDLE;
                found <= '1';

            when others =>
                n_state <= IDLE;
        end case;
    end process;

end architecture;
