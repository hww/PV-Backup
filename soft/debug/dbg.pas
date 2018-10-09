unit dbg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, Gauges, ExtCtrls, Mask;
//******************************************
// type of mode variable
//******************************************
type tmode = (mPC,mDBG, mDRAMM, mROM , mBRK);
//******************************************
type
  Tpanel = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    RunB: TButton;
    DbgB: TButton;
    SendB: TButton;
    CompareB: TButton;
    DrammB: TButton;
    RomB: TButton;
    DbgB2: TButton;
    WaitChk: TCheckBox;
    ConnectB: TButton;
    TestB: TButton;
    dumpB: TButton;
    dump_list: TButton;
    OutWin: TMemo;
    ClearOut: TButton;
    FileName: TEdit;
    StatusDBG: TStatusBar;
    Gauge1: TGauge;
    Splitter1: TSplitter;
    Label4: TLabel;
    DumpWin: TMemo;
    Label5: TLabel;
    OpenDialog1: TOpenDialog;
    Mode_str: TLabel;
    minus: TButton;
    Pluse: TButton;
    BrowseB: TButton;
    Led: TShape;
    PowerLED: TShape;
    PowerC: TLabel;
    OneSec: TTimer;
    dump_addr: TMaskEdit;
    DumpPC: TButton;
    List: TButton;
    Bevel3: TBevel;
    Label6: TLabel;
    Bevel1: TBevel;
    procedure ConnectBClick(Sender: TObject);
    Function Connect :boolean;
    procedure ClearOutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mode(mode: tmode);
    procedure dumpBClick(Sender: TObject);
    procedure dump(address: integer);
    procedure PluseClick(Sender: TObject);
    procedure minusClick(Sender: TObject);
    function word2chars(w: word):string;
    function InP16:word;
    procedure OutP16(D:word);
    function InP(A:word):byte;
    procedure OutP(A:word;D:byte);
    procedure SetA(Rn:byte);
    procedure WrD(D:byte);
    function  RdD: byte;
    procedure SetPtr(ptr : integer);
    procedure dump_listClick(Sender: TObject);
    procedure set_mode(m:byte);
    procedure ninit;
    function Stat:byte;
    function RdPtr:integer;
    procedure BrowseBClick(Sender: TObject);
    procedure PowerChk;
    procedure OneSecTimer(Sender: TObject);
    procedure DbgB2Click(Sender: TObject);
    procedure RomBClick(Sender: TObject);
    procedure DrammBClick(Sender: TObject);
    procedure RunBClick(Sender: TObject);
    procedure DbgBClick(Sender: TObject);
    procedure SendBClick(Sender: TObject);
    procedure CompareBClick(Sender: TObject);
    procedure Load;
    procedure Send;
    procedure cmpf;
    procedure dumprd(a:integer);
    procedure DumpPCClick(Sender: TObject);
    procedure dump_addrChange(Sender: TObject);
    procedure varsave(s:byte);
    procedure ListClick(Sender: TObject);
    procedure TestBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
const exchange = $13FFFE00;
const bpc = 1; // Set PC Mode
const sbpc = $10; // Status PC Mode

const bdramm = $0; // Set PC Mode
const brom = $22; // Set PC Mode
const bdbg = $6; // Set PC Mode
const bbrk = $7; // Set PC Mode
const sbrk = $20; // Set PC Mode
const sdf = $40; // was write to dramm
const base = $378;
const rga = 3 ; rgd = 4; rgc = 2; rg_stat = 1;
var
  HistoryPos:integer;
  FileSize: integer;
  buffer: array[0..4194304] of word; // buffer for file
  panel: Tpanel;
  var_mode: tmode ; // Mode of device
  dump_buffer: array[0..511] of word; // buffer for dumping
implementation

{$R *.DFM}

procedure Tpanel.ConnectBClick(Sender: TObject);
begin
    If Connect= true then
    begin
         LED.Brush.Color:=clGreen;
    end
    else
    begin
         LED.Brush.Color:=clRed;
    end;
end;
// **********************************************
// Find PV Backup device
// If defice found, functions return TRUE
// if not FALSE
//***********************************************
Function Tpanel.Connect():boolean;
begin
          ninit;
          if (Stat and sbpc) > 0 then
          begin
               Connect:=False;
          end
          else
          begin
               Set_mode(bpc);
               if (Stat and sbpc) > 0 then Connect:=True else Connect:=false;
          end;
end;
// Check power on N64
Procedure Tpanel.powerChk();
begin
    If Stat  > $7F then
    begin
         PowerLED.Brush.Color:=clGreen;
    end
    else
    begin
         PowerLED.Brush.Color:=clGray;
    end;
