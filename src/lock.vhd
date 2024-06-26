library ieee;
use ieee.std_logic_1164.all;

entity digital_lock is
    generic (
        count_thresh : integer := 20_000_000
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        btn : in std_logic_vector(3 downto 0);
        led : out std_logic_vector(3 downto 0)
    );
end digital_lock;

architecture Behavioral of digital_lock is

    component debounce is
        generic (
            clk_freq : integer := 125_000_000;
            stable_time : integer := 10
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            button : in std_logic;
            result : out std_logic
        );
    end component;

    component single_pulse_detector is
        generic (detect_type : std_logic_vector(1 downto 0) := "01");
        port (
            clk : in std_logic;
            rst : in std_logic;
            input_signal : in std_logic;
            output_pulse : out std_logic);
    end component;

    type state_type is (LOCK, S1, S2, S3, Unlock, W1, W2, W3, Alarm, A1, R1, R2, R3, Reset);

    signal guess : state_type := LOCK;
    signal east_btn : std_logic := '0';
    signal west_btn : std_logic := '0';
    signal north_btn : std_logic := '0';
    signal south_btn : std_logic := '0';

    signal east_pulse : std_logic;
    signal south_pulse : std_logic;
    signal west_pulse : std_logic;
    signal north_pulse : std_logic;

    signal unlock_pattern : std_logic_vector(3 downto 0) := "1111";
    signal alarm_pattern : std_logic_vector(3 downto 0) := "0101";

    signal counter : integer := 0;
    
begin

    debounce0 : debounce port map(clk => clk, rst => rst, button => btn(0), result => east_btn);
    debounce1 : debounce port map(clk => clk, rst => rst, button => btn(1), result => south_btn);
    debounce2 : debounce port map(clk => clk, rst => rst, button => btn(2), result => west_btn);
    debounce3 : debounce port map(clk => clk, rst => rst, button => btn(3), result => north_btn);

    single_pulse_detector0 : single_pulse_detector port map(clk => clk, rst => rst, input_signal => east_btn, output_pulse => east_pulse);
    single_pulse_detector1 : single_pulse_detector port map(clk => clk, rst => rst, input_signal => south_btn, output_pulse => south_pulse);
    single_pulse_detector2 : single_pulse_detector port map(clk => clk, rst => rst, input_signal => west_btn, output_pulse => west_pulse);
    single_pulse_detector3 : single_pulse_detector port map(clk => clk, rst => rst, input_signal => north_btn, output_pulse => north_pulse);
    
    FSM_DIGITAL_LOCK : process (clk, rst)
    begin

        if rising_edge(clk) then
            if (guess = LOCK) then
                led <= "0000";
                if south_pulse = '1' then
                    guess <= S1;
                elsif east_pulse = '1' then
                    guess <= R1;
                elsif north_pulse = '1' or west_pulse = '1' then
                    guess <= W1;
                else
                    guess <= LOCK;
                end if;

            elsif guess = S1 then
                led <= "0001";
                if west_pulse = '1' then
                    guess <= S2;
                elsif east_pulse = '1' then
                    guess <= R2;
                elsif north_pulse = '1' or south_pulse = '1' then
                    guess <= W2;
                else
                    guess <= S1;
                end if;

            elsif guess = S2 then
                led <= "0011";
                if east_pulse = '1' then
                    guess <= S3;
                elsif north_pulse = '1' or west_pulse = '1' or east_pulse = '1'then
                    guess <= W3;
                else
                    guess <= S2;
                end if;

            elsif guess = S3 then
                led <= "0111";
                if east_pulse = '1' then
                    guess <= Reset;
                elsif west_pulse = '1' then
                    guess <= Unlock;
                elsif north_pulse = '1' or south_pulse = '1'then
                    guess <= Alarm;
                else
                    guess <= S3;
                end if;

            elsif guess = Unlock then
                led <= unlock_pattern;
                if north_pulse = '1' or east_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= LOCK;
                else
                    guess <= Unlock;
                end if;

            elsif guess = W1 then
                led <= "0001";
                if east_pulse = '1' then
                    guess <= R2;
                elsif north_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= W2;
                else
                    guess <= W1;
                end if;

            elsif guess = W2 then
                led <= "0011";
                if east_pulse = '1' then
                    guess <= R3;
                elsif north_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= W3;
                else
                    guess <= W2;
                end if;

            elsif guess = W3 then
                led <= "0111";
                if north_pulse = '1' or east_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= Alarm;
                else
                    guess <= W3;
                end if;

            elsif guess = Alarm then
                led <= alarm_pattern;
                if west_pulse = '1' then
                    guess <= A1;
                else
                    guess <= Alarm;
                end if;

            elsif guess = A1 then
                led <= alarm_pattern;
                if east_pulse = '1' then
                    guess <= Reset;
                elsif north_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= Alarm;
                else
                    guess <= A1;
                end if;

            elsif guess = R1 then
                led <= "0001";
                if east_pulse = '1' then
                    guess <= Reset;
                elsif north_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= W2;
                else
                    guess <= R1;
                end if;

            elsif guess = R2 then
                led <= "0011";
                if east_pulse = '1' then
                    guess <= Reset;
                elsif north_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= W3;
                else
                    guess <= R2;
                end if;

            elsif guess = R3 then
                led <= "0111";
                if east_pulse = '1' then
                    guess <= Reset;
                elsif north_pulse = '1' or west_pulse = '1' or south_pulse = '1' then
                    guess <= Alarm;
                else
                    guess <= R3;
                end if;

            elsif guess = Reset then
                led <= "0000";
                guess <= LOCK;
            else
                guess <= guess;
            end if;

        end if;
    end process;

    COUNTER_PROCESS : process (rst, clk)
    begin
        if (rst = '1') then
            counter <= 0;
        elsif rising_edge(clk) then
            if counter <= count_thresh then
                counter <= counter + 1;
            else
                counter <= 0;
                alarm_pattern <= not alarm_pattern;
                unlock_pattern <= not unlock_pattern;
            end if;
        end if;
    end process;

end Behavioral;