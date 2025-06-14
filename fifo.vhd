library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO is
    generic( B : natural := 9 ; --bits
             W : natural := 2   -- address bits
            );
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           rd : in STD_LOGIC;
           wr : in STD_LOGIC;
           w_data : in STD_LOGIC_VECTOR (B-1 downto 0);
           r_data : out STD_LOGIC_VECTOR (B-1 downto 0);
           empty : out STD_LOGIC;
           full : out STD_LOGIC;
           ERROR : out STD_LOGIC);
end FIFO;

architecture Behavioral of FIFO is
    type reg_file_type is array (2**W-1 downto 0) of std_logic_vector (B-1 downto 0);
    signal array_reg : reg_file_type;
    signal w_ptr_reg, w_ptr_next, w_ptr_succ : std_logic_vector(W-1 downto 0);
    signal r_ptr_reg, r_ptr_next, r_ptr_succ : std_logic_vector(W-1 downto 0);
    signal full_reg, full_next, empty_reg, empty_next : std_logic;
    signal wr_op : std_logic_vector (1 downto 0);
    signal wr_en : std_logic;
    signal rd_wr_enable : std_logic;
    signal error_reg, error_next : STD_LOGIC;   
begin
    -- Register file
    reg_file : process (clk, reset)
    begin 
        if (reset = '1') then 
            array_reg <= (others => (others => '0'));
        elsif (rising_edge(clk)) then 
            if wr_en = '1' then 
                array_reg(to_integer(unsigned(w_ptr_reg))) <= w_data;
            end if;
        end if;                
    end process;
    
    -- Read port
    r_data <= array_reg(to_integer(unsigned(r_ptr_reg)));
    
    -- Write enable only when FIFO is not full           
    wr_en <= '1' when rd_wr_enable = '1' else wr and (not full_reg);
    
    -- FIFO controller
    reg_rd_wr_PTR : process (clk, reset)
    begin 
        if (reset = '1') then
            w_ptr_reg <= (others => '0');
            r_ptr_reg <= (others => '0');
            full_reg <= '0';
            empty_reg <= '1';
            error_reg <= '0'; 
        elsif (rising_edge(clk)) then 
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
            error_reg <= error_next;          
        end if;     
    end process;
    
    -- Successive pointer values
    w_ptr_succ <= std_logic_vector(unsigned(w_ptr_reg) + 1); 
    r_ptr_succ <= std_logic_vector(unsigned(r_ptr_reg) + 1);
    
    -- Next state logic for read and write pointers
    wr_op <= wr & rd; -- read write status
    next_state_logic : process (w_ptr_reg, w_ptr_succ, r_ptr_reg, r_ptr_succ, wr_op, empty_reg, full_reg)
    begin
        w_ptr_next <= w_ptr_reg;
        r_ptr_next <= r_ptr_reg;
        full_next <= full_reg;
        empty_next <= empty_reg;
        rd_wr_enable <= '0';
        error_next <= '0';
        
        case wr_op is 
            when "00" => -- no op
                null;
            when "01" => -- read only
                if (empty_reg /= '1') then -- not empty
                    r_ptr_next <= r_ptr_succ;
                    full_next <= '0';
                    if (r_ptr_succ = w_ptr_reg) then 
                        empty_next <= '1';
                    end if;
                end if;
            when "10" => -- write only
                if (full_reg /= '1') then -- not full
                    w_ptr_next <= w_ptr_succ;
                    empty_next <= '0';
                    if (w_ptr_succ = r_ptr_reg) then 
                        full_next <= '1';
                    end if;
                end if;
            when "11" => -- simultaneous write and read
                if (empty_reg /= '1' and full_reg /= '1') then
                    -- Both operations valid
                    w_ptr_next <= w_ptr_succ;
                    r_ptr_next <= r_ptr_succ;
                    rd_wr_enable <= '1';
                elsif (empty_reg = '1' and full_reg /= '1') then
                    -- Only write valid
                    w_ptr_next <= w_ptr_succ;
                    empty_next <= '0';
                    rd_wr_enable <= '1';
                elsif (full_reg = '1' and empty_reg /= '1') then
                    -- Only read valid  
                    r_ptr_next <= r_ptr_succ;
                    full_next <= '0';
                end if;
            when others => 
                error_next <= '1';          
        end case;
    end process;
    
    -- Output assignments
    full <= full_reg;
    empty <= empty_reg;
    ERROR <= error_reg;
end Behavioral;
