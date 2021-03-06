------------------------------------------------------------
-- Author       :   Alessandro Tempia Calvino, Pietro Mambelli
-- File         :   des_cracker.vhd
------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.des_pkg.all;

entity des_cracker is
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
end entity des_cracker;

architecture rtl of des_cracker is

    component des_ctrl
    port(   clk         : in std_ulogic;
            sresetn     : in std_ulogic;
            start       : in std_ulogic;
            stop        : in std_ulogic;
            p           : in std_ulogic_vector(63 downto 0);
            c           : in std_ulogic_vector(63 downto 0);
            k0          : in std_ulogic_vector(55 downto 0);    -- starting key
            k           : out std_ulogic_vector(55 downto 0);   -- last tried key
            k1          : out std_ulogic_vector(55 downto 0);   -- found key
            found       : out std_ulogic
    );
    end component;

    signal start    : std_ulogic;
    signal stop     : std_ulogic;
    signal p        : std_ulogic_vector(63 downto 0);   --0x000
    signal c        : std_ulogic_vector(63 downto 0);   --0x008
    signal k0       : std_ulogic_vector(55 downto 0);   --0x010
    signal k        : std_ulogic_vector(55 downto 0);   --0x018
    signal k1       : std_ulogic_vector(55 downto 0);   --0x020
    signal found    : std_ulogic;

    signal k_s      : std_ulogic_vector(55 downto 0);
    signal k1_s     : std_ulogic_vector(55 downto 0);   --0x020
    signal k_read   : std_ulogic;
    signal k_freeze : std_ulogic_vector(55 downto 0);
    signal found_s  : std_ulogic;

    --state machine signals
    type state_type_r is (WAIT_V, ACK_R, WAIT_R);
    signal c_state_r, n_state_r : state_type_r;
    type state_type_w is (WAIT_V, ACK_R, WAIT_R);
    signal c_state_w, n_state_w : state_type_w;


    constant OKAY   : std_ulogic_vector(1 downto 0) := "00";
    constant EXOKAY : std_ulogic_vector(1 downto 0) := "01";
    constant SLVERR : std_ulogic_vector(1 downto 0) := "10";
    constant DECERR : std_ulogic_vector(1 downto 0) := "11";

