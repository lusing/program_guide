-- 子库单元的体
package body Ch26_Support.Stats is
   function Average (A : Int_Array) return Integer is
      Sum : Integer := 0;
   begin
      for V of A loop
         Sum := Sum + V;
      end loop;
      return Sum / Integer (A'Length);
   end Average;

   function Max_Of (A : Int_Array) return Integer is
      M : Integer := Integer'First;
   begin
      for V of A loop
         if V > M then
            M := V;
         end if;
      end loop;
      return M;
   end Max_Of;
end Ch26_Support.Stats;
