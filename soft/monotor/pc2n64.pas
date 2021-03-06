unit pc2n64;
{****************************************************************************}
{ Russia Omsk REMIS Lab }
{ Monitor unloader PC with n64   }
{ VAP }
{****************************************************************************}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    term: TListBox;
    command: TEdit;
    wcf: TCheckBox;
    wdf: TCheckBox;
    creset: TCheckBox;
    pc: TCheckBox;
    ProgressBar: TProgressBar;
   procedure commandKeyPress(Sender: TObject; var Key: Char);
   procedure syntax( cmd : string );
   procedure dump_ram ;
   procedure cmd_reset ;
   procedure cmd_help;
   function InP(A : word): byte;
   procedure OutP(A  : word ; D: word);
   procedure epp_write (R : byte ; D: byte);
   function epp_read (R  : byte): byte;
   procedure cmd_load;
   procedure cmd_addres;
   procedure cmd_aread;
   procedure wr_a(A: integer);
   function rd_a : integer;
   procedure cmd_mon;
   procedure cmd_moff;
   procedure cmd_stat;
   procedure prn(line: string);
   procedure cmd_send;
   procedure cmd_read;
   procedure dump_n64;
   procedure cmd_sx;
   procedure cmd_test;
   procedure cmd_cmp;
   procedure cmd_fill;
   procedure fill(b: byte);
   procedure fill_i(b: byte);
   procedure fill_rnd;
   procedure set_mode;
   procedure cmd_mode;
   procedure cmd_i;
   procedure cmd_o;
   procedure cmd_run;

  private
    { Private declarations }
  public
    { Public declarations }

end;
const base = $378;
const rga = 3 ; rgd = 4; rgc = 2; rg_stat = 1;
var
  Form1: TForm1;
  param: array[1..10] of string;
  paramd: array[1..10] of integer;
  buffer: array [0..$7FFFFF] of byte;
  sizef,sizef1: integer;
  line_com : string;
  mode: byte;
implementation

{$R *.DFM}

{*************************************************************************}
{ Func to ports acces  }
{*************************************************************************}
function TForm1.InP(A : Word): byte;

asm
   MOV    DX,A
   IN     AL,DX
end;

procedure TForm1.OutP(A  : word; D: word);

asm
   MOV    AX,D
   MOV    DX,A
   OUT    DX,AL
end;

procedure TForm1.epp_write (R : byte ; D: byte);

begin
OutP ( base + rga, R);
OutP ( base + rgd, D);
end;

function TForm1.epp_read (R  : byte): byte;

begin
OutP ( base + rga , R);
epp_read := InP ( base + rgd );
end;

{*************************************************************************}
{ Editor command line }
{*************************************************************************}

procedure TForm1.commandKeyPress(Sender: TObject; var Key: Char);
var
char_sec,char_max,par_num : integer;
err : integer;
hex_val: string;
cmd: string;

begin

  if key = #$0d then
  begin
    { clear command line   }
    if command.text = '' then
    begin
         command.text:= line_com;
    end
    else
    begin
        line_com := command.Text;
    end;
    command.text := '';
    { print to terminal }
    prn(line_com);
    { clear parameters}
    param[1]:='';
    par_num :=2;
    while par_num < 11 do
    begin
         param[par_num] := '';
         par_num := par_num +1 ;
    end;

    { convert string to parameters }
    par_num := 1;
    char_max:=length(line_com);
    char_sec:= 1;
    while char_sec <= char_max do
    begin
         if line_com[char_sec] <> ' ' then
         begin
              param[par_num]:= param[par_num] +  line_com[char_sec];
              char_sec:= char_sec +1;
         end
         else
         begin
              par_num:= par_num + 1;
              char_sec:= char_sec +1;
              while ( line_com[char_sec] = ' ' ) and ( char_sec <= char_max ) do
              begin
                  char_sec:= char_sec +1;
              end
         end;
    end;

{ Convert numbers to parameters}
    par_num :=1;
    while par_num < 11 do
    begin
         val( '$'+ param[par_num],paramd[par_num],err);

         hex_val := inttohex(paramd[par_num],8);
         par_num := par_num +1 ;
    end;
    cmd:= param[1];
    syntax (cmd );
    cmd_stat;

  end;
end; { Func}

{*************************************************************************}
{ help }
{*************************************************************************}
procedure TForm1.cmd_help;
var
dir_path: string;

