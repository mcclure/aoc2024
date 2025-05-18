with Ada.Text_IO; use Ada.Text_IO;
with Ada.Task_Identification; use Ada.Task_Identification;
with Ada.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

procedure Puzzle is
   package CLI renames Ada.Command_Line;
      F           : File_Type;
      Line        : String(1..20001); -- Will fail on inputs over 20k chars
      Line_Last   : Natural;
      I           : Natural;
      Mem_Len_Tmp : Natural;
      Temp_Digit  : Natural;
      procedure Run(Mem_Len : Natural) is
         Line_Idx  : Natural range 1..20001;
         File_Id   : Natural;
         File_Cand : Integer range -1..Integer'Last;
         Mem_Idx_Tmp : Natural range 1..Mem_Len;
         Mem_Idx_From : Natural range 1..Mem_Len;
         Mem_Idx_To : Natural range 1..Mem_Len;
         Mem_Idx   : Natural range 1..Mem_Len;
         Mem       : Array (Natural range 1..Mem_Len) of Integer range -1..Integer'Last := (Others => -1);
         Checksum  : Long_Integer;
         procedure Dump is
         begin
            -- Print data back out
            for Mem_Idx in 1..Mem_Len loop
               --Put( Item => "(" & Natural'Image(Mem_Idx) & ")" );
               File_Cand := Mem(Mem_Idx);
               if File_Cand >= 0 then
                  Put( Item => Integer'Image(File_Cand mod 10) );
               else
                  Put( Item => " _" );
               end if;
            end loop;
            Put_Line("");
         end;
      begin
         -- Actual program here
         File_Id := 0;
         Mem_Idx := 1;

         -- Populate Mem based on instructions in Line
         for Line_Idx in 1..Line_Last loop
            -- One digit of line
            Temp_Digit := Character'Pos(Line(Line_Idx)) - Character'Pos('0');

            --Put_Line (Item => "Bump" & Natural'Image(Mem_Idx) & " + " & Natural'Image(Temp_Digit));

            if Line_Idx mod 2 = 1 then -- This is a block
               if Mem_Idx = 1 then -- This horrible thing so I can iterate without hitting 0 or +1 
                  Mem_Idx_From := 1;
                  Mem_Idx_To := Mem_Idx + Temp_Digit - 1;
               else
                  Mem_Idx_From := Mem_Idx + 1;
                  Mem_Idx_To := Mem_Idx + Temp_Digit;
               end if;
               -- Iterate over block filling out File Id
               for Mem_Idx_Tmp in Mem_Idx_From..Mem_Idx_To loop
                  --Put_Line (Item => "X " & Natural'Image(Mem_Idx_Tmp));
                  Mem(Mem_Idx_Tmp) := File_Id;
                  Mem_Idx := Mem_Idx_Tmp;
               end loop;

               -- Need a new file id
               File_Id := File_Id + 1;
            else -- This is a skip
               --Put_Line (Item => "Y");
               Mem_Idx := Mem_Idx + Temp_Digit; -- Assumes odd length input strings
            end if;
         end loop;

         Dump;

         -- Work toward center "ugly defragmenting" drive

         Mem_Idx_To := 1;
         Mem_Idx_From := Mem_Len;

         while Mem_Idx_From > 1 and Mem_Idx_To < Mem_Idx_From loop
            while Mem(Mem_Idx_To) >= 0 and Mem_Idx_To < Mem_Len loop -- Find blank space
               Mem_Idx_To := Mem_Idx_To + 1;
            end loop;

            if Mem_Idx_To < Mem_Idx_From then
--               Put_Line("MOVE" & Integer'Image(Mem_Idx_From) & " TO " & Integer'Image(Mem_Idx_To));
               Mem(Mem_Idx_To) := Mem(Mem_Idx_From);
               Mem(Mem_Idx_From) := -1;
            end if;

            while Mem(Mem_Idx_From) < 0 and Mem_Idx_From > 1 loop
               Mem_Idx_From := Mem_Idx_From - 1;
            end loop;
         end loop;

         Dump;

         Checksum := 0;

         for Mem_Idx in 1..Mem_Len loop
            File_Cand := Mem(Mem_Idx);
            if File_Cand >= 0 then
               Checksum := Checksum + Long_Integer(File_Cand)*Long_Integer(Mem_Idx-1);
            end if;
         end loop;

         Put_Line("");
         Put_Line(Long_Integer'Image(Checksum));

         --Put_Line (Item => "Done" & Natural'Image(Mem_Len_Tmp));
      end;
begin
   -- Input data from STDIN

   Get_Line(Line, Line_Last);

   Put_Line (Item => "Line len: " & Line_Last'Image);

   -- Figure out needed size for data
   Mem_Len_Tmp := 0;
   for I in 1..Line_Last loop
      Temp_Digit := Character'Pos(Line(I)) - Character'Pos('0');
      Mem_Len_Tmp := Mem_Len_Tmp + Temp_Digit;
      --Put_Line (Item => "Buff" & Natural'Image(Temp_Digit) & " =" & Natural'Image(Mem_Len_Tmp));
   end loop;
   Put_Line (Item => "Mem len:  " & Natural'Image( Mem_Len_Tmp ) );

   -- Start process
   Run(Mem_Len_Tmp);
end Puzzle;
