library ieee;
use ieee.std_logic_1164.all;

--this file is sram controller for IS61WV51216BLL
entity sram_controller is
    port(
        clk, reset          : in std_logic;
        en, wr              : in std_logic;
        addrin              : in std_logic_vector(18 downto 0);
        din                 : in std_logic_vector(47 downto 0);

        dout                : out std_logic_vector(47 downto 0);
        ready               : out std_logic;

        we, ce, oe          : out std_logic;
        addr                : out std_logic_vector(18 downto 0);
        dio                 : inout std_logic_vector(47 downto 0));
end entity;

architecture arch of sram_controller is 
    type state is (idle, read, read2, write, write2);
    
    signal state_now, state_next : state;
    signal tsl_now, tsl_next : std_logic;  --control the TSL
    signal din_now, din_next : std_logic_vector(47 downto 0);
    signal dout_now, dout_next : std_logic_vector(47 downto 0);
    signal addr_now, addr_next : std_logic_vector(18 downto 0);
    signal we_now, we_next : std_logic;
    signal oe_now, oe_next : std_logic;
begin

    ce <= '0';      --always enable ce
    we <= we_now;
    oe <= oe_now;
    addr <= addr_now;
    dout <= dout_now;
    dio <= din_now when tsl_now = '0' else (others => 'Z');

heartbeat:
    process(clk, reset)
        variable inited : std_logic := '0';
    begin
        if (reset = '1' or inited = '0') then
            inited := '1';  --reset on init
            state_now   <= idle;
            tsl_now     <= '1';
            din_now     <= (others => '0');
            dout_now    <= (others => '0');
            addr_now    <= (others => '0');
            we_now      <= '1';
            oe_now      <= '1';
        elsif (rising_edge(clk)) then 
            state_now   <= state_next;
            tsl_now     <= tsl_next;
            din_now     <= din_next;
            dout_now    <= dout_next;
            addr_now    <= addr_next;
            we_now      <= we_next;
            oe_now      <= oe_next;
        end if;
    end process;

change_state:
    process(state_now, en, addrin, din, dio)
    begin
        case (state_now) is
            when (idle) =>
                if (en = '1') then
                    ready       <= '0';
                    addr_next   <= addrin;
                    din_next    <= din;
                    if (wr = '1') then      --write
                        state_next  <= write;
                    else                    --read
                        state_next  <= read;
                    end if;
                else
                    ready       <= '1';
                    state_next  <= idle;
                end if;
            when (read) =>
                state_next      <= read2;
            when (read2) =>
                dout_next       <= dio;
                state_next      <= idle;
            when (write) =>
                state_next      <= write2;
            when (write2) =>
                state_next      <= idle;
        end case;
    end process;

move_preparation:
    process(state_next)
    begin
        case (state_next) is 
            when(idle) => 
                we_next <= '1';
                oe_next <= '1';
                tsl_next <= '1';
            when(read) => 
                we_next <= '1';
                oe_next <= '0';
                tsl_next <= '1';
            when(read2) =>  --wait until data hold finish
                we_next <= '1';
                oe_next <= '0';
                tsl_next <= '1';
            when(write) => 
                we_next <= '0';
                oe_next <= '1';
                tsl_next <= '0';
            when(write2) => --wait until data hold finish
                we_next <= '1';
                oe_next <= '1';
                tsl_next <= '0';
        end case;
    end process;

end architecture;