begin
    prn('Programm monitor of PV-Backup ');
    prn('Omsk Russia  1999 REMIS Lab');
     prn('?                 This help' );
     prn('dr    $adres      dump ram PC' );
     prn('d     $adres      dump dramm n64' );
     prn('res               Reset' );
     prn('ld    Name_f      Load file');
     prn('r     Name_f      Run file ( Load and Send )');
     prn('ar                Read address register' );
     prn('a     $adres      Set address register' );
     prn('pc                PC mode' );
     prn('n64               n64 mode' );
     prn('stat              Status' );
     prn('send  $a $size    Send to n64' );
     prn('read  $a $size    receive from n64' );
     prn('sx    $a $size    Send to dram n64 w/o check' );
     prn('cmp   $a $size    compare dramm n64 and ram PC' );
     prn('f     $a $size $d Fill dramm n64' );
     prn('test              Test dramm' );
     prn('mode  we ce gm    Set mode' );
    getdir(0,dir_path);
    prn( ' Second dir ' + dir_path );
end;
{*************************************************************************}
{ Dump memory}
{*************************************************************************}
procedure TForm1.dump_ram();
var
a, x , y : integer;
ls : string;

begin
     a:= paramd[2];
     y:=0;
     while y < 8 do
     begin
          ls:= inttohex(a,8)+' : ';
          x:=0;
          while x<8 do
          begin
               ls:= ls + inttohex( (buffer[a+1]*256+buffer[a]) , 4) + ' ';
               a:=a+2;
               inc(x);
          end;
          prn(ls);
          inc(y);
     end;
end;

procedure TForm1.dump_n64();
var
a, x , y : integer;
ls : string;
d: integer;

begin
     a:= paramd[2];
     wr_a(a);
     y:=0;
     while y < 8 do
     begin
          ls:= inttohex(a,8)+' : ';
          x:=0;
          while x<8 do
          begin
               d:=epp_read(4);
               d:= d + epp_read(4)*256;

               ls:= ls + inttohex( d , 4) + ' ';
               a:=a+2;
               inc(x);
          end;
          prn(ls);
          inc(y);
     end;
end;

{*************************************************************************}
{ Adres register control }
{*************************************************************************}
procedure TForm1.cmd_aread();
var
addres: integer;
addresH: string;
begin
     addres:= rd_a;
     prn( inttohex(addres,8) ) ;
end;

procedure TForm1.cmd_addres();
begin
     wr_a(paramd[2]);
     prn( inttohex(rd_a,8) ) ;
end;

procedure TForm1.wr_a (A: integer );
var
b : byte;
begin
     b:= A mod 256;
     A:= A div 256;
     epp_write(0,b);
     b:= A mod 256;
     A:= A div 256;
     epp_write(1,b);
     b:= A mod 256;
     A:= A div 256;
     epp_write(2,b);
     b:= A mod 256;
     A:= A div 256;
     epp_write(3,b);
end;

function TForm1.rd_a():integer;
begin
     rd_a:= epp_read(0) +  epp_read(1) * $100 + epp_read(2) * $10000 + epp_read(3) * $1000000;
end;


procedure TForm1.cmd_i();
begin
     prn(inttohex(epp_read(4),2));
end;

procedure TForm1.cmd_o();
begin
     epp_write(4,paramd[2]);
     prn(inttohex(rd_a,2) + '  '+ inttohex(paramd[2],2));
end;
{*************************************************************************}
{ Reset }
{*************************************************************************}
procedure TForm1.cmd_reset();
var
Time,delay: integer;

begin
     OutP(base + rgc , $0);
     Time:=1;
     while Time < 100000 do
     begin
      delay:= delay+1;
      Time:=Time+1;
     end;
     OutP(base +rgc, $4);
     cmd_stat;
End;

procedure TForm1.cmd_mon();
begin
     OutP(base + rg_stat,1);
     mode:=mode or $1;
     set_mode;
end;

procedure TForm1.cmd_moff();
begin
     mode:= mode and $FE;
     set_mode;
end;

procedure TForm1.cmd_mode();
var
n:integer;
begin
     n:=1;
     mode:=mode and $10;
     while n<4 do
     begin
          if param[n] = 'db' then mode:=$6;
          if param[n] = 'dp' then mode:=$4;
          if param[n] = 'rp' then mode:=$22;
          inc(n);
     end;
     set_mode;
end;

Procedure TForm1.set_mode();
begin
     epp_write(5,mode);
end;

Procedure TForm1.cmd_stat();
var
stat:byte;
begin
     stat:= epp_read(3);

     if stat and $80 > 0 then creset.Checked := true else creset.Checked:= false;
     if stat and $20 > 0 then wcf.Checked := true else wcf.Checked:= false;
     if stat and $40 > 0 then wdf.Checked := true else wdf.Checked:= false;
     if stat and $10 > 0 then pc.Checked := true else pc.Checked:= false;