end;
//***********************************************
// Clear output window
//***********************************************
procedure Tpanel.ClearOutClick(Sender: TObject);
begin
     OutWin.Lines.Clear;
     HistoryPos:=0;
end;
//***********************************************
// Load Module
// Init more functions and set default mode
//***********************************************
procedure Tpanel.FormCreate(Sender: TObject);
begin
     OutWin.Lines.Clear;
     mode(mPC);
     FileName.Text:=' No file';
     StatusDBG.Panels[0].Text:='Welcome to light Debuger';
     ConnectB.Click;  // Check device
     PowerChk;      // Check power
end;
//***********************************************
// Set current mode
// PC, DBG, DRAMM, ROM
//***********************************************
procedure Tpanel.mode(mode: tmode);
begin
     var_mode:=mode;
     Case mode of
     mPC:
          begin
               Mode_str.Caption:='PC';
               Mode_str.Color:= clGray;
               set_mode (bpc);
          end;
     mDRAMM:
          begin
               Mode_str.Caption:='DRAMM';
               Mode_str.Color:= clGreen;
               set_mode (bdramm);
          end;
     mROM:
          begin
               Mode_str.Caption:='ROM';
               Mode_str.Color:= clGreen;
               set_mode (brom);
          end;
     mDBG:
          begin
               Mode_str.Caption:='DBG';
               Mode_str.Color:= clBlue;
               set_mode (bdbg);
          end;
     mBRK:
          begin
               Mode_str.Caption:='BRK';
               Mode_str.Color:= clRed;
               set_mode (bbrk);
          end;
     end;

end;
//***********************************************
// Open dialog
//***********************************************
procedure Tpanel.BrowseBClick(Sender: TObject);
begin
     OpenDialog1.Execute;
     FileName.Text:=OpenDialog1.FileName;
end;
//***********************************************
// Dump buffer for dumping
//***********************************************
// Dump fixet address
procedure Tpanel.dump_listClick(Sender: TObject);
begin
     mode(mPC);
     dumprd(exchange);
     dump(exchange);  // base of exchange area
end;
// Dump from address fields
procedure Tpanel.dumpBClick(Sender: TObject);
begin
     mode(mPC);
     dumprd(strtoint('$'+dump_addr.Text ));
     dump(strtoint('$'+dump_addr.Text ));
end;
// Dump PC memory
procedure Tpanel.DumpPCClick(Sender: TObject);
var
pos,a : integer;
begin
     a:= strtoint('$'+dump_addr.Text );
     pos:=0;
     while pos<256 do
     begin
          dump_buffer[pos]:=buffer[a+pos];
          inc(pos);
     end;
     dump(strtoint('$'+dump_addr.Text ));
end;
// Main D U M P
procedure Tpanel.dump(address: integer);
var
pos : integer;
line,linechr: string;
begin
     DumpWin.Lines.Clear;
     pos:=0;
     while pos < 256 do
     begin
          if (pos and 3) = 0 then
          begin
               line:=inttohex(address+(pos shl 1),8)+ ' ' +inttohex(dump_buffer[pos],4);
               linechr:=word2chars(dump_buffer[pos]);
          end
          else
          begin
               line:=line+' '+inttohex(dump_buffer[pos],4);
               linechr:=linechr+ word2chars(dump_buffer[pos]);
          end;

          if (pos and 3) = 3 then
          begin
               line:=line+' '+linechr;
               DumpWin.Lines.Add(line);
          end;
          inc(pos);
     end;
end;
// Converting one word to two chars
function Tpanel.word2chars(w: word):string;
var
   s:string;
begin
   if Hi(w)<$20 then s:='.' else s:=chr(Hi(w));
   if Lo(w)<$20 then s:=s+'.' else s:=s+chr(Lo(w));
   word2chars:=s;
end;

//***********************************************
// Dump address + and -
//***********************************************

procedure Tpanel.PluseClick(Sender: TObject);
begin
     dump_addr.text:=inttohex((strtoint('$'+dump_addr.text ) and $FFFFFE00) +$200,8);
     dumpB.Click;
end;

procedure Tpanel.minusClick(Sender: TObject);
begin
     dump_addr.text:=inttohex((strtoint('$'+dump_addr.text ) and $FFFFFE00) -$200,8);
     dumpB.Click;
end;

procedure Tpanel.dump_addrChange(Sender: TObject);
var
err,i,pos: integer;
line:string;
begin
     val('$'+dump_addr.text,i,err);
     if err>0 then
     begin
     line:=copy(dump_addr.Text,1,err-2)+'0';
     line:=line+copy(dump_addr.Text,err,10);
     dump_addr.Text:=line;
     dump_addr.SelStart:=err-2;
     dump_addr.SelLength:=1;
     end;
