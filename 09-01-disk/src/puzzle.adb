with Ada.Text_IO; use Ada.Text_IO;
with Ada.Task_Identification; use Ada.Task_Identification;
with Ada.Command_Line;

procedure Puzzle is
   package CLI renames Ada.Command_Line;
      F         : File_Type;
begin
   if CLI.Argument_Count /= 1 then
      Put_Line (Standard_Error, "** Expected filename as argument.");
      CLI.Set_Exit_Status( 1 );
      Abort_Task (Current_Task);
   end if;

   Put_Line (Item => "Argument Count:" & CLI.Argument_Count'Img);
end Puzzle;
