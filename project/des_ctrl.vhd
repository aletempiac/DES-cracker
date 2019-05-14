------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   des_ctrl.vhd
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity des_ctrl is
    port(   clk         : in std_ulogic;
            sresetn     : in std_ulogic;
            start       : in std_ulogic;
            p           : in std_ulogic_vector(63 downto 0);
            c           : in std_ulogic_vector(63 downto 0);
            k0          : in std_ulogic_vector(55 downto 0); -- starting key
            k           : out std_ulogic_vector(55 downto 0); -- last tried key
            k1          : out std_ulogic_vector(55 downto 0); --found key
            found       : out std_ulogic;
            finished    : out std_ulogic
    );
end entity des_ctrl;

architecture rtl of des_ctrl is

    component des_wrap
        port(   clk     : in std_ulogic;
                sresetn : in std_ulogic;
                p_in    : in w64;       --input plaintext
                key     : in w64;       --key
                index   : natural range(0 to DES_NUMBER-1);
                p_out   : out w64       --output cyphered plaintext
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

    -- signals

    type state is (IDLE, LOAD_KEY, WAIT_PIPE, COMPARE, FOUND, NOT_FOUND);
    signal c_state, n_state     : state;

    signal key              : w64;
    signal en_count         : std_ulogic;
    signal end_count        : std_ulogic;
    signal found_local      : std_ulogic;
    signal overflow         : std_ulogic;
    signal key_inc          : std_ulogic;
    --signal en_comp          : std_ulogic;
    signal mux_sel          : std_ulogic;
    signal p_out_array      : des_out_array;


begin

    des_wrap_gen: for i in 0 to DES_NUMBER-1 generate
        des_wrap_i:     des_wrap    port map(clk, sresetn, p, key, i, p_out_array(i));
        comparator_i:   comparator  port map(c, p_out_array(i), found_local);
    end generate;

    counter_0: counter port map(clk, sresetn, start, en_count, end_count);

    p_key_inc: process(clk)
    begin
        if (clk='1' and clk'event) then
            if (key_inc='1') then
                if (mux_sel ='0') then
                    key <= k0;
                elsif (mux_sel = '1') then
                    key <= key + DES_NUMBER;
                end if;
            end if;
        end if;
    end process;


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

    p_comb: process(c_state, start, overflow, end_count, found_local)
    begin
        n_state <= c_state;
        en_count    <= '0';
        key_inc     <= '0';
        found       <= '0';
        finished    <= '0';
        mux_sel     <= '0';

        case c_state is
            when IDLE =>
                if (start = '1') then
                    n_state <= WAIT_PIPE;
                end if;

            when LOAD_KEY =>
                if (end_count = '1') then
                    n_state <= COMPARE;
                end if;

                mux_sel <= '0';
                key_inc <= '1';
                en_count <= '1';


            when WAIT_PIPE =>
                if (end_count = '1') then
                    n_state <= COMPARE;
                end if;

                mux_sel <= '1';
                key_inc <= '1';
                en_count <= '1';

            when COMPARE =>
                if (overflow = '1') then
                    n_state <= NOT_FOUND;
                elsif (found_local = '1') then
                    n_state <= FOUND;
                end if;

                key_inc <= '1';
                en_comp <= '1';

            when NOT_FOUND =>
                n_state <= IDLE;
                finished_local <= '1';

            when FOUND =>
                n_state <= IDLE;
                finished <= '1';
                found <= '1';

            when others =>
                n_state <= IDLE;
        end case;
    end process;

end architecture;