end;

{*************************************************************************}
{ Reading file }
{*************************************************************************}
procedure TForm1.cmd_run();
begin
     cmd_load;
     paramd[2]:=0;paramd[3]:=0;
     cmd_mon;
     cmd_send;
     cmd_moff;
end;

procedure TForm1.cmd_load();
var
NumReaded : integer;
IsFile: boolean;
namef: string;
dfile: file ;
a:     integer;
b:     byte;
begin
     namef:= param[2] + '.v64';
     prn('Loading File : ' + namef );
     AssignFile ( dfile, namef);
     try
        Reset ( dfile, 1);
        IsFile := True;
     except
        IsFile := false;
     end;
     if IsFile then
     begin
           sizef:=SizeOf(Buffer);
           BlockRead( dfile, Buffer, Sizef, NumReaded);
           prn( IntToStr( NumReaded ));
     end
     else
     begin
         prn(' ���� �����������');
     end;
     sizef:=NumReaded;
     closefile ( dfile);
     if buffer[0] = $80 then
     begin
         a:=0;
         while a<NumReaded do
         begin
              b:=buffer[a];
              buffer[a]:=buffer[a+1];
              inc(a);
              buffer[a]:=b;
              inc(a);
         end;
     end;
End;
{*************************************************************************}
{ Send cart to n64 }
{*************************************************************************}
Procedure TForm1.cmd_send();
var
a,ao,l: integer;
b,b2,b3,b4: byte;
errors: integer;
begin
     sizef1:=sizef;
     paramd[3] := paramd[2] + paramd[3];
     if sizef = 0 then  sizef1:= $800000;
     if (sizef > paramd[3]) and (paramd[3] > 0) then  sizef1:= paramd[3];

     ProgressBar.Max:= sizef1;
     errors:=0;
     a:=paramd[2];
     while ((a<sizef1) and (errors < 10)) do
     begin
          wr_a (a);
          ao:=a;
          l:=0;
          while l<512 do
          begin
               epp_write( 4, buffer[a]);
               inc (l);
               inc (a);
          end;

          wr_a(ao);
          l:=0;
          while ((l<512) and (errors <10)) do
          begin
               b:=epp_read(4);
               if b<> buffer[ao] then
               begin
                    prn('Error, addres: ' + inttohex( ao,8 )+ ' PCmem: ' + inttohex(buffer[ao],2) + ' n64mem: ' + inttohex (b,2));
                    inc(errors);
               end;
             inc (l);
             inc (ao);
          end;
          progressbar.Position:= a;
     end
end;
{*************************************************************************}
{ Send Fast w/o checking}
{*************************************************************************}
Procedure TForm1.cmd_sx();
var
a,ao,l: integer;
b,b2,b3,b4: byte;
errors: integer;
begin
     sizef1:=sizef;
     paramd[3] := paramd[2] + paramd[3];
     if sizef = 0 then  sizef1:= $800000;
     if (sizef > paramd[3]) and (paramd[3] > 0) then  sizef1:= paramd[3];

     ProgressBar.Max:= sizef1;
     errors:=0;
     a:=paramd[2];
     while a<sizef1 do
     begin
          wr_a (a);
          l:=0;
          while l<512 do
          begin
               epp_write( 4, buffer[a]);
               inc (l);
               inc(a);
          end;
          progressbar.Position:= a;
     end
end;
{*************************************************************************}
{ Fill fast}
{*************************************************************************}

Procedure TForm1.cmd_fill();
var
a,ao,l: integer;
bl,bh: byte;
errors: integer;
begin
     sizef1:=sizef;
     paramd[3] := paramd[2] + paramd[3];
     if sizef = 0 then  sizef1:= $800000;
     if (sizef > paramd[3]) and (paramd[3] > 0) then  sizef1:= paramd[3];

     ProgressBar.Max:= sizef1;
     errors:=0;
     a:=paramd[2];
     bl:=paramd[4] and $FF;
     bh:=(paramd[4] div 256) and $ff;
     while a<sizef1 do
     begin
          wr_a (a);
          l:=0;
          while l<256 do
          begin
               epp_write( 4, bl);
               epp_write( 4, bh);
               inc (l);
               a:=a+2;
          end;
          progressbar.Position:= a;
     end
