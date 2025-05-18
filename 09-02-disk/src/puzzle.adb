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
         File_Id_Max : Natural;
         File_Cand : Integer range -1..Integer'Last;
         Mem_Idx_Tmp : Natural range 1..Mem_Len;
         Mem_Idx_From : Natural range 1..Mem_Len;
         Mem_Idx_To : Natural range 1..Mem_Len;
         Mem_Idx   : Natural range 1..Mem_Len;
         Mem       : Array (Natural range 1..Mem_Len) of Integer range -1..Integer'Last := (Others => -1);
         Checksum  : Long_Integer;
         Success   : Boolean;
         Overflow  : Boolean;
         File_Size : Natural;
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
               File_Id_Max := File_Id;
               File_Id := File_Id + 1;
            else -- This is a skip
               --Put_Line (Item => "Y");
               Mem_Idx := Mem_Idx + Temp_Digit; -- Assumes odd length input strings
            end if;
         end loop;

         Dump;

         -- Work toward center "naive defragmenting" drive

         File_Id := File_Id_Max; -- Count down file IDs to 1
         Mem_Idx_To := 1;

         while File_Id > 0 loop
            -- Find the file ID
            Mem_Idx_From := 1;
            while Mem_Idx_From < Mem_Len and Mem(Mem_Idx_From) /= File_Id loop
               Mem_Idx_From := Mem_Idx_From + 1;
            end loop;

            -- Measure file size
            if Mem_Idx_From = Mem_Len then
               File_Size := 1;
            else
               File_Size := 0;
               for Mem_Idx in Mem_Idx_From..Mem_Len loop
                  if Mem(Mem_Idx) = File_Id then
                     File_Size := File_Size + 1;
                  else
                     exit;
                  end if;
               end loop;
            end if;

            -- Find a block of at least that size
            Mem_Idx_To := 1;
            Success := False;
            while not Success and Mem_Idx_To < Mem_Idx_From loop
               if Mem(Mem_Idx_To) >= 0 then -- Keep looking for a free space
                  Mem_Idx_To := Mem_Idx_To + 1;
               else
                  Mem_Idx := Mem_Idx_To;
                  Overflow := False;
                  while not Overflow and Mem_Idx <= (Mem_Idx_to + File_Size - 1) loop
                     if Mem(Mem_Idx) < 0 then
                        Mem_Idx := Mem_Idx + 1;
                     else
                        Overflow := True;
                        Mem_Idx_To := Mem_Idx + 1;
                     end if;
                  end loop;
                  if not Overflow then
                     Success := True;
                  end if;
               end if;
            end loop;

            if Success then
               Put_Line("File" & File_Id'Image & " len" & File_Size'Image & " move from" & Mem_Idx_From'Image & " to" & Mem_Idx_to'Image );

               for Mem_Idx in 1..File_Size loop
                  Mem(Mem_Idx_To + Mem_Idx - 1) := File_Id;
                  Mem(Mem_Idx_From + Mem_Idx - 1) := -1;
               end loop;
            else
               Put_Line("File" & File_Id'Image & " stay in place");
            end if;

            File_Id := File_Id - 1;
         end loop;

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

         -- Done; calculate checksum.

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
