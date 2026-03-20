library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal and constnat declarations
    constant k_IO_WIDTH : natural := 4;
    constant k_clk_period : time := 10 ns;
   	
   	
   	signal w_clk_0, w_clk_1, w_reset_1, w_reset_2 : std_logic := '0';
	signal w_D3, w_D2, w_D1, w_D0, f_data : std_logic_vector(k_IO_WIDTH -1 downto 0) := (others => '0');
    signal f_sel_n : std_logic_vector(3 downto 0);

    
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
    clkdiv_inst_0 : clock_divider
        generic map (k_DIV => 25000000)
        port map (
            i_clk => clk,
            i_reset => w_reset_2,
            o_clk => w_clk_0
        );
        
    clkdiv_inst_1 : clock_divider
        generic map (k_DIV => 200000)
        port map (
            i_clk => clk,
            i_reset => w_reset_2,
            o_clk => w_clk_1
        );
        
    TDM4_inst : TDM4
        generic map (k_WIDTH => k_IO_WIDTH)
        port map (
           i_clk   => w_clk_1,
           i_reset => btnU,
           i_D3    => w_D3,
           i_D2    => w_D2,
           i_D1    => w_D1,
           i_D0    => w_D0,
           o_data  => f_data,
           o_sel => f_sel_n
        );
	
	elevator_controller_fsm_0 : elevator_controller_fsm port map (
		i_clk     => w_clk_0,
		i_reset   => w_reset_1,
		is_stopped    => sw(0),
		go_up_down => sw(1),
		o_floor   =>  w_D0
	);
	
	elevator_controller_fsm_1 : elevator_controller_fsm port map (
		i_clk     => w_clk_0,
		i_reset   => w_reset_1,
		is_stopped    => sw(15),
		go_up_down => sw(14),
		o_floor   => w_D2
	);
	
	sevenseg_decoder_0 : sevenseg_decoder
	port map (
	   i_hex => f_data,
	   o_seg_n => seg
	);
	-- CONCURRENT STATEMENTS ----------------------------
	w_reset_1 <= btnU or btnR; -- FSM
    w_reset_2 <= btnU or btnL; -- Clock
    w_D3 <= "1111";
    w_D1 <= "1111";
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	an <= f_sel_n;
	led(15) <= w_clk_0;
	led(14 downto 0) <= (others => '0');
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
