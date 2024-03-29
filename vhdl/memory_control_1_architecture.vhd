-------------------------------------------------------------------------------
-- Design: Memory Control 1 Architecture                                     --
--                                                                           --
-- Author : Sebastian Dichler                                                --
-- Date : 22.05.2018                                                         --
-- File : memory_control_1_architecture.vhd                                  --
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

architecture memory_control_1_architecture of memory_control_1_entity is
	-- Import MEM1 ROM (generated via Xilinx Vivado IP Catalog/Block Memory Generator)
	component rom_mem1 is
	port (	clka	:  in std_logic;
					addra	:  in std_logic_vector(16 downto 0);
					douta	: out std_logic_vector(11 downto 0));
	end component;

	constant H_VISIBLE_AREA			: std_logic_vector(9 downto 0) := "1010000000";					-- Visible Area					| 640
	constant V_VISIBLE_AREA			: std_logic_vector(9 downto 0) := "0111100000";					-- Visible Area					| 480
	constant H_VISIBLE_AREA_12	: std_logic_vector(9 downto 0) := "0101000000";					-- 1/2 of Visible Area	| 320
	constant ROM_MAX_VALUE			: std_logic_vector(16 downto 0) := "10010101111111111";	-- Rom max addr value		| 76799

	signal s_rom_current_val	: std_logic_vector(16 downto 0);			-- Rom Current Value - saves the  rom addressvalue if H-Sync Counter reaches 320
	signal s_rom_addr					: std_logic_vector(16 downto 0);			-- Internal Address Signal
	signal s_rom_dout					: std_logic_vector(11 downto 0);			-- Internal Data Signal
	signal s_rgb							: std_logic_vector(11 downto 0);			-- Internal RGB Signal

begin

	i_rom_mem1 : rom_mem1
	port map(	clka		=> clk_i,
						addra		=> s_rom_addr,
						douta		=> s_rom_dout);

	-----------------------------------------------------------------------------
	-- Increment ROM Address if we are in Visible Area
	-----------------------------------------------------------------------------
	p_counter : process(clk_i, reset_i)
	begin
		if reset_i = '1' then
			-- Reset System
			s_rom_current_val <= "00000000000000000";
			s_rom_addr <= "00000000000000000";

		elsif clk_i'event and clk_i = '1' then
			-- If Counter for V-Sync is less or equals the V-Sync Visible area
			if v_sync_counter_i < V_VISIBLE_AREA then
				-- If Counter for H-Sync is less or equals the H-Sync Visible area
				if h_sync_counter_i <= H_VISIBLE_AREA then
					-- If H-Sync Counter euqlas the Start
					if h_sync_counter_i = "0000000001" then
						-- Set Rom Address to last addressvalue
						s_rom_addr <= s_rom_current_val;
					-- If H-Sync Counter euqals 1/2 of Visible area
					elsif h_sync_counter_i = H_VISIBLE_AREA_12 then
						s_rom_addr <= s_rom_current_val;
					-- If H-Sync Counter quals the Visible area
					elsif h_sync_counter_i = H_VISIBLE_AREA then
						s_rom_current_val <= s_rom_addr;
					end if;

					-- If 25Mhz Enable Signal is high
					if en_25mhz_i = '1' then
						-- If Rom Address is on max value reset it otherwise increment it with 1
						if s_rom_addr = ROM_MAX_VALUE then
							s_rom_addr <= "00000000000000000";
						else
							s_rom_addr <= unsigned(s_rom_addr) + '1';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process p_counter;

	-----------------------------------------------------------------------------
	-- Put Data from ROM to RGB Output
	-----------------------------------------------------------------------------
	p_data : process(clk_i, reset_i)
	begin
		if reset_i = '1' then
			-- Reset System
			s_rgb <= "000000000000";

		elsif clk_i'event and clk_i = '1' then
			-- RGB Output is always low if we are not in the visible area
			s_rgb <= "000000000000";
			-- If Counter for V-Sync is less or equals the V-Sync Visible area
			if v_sync_counter_i <= V_VISIBLE_AREA then
				-- If Counter for H-Sync is less or equals the H-Sync Visible area
				if h_sync_counter_i <= H_VISIBLE_AREA then
					s_rgb <= s_rom_dout;
				end if;
			end if;
		end if;
	end process p_data;

	rgb_o <= s_rgb;
end memory_control_1_architecture;