begin

    des_ctrl_0 : des_ctrl
    port map (clk     => aclk,
              sresetn   => aresetn,
              start     => start,
              stop      => stop,
              p         => p,
              c         => c,
              k0        => k0,
              k         => k,
              k1        => k1,
              found     => found);


    process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            if (aresetn='0') then
                k1_s    <= (others => '0');
                k_s     <= (others => '0');
                led     <= (others => '0');
                found_s <= '0';
                irq     <= '0';
            else
                if (found='1') then
                    k1_s    <= k1;
                end if;
                led(3 downto 0) <= k(33 downto 30);
                if (k_read='0') then
                    k_s <= k;
                else
                    k_s <= k_freeze;
                end if;
                irq <= found;
            end if;
        end if;
    end process;

    p_sread: process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            if (aresetn='0') then
                c_state_r <= WAIT_V;
            else
                c_state_r <= n_state_r;
            end if;
        end if;
    end process;

    p_combread: process(c_state_r, s0_axi_arvalid, s0_axi_rready)
    begin
        n_state_r <= c_state_r;
        s0_axi_arready <= '0';
        s0_axi_rvalid <= '0';

        case c_state_r is
            when WAIT_V =>
                if (s0_axi_arvalid='1') then
                    n_state_r <= ACK_R;
                end if;

            when ACK_R =>
                s0_axi_arready <= '1';
                s0_axi_rvalid <= '1';

                if (s0_axi_rready='1') then
                    n_state_r <= WAIT_V;
                else
                    n_state_r <= WAIT_R;
                end if;

            when WAIT_R =>
                s0_axi_arready <= '0';
                s0_axi_rvalid <= '1';

                if (s0_axi_rready='1') then
                    n_state_r <= WAIT_V;
                end if;

            when others =>
                n_state_r <= WAIT_V;
            end case;
    end process;


    p_rresp: process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            if (aresetn='0') then
                s0_axi_rresp <= OKAY;
                s0_axi_rdata <= (others=>'0');
                k_read       <= '0';
                k_freeze     <= (others => '0');
            else
                if (n_state_r=ACK_R) then
                    if (s0_axi_araddr(11 downto 2)="0000000000") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= p(31 downto 0);
                    elsif (s0_axi_araddr(11 downto 2)="0000000001") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= p(63 downto 32);
                    elsif (s0_axi_araddr(11 downto 2)="0000000010") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= c(31 downto 0);
                    elsif (s0_axi_araddr(11 downto 2)="0000000011") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= c(63 downto 32);
                    elsif (s0_axi_araddr(11 downto 2)="0000000100") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= k0(31 downto 0);
                    elsif (s0_axi_araddr(11 downto 2)="0000000101") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata(31 downto 24) <= (others => '0');
                        s0_axi_rdata(23 downto 0) <= k0(55 downto 32);
                    elsif (s0_axi_araddr(11 downto 2)="0000000110") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= k_s(31 downto 0);
                        k_read       <= '1';    --to stop the update of k during reading
                        k_freeze     <= k_s;
                    elsif (s0_axi_araddr(11 downto 2)="0000000111") then
                        k_read       <= '0';
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata(31 downto 24) <= (others => '0');
                        s0_axi_rdata(23 downto 0) <= k_s(55 downto 32);
                    elsif (s0_axi_araddr(11 downto 2)="0000001000") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata <= k1_s(31 downto 0);
                    elsif (s0_axi_araddr(11 downto 2)="0000001001") then
                        s0_axi_rresp <= OKAY;
                        s0_axi_rdata(31 downto 24) <= (others => '0');
                        s0_axi_rdata(23 downto 0) <= k1_s(55 downto 32);
                    else
                        s0_axi_rresp <= DECERR;
                        s0_axi_rdata<= (others=>'0');
                    end if;
                end if;
            end if;
        end if;
    end process;


    p_swrite: process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            if (aresetn='0') then
                c_state_w <= WAIT_V;
            else
                c_state_w <= n_state_w;
            end if;
        end if;
    end process;


    p_combwrite: process(c_state_w, s0_axi_awvalid, s0_axi_wvalid, s0_axi_bready)
    begin
        n_state_w <= c_state_w;
        s0_axi_awready <= '0';
        s0_axi_wready <= '0';
        s0_axi_bvalid <= '0';

        case c_state_w is
            when WAIT_V =>
                if (s0_axi_awvalid='1' and s0_axi_wvalid='1') then
                    n_state_w <= ACK_R;
                end if;

            when ACK_R =>
                s0_axi_awready <= '1';
                s0_axi_wready <= '1';
                s0_axi_bvalid <= '1';



                if (s0_axi_bready='1') then
                    n_state_w <= WAIT_V;
                else
                    n_state_w <= WAIT_R;
                end if;

            when WAIT_R =>
                s0_axi_awready <= '0';
                s0_axi_wready <= '0';
                s0_axi_bvalid <= '1';


                if (s0_axi_bready='1') then
                    n_state_w <= WAIT_V;
                else
                    n_state_w <= WAIT_R;
                end if;

            when others =>
                n_state_w <= WAIT_V;
            end case;
    end process;

    p_wresp: process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            if (aresetn='0') then
                s0_axi_bresp <= OKAY;
            else
                if (n_state_w=ACK_R) then
                    if (s0_axi_awaddr(11 downto 2)="0000000000") then
                        s0_axi_bresp <= OKAY;
                        p(31 downto 0) <= s0_axi_wdata;
                    elsif (s0_axi_awaddr(11 downto 2)="0000000001") then
                        s0_axi_bresp <= OKAY;
                        p(63 downto 32) <= s0_axi_wdata;
                    elsif (s0_axi_awaddr(11 downto 2)="0000000010") then
                        s0_axi_bresp <= OKAY;
                        c(31 downto 0) <= s0_axi_wdata;
                    elsif (s0_axi_awaddr(11 downto 2)="0000000011") then
                        s0_axi_bresp <= OKAY;
                        c(63 downto 32) <= s0_axi_wdata;
                    elsif (s0_axi_awaddr(11 downto 2)="0000000100") then
                        s0_axi_bresp <= OKAY;
                        k0(31 downto 0) <= s0_axi_wdata;
                    elsif (s0_axi_awaddr(11 downto 2)="0000000101") then
                        s0_axi_bresp <= OKAY;
                        k0(55 downto 32) <= s0_axi_wdata(23 downto 0);
                    elsif (s0_axi_awaddr(11 downto 3)="000000011") then
                        s0_axi_bresp <= SLVERR;
                    elsif (s0_axi_awaddr(11 downto 3)="000000100") then
                        s0_axi_bresp <= SLVERR;
                    else
                        s0_axi_bresp <= DECERR;
                    end if;
                end if;
            end if;
        end if;
    end process;

    p_startstop: process(aclk)
    begin
        if (aclk='1' and aclk'event) then
            start   <= '0';
            stop    <= '0';
            if (n_state_w=ACK_R) then
                if (s0_axi_awaddr(11 downto 2)="0000000100") then
                    stop    <= '1';
                elsif (s0_axi_awaddr(11 downto 2)="0000000101") then
                    start   <= '1';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