end;
//***********************************************
// Access to the ports
//***********************************************
// In from port
function Tpanel.InP(A : Word): byte;
asm
   MOV    DX,A
   IN     AL,DX
end;
// Out to port
procedure Tpanel.OutP(A  : word; D: byte);

asm
   MOV    AL,D
   MOV    DX,A
   OUT    DX,AL
end;
// Procedure set address of register
procedure Tpanel.SetA(Rn : byte);
asm
   MOV    AL,Rn
   MOV    DX,base+rga
   OUT    DX,AL
end;
// Procedure write data to EPP
procedure Tpanel.WrD(D : byte);
asm
   MOV    AL,D
   MOV    DX,base+rgd
   OUT    DX,AL
end;
// Read data from EPP
function Tpanel.RdD(): byte;
asm
   MOV    DX,base + rgd;
   IN     AL,DX
end;

// Procedure set address of dramm
procedure Tpanel.SetPtr(ptr : integer);
begin
     SetA(0);
     WrD(Ptr and 255);
     SetA(1);
     WrD((Ptr shr 8) and 255);
     SetA(2);
     WrD((Ptr shr 16) and 255);
     SetA(3);
     WrD((Ptr shr 24) and 255);
end;

// Procedure read address of dramm
function Tpanel.RdPtr():integer;
var
   a: integer;
begin
     SetA(0);
     a:=RdD;
     SetA(1);
     a:=a+ (RdD shl 8);
     SetA(2);
     a:=a+(RdD shl 16);
     SetA(3);
     a:=a+(RdD shl 24);
     RdPtr:=a and $0FFFFFFF;
end;

// Procedure out data 16
procedure Tpanel.OutP16(D : word);
asm
   MOV    AX,D
   MOV    DX,base+rgd
   XCHG   AL,AH
   OUT    DX,AL
   XCHG   AL,AH
   OUT    DX,AL
end;

// Procedure in data 16
function Tpanel.InP16():word;
asm
   MOV    DX,base+rgd
   IN     AL,DX
   XCHG   AL,AH
   IN     AL,DX
end;

// Reset of controller
procedure Tpanel.ninit();
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
End;
//***********************************************
// Write to mode register
//***********************************************
procedure Tpanel.set_mode(m:byte);
begin
     SetA(5);
     WrD(m);
end;

function Tpanel.Stat():byte;

begin
     SetA(3);
     Stat:=RdD;
end;

//***********************************************
// Read dump buffer from device
//***********************************************
procedure TPanel.dumprd(a:integer);
var
pos: integer;
begin
     SetPtr(a);    // set pointer to a
     SetA(4);
     pos:=0;
     while pos < 256 do
     begin
        dump_buffer[pos]:=InP16;
        inc(pos);
     end;
end;

//***********************************************
// Timer for check 
//***********************************************
procedure Tpanel.OneSecTimer(Sender: TObject);
var
statb: byte;
begin
     PowerChk;
     statb:=stat;
     If (statb and sbrk)>0 then
     begin

          mode(mBRK);
          dumprd(exchange);
          varsave(statb);
          if WaitChk.Checked=false then mode(mDBG);
     end;
end;
//***********************************************
// Set modes
//***********************************************
// debug mode
procedure Tpanel.DbgB2Click(Sender: TObject);
begin
     mode(mDBG);
end;
// rom mode
procedure Tpanel.RomBClick(Sender: TObject);
begin
     mode(mROM);
end;
// dramm mode
procedure Tpanel.DrammBClick(Sender: TObject);
begin
     mode(mDRAMM);
end;
//***********************************************
// Read File and do command
//***********************************************
// DRAM mode
procedure Tpanel.RunBClick(Sender: TObject);
begin
     mode(mPC);
     Load;
     Send;
     mode(mDRAMM);
end;
// debug mode
procedure Tpanel.DbgBClick(Sender: TObject);
begin
     mode(mPC);
     Load;
     Send;
     mode(mDBG);
end;
// send only

procedure Tpanel.SendBClick(Sender: TObject);
begin
     mode(mPC);
     Load;
     Send;
end;
// Compare only

procedure Tpanel.CompareBClick(Sender: TObject);
begin
     mode(mPC);
     Load;
     cmpf;
