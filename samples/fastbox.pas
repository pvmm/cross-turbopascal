PROGRAM example_FastBox;

BEGIN
  Screen(5);
  Actpage:=0;
  Atrbyt:=255;            {  (foreground * 16)+background }
  FastBox(10,30,250,190);
  READLN;                 { wait for return }
  Screen(0);
END.
