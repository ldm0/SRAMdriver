library ieee;
use ieee.std_logic_1164.all;

--this file is sram controller for IS61WV51216BLL
entity sram_controller is
    port(
        clk, reset          : in std_logic; --should be at most 100mhz, 10ns the least interval for read
        en, wr              : in std_logic; --for wr, 0 means read, 1 means write
        addrin              : in std_logic_vector(18 downto 0);
        din                 : in std_logic_vector(47 downto 0);

        dout                : out std_logic_vector(47 downto 0); --can be directly accessed
        ready               : out std_logic;

        we, ce, oe          : out std_logic;
        addr                : out std_logic_vector(18 downto 0);
        dio                 : inout std_logic_vector(47 downto 0));
end entity;

architecture arch of sram_controller is 
    --state idle : just idle and wait for input
    --  when en change to '1' according to rw, change to read or write state
    --state read : enable the oe and use addr, wait to really read
    --  after a clock, read the dio and move the result to dout,
    --  then state change to idle
    --state write : enable the we and use addr and din
    --  after a clock, remove din 
    --  then state change to idle 
    type state is (idle, read, write);
    
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
    begin
        if (reset = '1') then
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
                dout_next       <= dio;
                state_next      <= idle;
            when (write) =>
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
            when(write) => 
                we_next <= '0';
                oe_next <= '1';
                tsl_next <= '0';
        end case;
    end process;

end architecture;