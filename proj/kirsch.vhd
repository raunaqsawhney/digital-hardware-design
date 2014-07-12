
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity kirsch is
  port(
    ------------------------------------------
    -- main inputs and outputs
    i_clock    : in  std_logic;                      
    i_reset    : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  std_logic_vector(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out std_logic_vector(2 downto 0);                      
    o_mode     : out std_logic_vector(1 downto 0);
    o_row      : out std_logic_vector(7 downto 0);
    ------------------------------------------
    -- debugging inputs and outputs
    debug_key      : in  std_logic_vector( 3 downto 1) ; 
    debug_switch   : in  std_logic_vector(17 downto 0) ; 
    debug_led_red  : out std_logic_vector(17 downto 0) ; 
    debug_led_grn  : out std_logic_vector(5  downto 0) ; 
    debug_num_0    : out std_logic_vector(3 downto 0) ; 
    debug_num_1    : out std_logic_vector(3 downto 0) ; 
    debug_num_2    : out std_logic_vector(3 downto 0) ; 
    debug_num_3    : out std_logic_vector(3 downto 0) ; 
    debug_num_4    : out std_logic_vector(3 downto 0) ;
    debug_num_5    : out std_logic_vector(3 downto 0) 
    ------------------------------------------
  );  
end entity;


architecture main of kirsch is
begin  

  debug_num_5 <= X"E";
  debug_num_4 <= X"C";
  debug_num_3 <= X"E";
  debug_num_2 <= X"3";
  debug_num_1 <= X"2";
  debug_num_0 <= X"7";

  debug_led_red <= (others => '0');
  debug_led_grn <= (others => '0');

  -- Custom Functions
  function "rol" (a : std_logic_vector; n : natural)
    return std_logic_vector
  is
  begin
    return std_logic_vector(unsigned(a) rol n);
  end function;

  function "max" (a : std_logic_vector; b : std_logic_vector)
    return std_logic_vector
  is
  begin
      if (a > b) then 
          return a;
      else
          return b;
      end if;
  end function;
  
  -- Defined Signals
  signal col        :   unsigned(2 downto 0);
  signal row        :   unsigned(2 downto 0);
  signal mem_wren   :   std_logic_vector(2 downto 0);
  signal mem_data   :   std_logic_vector(7 downto 0);
  signal count      :   unsigned(15 downto 0);
  signal busy       :   std_logic;
  signal a, b, c, d, e, f, g, h, i     : std_logic_vector(7 downto 0);
  signal v          :   std_logic_vector(4 downto 0);
  signal current_row:   std_logic_vector(3 downto 0);
  signal direction  :   std_logic_vector(3 downto 0);
 
	-- Definining Convolation Table
	--  -------------------
	--  |	a		|	b		|	c		|
	--	|			|			|			|
	--	|	h		|	i		|	d		|
	--	|			|			|			|
	--	|	g		|	f		|	e		|
	--	|			|			|			|
	--	-------------------
  
	-- A simple 2d array for VHDL
	-- Usage: array_name(0,0) <= 1000;
	type two_dim_arr is array (0 to 2, 0 to 2) of integer range 0 to 400;
	signal conv_table: two_dim_arr;

	-- Signal Help:
	-- row = row index of input image
	-- col = col index of input image
	-- m = 
	-- n = 
	signal row, col, m, n : natural 
	-- to signal pass across first two rows
	signal first_pass : natural 

	-- simar
	-- Memory Process
	process (i_clock) 
	begin
		for row = 0 to 255 {
			for col = 0 to 255 {
				for m = 0 to 2 {
					for n = 0 to 2 {
						wait until rising_edge(i_clock);
						if (i_valid = '1') then
							mem (row) <= i_pixel;
						if ( (row > 1) AND (col > 1) AND first_pass = '1') then
							 
					}
				}
			}
		} 
		
	-- Direction LUT --
  -- 000    E
  -- 001    W
  -- 010    N
  -- 011    S
  -- 100    NW
  -- 101    SE
  -- 110    NE
  -- 111    SW
  -------------------

  -- Registers
  -- Stage 1 Inputs
  signal r0, r1, r2, r3, r4, r5, r6, r7     : std_logic_vector(7 downto 0); 
   
  -- Stage 1 Data (also used Stage 2 Inputs)
  signal max_sum0, max_sum1, max_sum2, max_sum3 : std_logic_vector(9 downto 0);  
  signal sum0, sum1, sum2, sum3     : std_logic_vector(8 downto 0);
  -- Total Registers: 16

  -- Memory Array
  type mem_array is array (2 downto 0) of std_logic_vector(7 downto 0);
  signal mem_out    :   mem_array;
  
  -- Memories
  mem0  :   entity work.mem(main)
    port map (
        address => col,
        clock   => i_clock,
        data    => mem_data,
        wren    => mem_wren(0),
        q       => mem_out(0) 
    );

  mem1  :   entity work.mem(main)
    port map (
        address => col,
        clock   => i_clock,
        data    => mem_data,
        wren    => mem_wren(1),
        q       => mem_out(1)
    );

  mem2  :   entity work.mem(main)
    port map (
        address => col,
        clock   => i_clock,
        data    => mem_data,
        wren    => mem_wren(2),
        q       => mem_out(2)
    );

  -- Valid Bit Generator
  v(0) <= i_valid;
  v_gen : for i in 1 to 4 generate
      process begin
          wait until rising_edge(i_clock);
          v(i) <= '0';
      end process;
  end generate;

  -- Initialize System
  process begin
      wait until rising_edge(i_clock);

        if (i_reset = '1') then
            count        <= '0;
            col          <= '0';
            row          <= '0';
            busy         <= '0';
            current_row   <= "001";
        else
            if (i_valid = '1') then
                busy    <= '1';
                col     <= col + 1;
                if (col = '255') then
                    current_row <= current_row rol 1;
                    if (row = '255') then
                        busy = '0';
                    else
                        row <= (row + 1);
                    end if;
                end if;
            end if;
        end if;
  end process;

  -- System Modes
  process begin
      if (i_reset = '1') then
          o_mode <= '01';
      elsif (busy = '1') then
          o_mode <= '10';
      else 
          o_mode <= '11';
      end if;
  end process;

  -- Populate Memory
  process begin
      wait until rising_edge(i_clock);
      if (v(0) = '1') then
          case current_row is
              when "001" =>
                  mem_wren(1) <= '1';
                  mem_data    <= i_pixel;
              when "010" =>
                  mem_wren(2) <= '1';
                  mem_data    <= i_pixel;
              when "100" =>
                  mem_wren(3) <= '1';
                  mem_data    <= i_pixel;
              when others =>
                  mem_wren    <= x"00";
                  mem_data    <= i_pixel;
        end case;
        mem_wren    <= x"00";
    end if;
  end process;

end architecture;