end;
//***********************************************
// Load File
//***********************************************
Procedure TPanel.Load();
var
dfile: file;
BufferSize : integer;
IsFile: boolean;
a: integer;
w: word;
begin
     AssignFile ( dfile, FileName.Text);
     try
        Reset( dfile, 1);
        IsFile := True;
     except
        IsFile := false;
     end;
     if IsFile then
     begin
           BufferSize:=SizeOf(Buffer);
           BlockRead( dfile, Buffer, BufferSize, FileSize);
           StatusDBG.Panels[0].Text:='File read';
           StatusDBG.Panels[1].Text:='size:' + inttostr(FileSize);
     end
     else
     begin
          StatusDBG.Panels[0].Text:='File not found.';
     end;
     closefile ( dfile);

     if buffer[0] = $80 then
     begin
         a:=0;
         while a<(FileSize shr 1) do
         begin
              buffer[a]:=swap(buffer[a]);
              inc(a);
         end;
     end;
end;
//***********************************************
// Send File
//***********************************************
Procedure TPanel.Send();
var
a,acmp,pos: integer;
err,len:integer;
w:word;
begin
     a:=0;
     len:=FileSize shr 1;
     Gauge1.MaxValue:=len;
     while (a < len) and (err < 8) do
     begin
          SetPtr(a shl 1);    // set pointer to a
          SetA(4);
          pos:=0;
          while pos < 256 do
          begin
               OutP16(buffer[a+pos]);
               inc(pos);
          end;

          SetPtr(a shl 1);    // set pointer to a for control
          SetA(4);
          pos:=0;
          while pos < 256 do
          begin
               w:=InP16;
               if w <> buffer[a+pos] then
               begin
                    OutWin.Lines.Add('Error a:'+inttohex(a+pos,8)+' wr:'+inttohex(buffer[a+pos],4)+ ' rd:'+inttohex(w,4));
                    inc(err);
               end;
               inc(pos);
          end;
          a:=a+$100;
          Gauge1.Progress:=a;
     end;
     if err>0 then StatusDBG.Panels[0].Text:='File did not send.' else StatusDBG.Panels[0].Text:='File send.';
end;
//***********************************************
// Compare File
//***********************************************
procedure TPanel.cmpf();
var
a,acmp,pos: integer;
err,len:integer;
w:word;
begin
     a:=0;
     len:= FileSize shr 1;
     Gauge1.MaxValue:=len;
     while (a < len) and (err < 8) do
     begin
          SetPtr(a shl 1);    // set pointer to a
          SetA(4);
          pos:=0;
          while pos < 256 do
          begin
               w:=InP16;
               if w <> buffer[a+pos] then
               begin
                    OutWin.Lines.Add('Error a:'+inttohex(a+pos,8)+' wr:'+inttohex(buffer[a+pos],4)+ ' rd:'+inttohex(w,4));
                    inc(err);
               end;
               inc(pos);
          end;
          a:=a+$100;
          Gauge1.Progress:=a;
     end;
     if err>0 then StatusDBG.Panels[0].Text:='File is different.' else StatusDBG.Panels[0].Text:='File uqual.';
end;
//***********************************************
// Print exchange buffer
//***********************************************
procedure TPanel.varsave(s:byte);
var
pos, varnum:integer;
bl,bh,ending: byte;
line:string;
begin
     ending:=0;
     inc(HistoryPos);
     If ( s and sdf)>0 then
     begin
        OutWin.Lines.Add('[ '+ Inttostr(HistoryPos)+' ] n64 write to dramm ------------------');
     end
     else
     begin
        OutWin.Lines.Add('[ '+ Inttostr(HistoryPos)+' ] -------------------------------------');
     end;
     pos:=0;
     while (pos < 256) or (ending=0) do
     begin
          bh:=Hi(dump_buffer[pos]);
          bl:=Lo(dump_buffer[pos]);
          case bh of
          $0D:
               begin
                    OutWin.Lines.Add(line);
                    line:='';
               end;
          $20..$FF: line:=line+chr(bh);
          0:inc(ending);
          end;
          case bl of
          $0D:
              begin
                   OutWin.Lines.Add(line);
                   line:='';
              end;
          $20..$FF: line:=line+chr(bl);
          0: inc(ending);
          end;
          inc(pos);
     end;
end;
//***********************************************
// Print exchange buffer
//***********************************************
procedure Tpanel.ListClick(Sender: TObject);
begin
     mode(mPC);
     dumprd(exchange);
     varsave(0);
end;
//***********************************************
// Fill Memory
//***********************************************

procedure Tpanel.TestBClick(Sender: TObject);
var
a,b: integer;
begin
     mode(mPC);
     FileSize:=SizeOf(buffer) shr 1;
     a:=0;b:=0;
     while a<FileSize do
     begin
          buffer[a]:=b and $FFFF;
          buffer[a+1]:=(b shr 16)and $FFFF;
          a:=a+2;
          Inc(b);
     end;
     Send;
     cmpf;
end;

end.
