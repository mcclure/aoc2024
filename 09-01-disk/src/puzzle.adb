with Ada.Text_IO; use Ada.Text_IO;
with Ada.Task_Identification; use Ada.Task_Identification;
with Ada.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

procedure Puzzle is
   package CLI renames Ada.Command_Line;
      F           : File_Type;
      Line        : String(1..20001); -- Will fail on inputs over 20k chars
      Last        : Natural;
      I           : Natural;
      Mem_Len_Tmp : Natural;
      Temp_Digit  : Natural;
      procedure Run(Mem_Len : Natural) is
         Mem       : Array (Natural range 1..Mem_Len) of Integer range -1..Integer'Last;
      begin
         Put_Line (Item => "Done");
      end;
begin
   -- if CLI.Argument_Count /= 1 then
   --    Put_Line (Standard_Error, "** Expected filename as argument.");
   --    CLI.Set_Exit_Status( 1 );
   --    Abort_Task (Current_Task);
   -- end if;

   -- -- Is there a version of Get_Line that works on a filehandle, I didn't find it :(
   -- Open (F, In_File, CLI.Argument(1));
   Get_Line(Line, Last);
   -- if not Done then
   --    Put_Line (Standard_Error, "** Expected file to be one line long.");
   --    CLI.Set_Exit_Status( 1 );
   --    Abort_Task (Current_Task);
   -- end if;
   -- Close (F);

   Put_Line (Item => "Line len: " & Last'Image);

   Mem_Len_Tmp := 0;
   for I in 1..Last loop
      Temp_Digit := Character'Pos(Line(I)) - Character'Pos('0');
      Mem_Len_Tmp := Mem_Len_Tmp + Temp_Digit;
   end loop;
   Put_Line (Item => "Mem len:  " & Natural'Image( Mem_Len_Tmp ) );

   -- Start process
   Run(Mem_Len_Tmp);
end Puzzle;
