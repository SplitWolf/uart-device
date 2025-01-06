--------------------------------------------------------------------------------
-- Title         : Clock Divider Circuit
-- Project       : VHDL Example Programs
-------------------------------------------------------------------------------
-- File          : clk_div.vhd
-- Author        : Rami Abielmona  <rabielmo@site.uottawa.ca>
-- Created       : 2004/10/07
-- Last modified : 2007/09/26
-------------------------------------------------------------------------------
-- Description : This file creates a clock divider circuit using a behavioral approach.
--		 		 The code is extracted from "Rapid Prototyping Of Digital Systems" 
--				 by James Hamblen et Michael Furman.
-------------------------------------------------------------------------------
-- Modification history :
-- 2004.10.07 	R. Abielmona		Creation
-- 2007.09.26 	R. Abielmona		Modified copyright notice
-------------------------------------------------------------------------------
-- This file is copyright material of Rami Abielmona, Ph.D., P.Eng., Chief Research
-- Scientist at Larus Technologies.  Permission to make digital or hard copies of part
-- or all of this work for personal or classroom use is granted without fee
-- provided that copies are not made or distributed for profit or commercial
-- advantage and that copies bear this notice and the full citation of this work.
-- Prior permission is required to copy, republish, redistribute or post this work.
-- This notice is adapted from the ACM copyright notice.
--------------------------------------------------------------------------------
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY clk_div41 IS
	PORT
	(
		clock_25Mhz	   : IN	STD_LOGIC;
		clock_304878Hz : OUT STD_LOGIC
    );
END clk_div41;

ARCHITECTURE a OF clk_div41 IS

	SIGNAL	count_div41: STD_LOGIC_VECTOR(7 DOWNTO 0); 
	SIGNAL  clock_304878Hz_int: STD_LOGIC; 

BEGIN
	PROCESS 
	BEGIN
-- Divide by 25
		WAIT UNTIL clock_25Mhz'EVENT and clock_25Mhz = '1';
			IF count_div41 < 40 THEN
                count_div41 <= count_div41 + 1;
			ELSE
                count_div41 <= "00000000";
			END IF;
			IF count_div41 < 20 THEN
                clock_304878Hz_int <= '0';
			ELSE
                clock_304878Hz_int <= '1';
			END IF;	
-- Ripple clocks are used in this code to save prescalar hardware
-- Sync all clock prescalar outputs back to master clock signal
            clock_304878Hz <= clock_304878Hz_int;
	END PROCESS;	

END a;