end;
{*************************************************************************}
{ Reading N64 I do not chack this routine }
{*************************************************************************}
Procedure TForm1.cmd_read();
var
a,ao,l: integer;
b,b2,b3,b4: byte;
errors: integer;
begin
     paramd[3]:= paramd[2]+paramd[3];
     sizef1:=sizef;
     if sizef = 0 then  sizef1:= $800000 else sizef1:=sizef;
     if (sizef > paramd[3]) and (paramd[3] > 0) then  sizef1:= paramd[3];

     ProgressBar.Max:= sizef1;
     errors:=0;
     a:=paramd[2];
     while ((a<sizef1) and (errors < 10)) do
     begin
          wr_a (a);
          l:=0;
          while ((l<512) and (errors <10)) do
          begin
               buffer[a]:=epp_read(4);
               inc(a);
               inc (l);
          end;
          progressbar.Position:= a;
     end;
end;
{*************************************************************************}
{ Compare dram and pc-ram }
{*************************************************************************}
Procedure TForm1.cmd_cmp();
var
a,ao,l: integer;
b,b2,b3,b4: byte;
errors: integer;
begin
     paramd[3]:= paramd[2]+paramd[3];
     sizef1:=sizef;
     if sizef = 0 then  sizef1:= $800000 else sizef1:=sizef;
     if (sizef > paramd[3]) and (paramd[3] > 0) then  sizef1:= paramd[3];

     ProgressBar.Max:= sizef1;
     errors:=0;
     a:=paramd[2];
     while ((a<sizef1) and (errors < 10)) do
     begin
          wr_a (a);
          l:=0;
          while ((l<512) and (errors <10)) do
          begin
               b:=epp_read(4);
               if b<> buffer[a] then
               begin
                    prn('Error, addres: ' + inttohex( a,8 )+ ' PCmem: ' + inttohex(buffer[a],2) + ' n64mem: ' + inttohex (b,2));
                    inc(errors);
               end;
               inc(a);
               inc (l);
          end;
          progressbar.Position:= a;
     end
end;
{*************************************************************************}
{ Syntax case }
{*************************************************************************}
procedure TForm1.syntax(cmd: string );
begin
     if cmd = '?' then  cmd_help
     else if cmd = 'dr' then dump_ram
     else if cmd = 'd' then dump_n64
     else if cmd = 'res' then cmd_reset
     else if cmd = 'ld' then cmd_load
     else if cmd = 'ar' then cmd_aread
     else if cmd = 'a' then  cmd_addres
     else if cmd = 'pc' then  cmd_mon
     else if cmd = 'n64' then  cmd_moff
     else if cmd = 'stat' then  cmd_stat
     else if cmd = 'send' then  cmd_send
     else if cmd = 'f'    then  cmd_fill
     else if cmd = 'read' then  cmd_read
     else if cmd = 'sx' then  cmd_sx
     else if cmd = 'test' then  cmd_test
     else if cmd = 'cmp' then  cmd_cmp
     else if cmd = 'mode' then  cmd_mode
     else if cmd = 'i' then  cmd_i
     else if cmd = 'o' then  cmd_o
     else if cmd = 'r' then  cmd_run

end;
{*************************************************************************}
{ Printf }
{*************************************************************************}
Procedure TForm1.prn(line: string );
begin
     term.items.add(line);
     if term.items.Count > 128 then term.items.delete (0);
     term.TopIndex:= term.items.Count - 1 ;

end;

{*************************************************************************}
{ Test dramm }
{*************************************************************************}

Procedure TForm1.cmd_test();
var
b: byte;
begin
     prn(' Write increment ');
     b:=$0;
     fill_i(b);
     cmd_send;

     b:=1;
     while b<>0 do
     begin
          prn (' Write running 1, now ALL ' + inttohex(b,2) );
          fill(b);
          b:=b*2;
          cmd_send;
     end;

     prn(' Write ALL 0');
     b:=0;
     fill(b);
     cmd_send;

     prn(' Write ALL $FF ');
     b:=$FF;
     fill(b);
     cmd_send;

     prn(' Write ALL $55');
     b:=$55;
     fill(b);
     cmd_send;

     prn(' Write ALL $AA');
     b:=$AA;
     fill(b);
     cmd_send;

     prn(' Write Random ');
     fill_rnd;
     cmd_send;
end;

procedure TForm1.fill( b:byte);
var
a: integer;
begin
    a:=0;
    while a < $800000 do
    begin
         buffer[a]:= b;
         inc(a);
    end;
end;
procedure TForm1.fill_i( b:byte);
var
a: integer;
begin
     a:=0;
     while a < $800000 do
     begin
           buffer[a]:= b;
           inc(a);
           inc(b);
           if b=0 then inc(b);
     end;
end;

procedure TForm1.fill_rnd( );
var
a: integer;
begin
a:=0;
    while a < $800000 do
    begin
       buffer[a]:= random(256);
       inc(a);
    end;
end;

end.
